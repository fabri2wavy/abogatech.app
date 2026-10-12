"use server";
import { serverContext } from "../backend/server";
import { list, one, insert, profiles } from "../backend/data";
import { message, requireRole, check, fullName } from "../backend/context";
import {
  mapAgreement,
  mapInstallment,
  mapExpense,
  paidByInstallment,
  currency,
  assertSingleCurrency,
  todayBO,
} from "../backend/finance";
import { mapClient } from "../backend/mappers";
import type { RepositoryResponse } from "@/domain/types/RepositoryResponse";
import type { Rows } from "@/domain/types/database";
import type {
  Honorario,
  CuotaPago,
  EstadoCuentaExpediente,
  CreateHonorarioDTO,
  CreateCuotaDTO,
  CreateGastoDTO,
  GastoExpediente,
  ReporteFinancieroGlobal,
  AlertaCuotaVencida,
  FilaReporteFinanciero,
} from "@/domain/entities/Finanzas";
async function dataset() {
  const { db, ctx } = await serverContext();
  requireRole(ctx, ["admin", "finanzas"]);
  const [agreements, installments, payments, allocations] = await Promise.all([
    list(db, ctx, "fee_agreements"),
    list(db, ctx, "fee_installments"),
    list(db, ctx, "payments"),
    list(db, ctx, "payment_allocations"),
  ]);
  return {
    db,
    ctx,
    agreements,
    installments,
    payments,
    paid: paidByInstallment(payments, allocations),
  };
}
export async function obtenerEstadoCuenta(
  expedienteId: string,
): Promise<RepositoryResponse<EstadoCuentaExpediente>> {
  try {
    const d = await dataset();
    await one(d.db, d.ctx, "cases", expedienteId);
    const agreements = d.agreements.filter(
      (a) => a.case_id === expedienteId && a.estado !== "cancelado",
    );
    if (agreements.length > 1)
      throw new Error(
        "Este expediente tiene varios contratos. La pantalla actual muestra uno; selecciona un contrato antes de consolidar sus cuotas.",
      );
    const a = agreements[0];
    const expenses = (await list(d.db, d.ctx, "case_expenses")).filter(
      (g) => g.case_id === expedienteId && g.estado !== "anulado",
    );
    assertSingleCurrency([
      ...expenses.map((g) => g.moneda),
      ...(a ? [a.moneda] : []),
    ]);
    const honorario = a ? mapAgreement(a) : null;
    if (a?.compensation_scheme_id && honorario) {
      const [rules, members] = await Promise.all([
        list(d.db, d.ctx, "compensation_rules"),
        list(d.db, d.ctx, "firm_memberships"),
      ]);
      const applicable = rules.filter(
        (r) => r.scheme_id === a.compensation_scheme_id && r.activo,
      );
      honorario.porcentajeFondo = applicable
        .filter(
          (r) =>
            r.recipient_type === "firma" && r.calculation_type === "porcentaje",
        )
        .reduce((sum, r) => sum + Number(r.valor), 0);
      const net = 71.5 - (honorario.porcentajeFondo ?? 0);
      const distribution = new Map<string, number>();
      for (const rule of applicable.filter(
        (r) =>
          r.recipient_type === "miembro" && r.calculation_type === "porcentaje",
      )) {
        const userId = members.find(
          (m) => m.id === rule.membership_id,
        )?.user_id;
        if (userId && net > 0)
          distribution.set(
            userId,
            (distribution.get(userId) ?? 0) + (Number(rule.valor) * 100) / net,
          );
      }
      honorario.distribucionAbogados = [...distribution].map(
        ([abogadoId, porcentaje]) => ({
          abogadoId,
          porcentaje: String(porcentaje),
        }),
      );
    }
    return {
      data: {
        honorario,
        cuotas: d.installments
          .filter((i) => i.agreement_id === a?.id)
          .sort((a, b) => a.numero - b.numero)
          .map((i) => mapInstallment(i, d.paid.get(i.id) ?? 0)),
        gastos: expenses.map(mapExpense),
      },
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function crearHonorarioConCuotas(
  data: CreateHonorarioDTO,
  cuotas: CreateCuotaDTO[],
): Promise<RepositoryResponse<{ honorario: Honorario; cuotas: CuotaPago[] }>> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin", "finanzas"]);
    const r = await db.rpc("app_create_agreement", {
      p_firm_id: ctx.firmId,
      p_data: data,
      p_installments: cuotas,
    });
    check(r.error);
    const result = r.data as {
      agreement: Rows["fee_agreements"];
      installments: Rows["fee_installments"][];
      paid: Record<string, number>;
    };
    return {
      data: {
        honorario: mapAgreement(result.agreement),
        cuotas: result.installments.map((i) =>
          mapInstallment(i, result.paid?.[i.id] ?? 0),
        ),
      },
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function registrarGasto(
  g: CreateGastoDTO,
): Promise<RepositoryResponse<GastoExpediente>> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin", "finanzas"]);
    await one(db, ctx, "cases", g.expedienteId);
    const agreements = (await list(db, ctx, "fee_agreements")).filter(
      (a) => a.case_id === g.expedienteId && a.estado !== "cancelado",
    );
    assertSingleCurrency(agreements.map((a) => a.moneda));
    if (!agreements.length)
      throw new Error(
        "Registra el contrato para determinar la moneda del gasto.",
      );
    return {
      data: mapExpense(
        await insert(db, ctx, "case_expenses", {
          case_id: g.expedienteId,
          concepto: g.concepto,
          monto: g.monto,
          moneda: agreements[0].moneda,
          fecha: g.fecha,
          estado: g.reembolsado ? "reembolsado" : "registrado",
          reembolsado_at: g.reembolsado ? new Date().toISOString() : null,
          comprobante_path: g.comprobanteUrl,
          observaciones: g.observaciones,
          creado_por: ctx.userId,
        }),
      ),
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function obtenerReporteFinancieroGlobal(): Promise<
  RepositoryResponse<ReporteFinancieroGlobal>
> {
  try {
    const d = await dataset();
    const agreements = d.agreements.filter(
      (a) => a.estado === "vigente" || a.estado === "finalizado",
    );
    assertSingleCurrency(agreements.map((a) => a.moneda));
    const [cases, clients, members, assignments] = await Promise.all([
      list(d.db, d.ctx, "cases"),
      list(d.db, d.ctx, "clients"),
      list(d.db, d.ctx, "firm_memberships"),
      list(d.db, d.ctx, "case_members"),
    ]);
    const p = await profiles(
      d.db,
      members.map((m) => m.user_id),
    );
    let mora = 0;
    const filas: FilaReporteFinanciero[] = agreements.map((a) => {
      const c = cases.find((c) => c.id === a.case_id);
      const client = clients.find((cl) => cl.id === c?.client_id);
      const assigned = assignments.find(
        (m) => m.case_id === a.case_id && m.role === "responsable" && m.activo,
      );
      const member = members.find((m) => m.id === assigned?.membership_id);
      const cuotas = d.installments
        .filter((i) => i.agreement_id === a.id && i.estado !== "cancelado")
        .map((i) => mapInstallment(i, d.paid.get(i.id) ?? 0));
      const paid = cuotas.reduce((s, i) => s + (i.montoPagado ?? 0), 0);
      const overdue = cuotas.filter((i) => i.estado === "atrasado");
      mora += overdue.reduce((s, i) => s + (i.saldoPendiente ?? 0), 0);
      return {
        expedienteId: a.case_id,
        numeroCaso: c?.numero_caso ?? "",
        tituloExpediente: c?.titulo ?? "",
        nombreCliente: client ? mapClient(client).nombreCompleto : "",
        abogadoNombre: member ? fullName(p.get(member.user_id)) : "Sin asignar",
        montoTotal: Number(a.monto_total),
        moneda: currency(a.moneda),
        totalPagado: paid,
        totalPendiente: Math.max(0, Number(a.monto_total) - paid),
        cuotasAtrasadas: overdue.length,
        estadoPago: overdue.length
          ? "moroso"
          : paid >= Number(a.monto_total)
            ? "al_dia"
            : "en_proceso",
      };
    });
    return {
      data: {
        filas,
        totalFacturado: filas.reduce((s, r) => s + r.montoTotal, 0),
        totalPendiente: filas.reduce((s, r) => s + r.totalPendiente, 0),
        totalMora: mora,
      },
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function obtenerAlertasCuotasVencidas(): Promise<
  RepositoryResponse<AlertaCuotaVencida[]>
> {
  try {
    const d = await dataset();
    const [cases, clients] = await Promise.all([
      list(d.db, d.ctx, "cases"),
      list(d.db, d.ctx, "clients"),
    ]);
    const result: AlertaCuotaVencida[] = [];
    for (const raw of d.installments) {
      const a = d.agreements.find(
        (a) => a.id === raw.agreement_id && a.estado === "vigente",
      );
      if (!a || raw.estado === "cancelado") continue;
      const i = mapInstallment(raw, d.paid.get(raw.id) ?? 0);
      if (i.estado === "pagado") continue;
      const days = i.fechaVencimiento
        ? Math.round(
            (Date.parse(i.fechaVencimiento) - Date.parse(todayBO())) / 86400000,
          )
        : 0;
      if (i.tipoVencimiento !== "hito" && days > 7) continue;
      const c = cases.find((c) => c.id === a.case_id);
      const cl = clients.find((cl) => cl.id === c?.client_id);
      result.push({
        cuotaId: i.id,
        descripcion: i.descripcion,
        monto: i.saldoPendiente ?? i.monto,
        moneda: currency(a.moneda),
        fechaVencimiento: i.fechaVencimiento ?? "",
        estado: i.estado,
        diasRestantes: days,
        urgencia:
          i.tipoVencimiento === "hito"
            ? "hito_pendiente"
            : days < 0
              ? "vencida"
              : days === 0
                ? "vence_hoy"
                : "proxima",
        expedienteId: a.case_id,
        numeroCaso: c?.numero_caso ?? "",
        tituloExpediente: c?.titulo ?? "",
        nombreCliente: cl ? mapClient(cl).nombreCompleto : "",
        abogadoNombre: "",
      });
    }
    return { data: result, error: null };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
