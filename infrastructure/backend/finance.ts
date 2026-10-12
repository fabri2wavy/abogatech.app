import type { Rows } from "@/domain/types/database";
import type {
  Honorario,
  CuotaPago,
  GastoExpediente,
  MonedaHonorario,
} from "@/domain/entities/Finanzas";
export function currency(code: string): MonedaHonorario {
  if (code === "BOB") return "BS";
  if (code === "USD") return "USD";
  throw new Error(
    "La pantalla actual solo admite BOB y USD. Moneda encontrada: " + code,
  );
}
export function assertSingleCurrency(codes: string[]) {
  if (new Set(codes).size > 1)
    throw new Error(
      "El reporte contiene varias monedas. No se suman BOB y USD sin una tasa de conversión definida.",
    );
}
export function paidByInstallment(
  payments: Rows["payments"][],
  allocations: Rows["payment_allocations"][],
) {
  const active = new Set(
    payments.filter((p) => p.estado === "registrado").map((p) => p.id),
  );
  const totals = new Map<string, number>();
  for (const a of allocations)
    if (active.has(a.payment_id))
      totals.set(
        a.installment_id,
        (totals.get(a.installment_id) ?? 0) + Number(a.monto),
      );
  return totals;
}
export function todayBO(now = new Date()) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/La_Paz",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
}
export function mapAgreement(r: Rows["fee_agreements"]): Honorario {
  return {
    id: r.id,
    expedienteId: r.case_id,
    montoTotal: Number(r.monto_total),
    moneda: currency(r.moneda),
    estadoContrato: r.estado as Honorario["estadoContrato"],
    creadoEn: r.created_at,
    autorizadoAdministracion: !!r.autorizado_por,
  };
}
export function mapInstallment(
  r: Rows["fee_installments"],
  paid: number,
): CuotaPago {
  return {
    id: r.id,
    honorarioId: r.agreement_id,
    descripcion: r.descripcion,
    monto: Number(r.monto),
    montoPagado: paid,
    saldoPendiente: Math.max(0, Number(r.monto) - paid),
    tipoVencimiento: r.tipo_vencimiento as "fecha" | "hito",
    hitoVencimiento: r.hito_vencimiento,
    fechaVencimiento: r.fecha_vencimiento,
    estado:
      r.estado === "cancelado"
        ? "cancelado"
        : paid >= Number(r.monto)
          ? "pagado"
          : r.fecha_vencimiento && r.fecha_vencimiento < todayBO()
            ? "atrasado"
            : "pendiente",
    fechaPago: r.pagado_at,
    creadoEn: r.created_at,
  };
}
export function mapExpense(r: Rows["case_expenses"]): GastoExpediente {
  return {
    id: r.id,
    expedienteId: r.case_id,
    concepto: r.concepto,
    monto: Number(r.monto),
    fecha: r.fecha,
    reembolsado: r.estado === "reembolsado",
    comprobanteUrl: r.comprobante_path,
    creadoEn: r.created_at,
    observaciones: r.observaciones,
  };
}
