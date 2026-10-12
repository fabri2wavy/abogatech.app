"use server";
import { serverContext } from "../backend/server";
import { list, profiles } from "../backend/data";
import { message, requireRole, fullName } from "../backend/context";
import { assertSingleCurrency } from "../backend/finance";
import { obtenerReporteFinancieroGlobal } from "./finanzasRepository";
import type {
  KpisFinancieros,
  CargaAbogado,
  DistribucionMateria,
} from "@/domain/entities/Reportes";
import type { RepositoryResponse } from "@/domain/types/RepositoryResponse";
export async function obtenerKpisFinancieros(): Promise<
  RepositoryResponse<KpisFinancieros>
> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin", "finanzas"]);
    const r = await obtenerReporteFinancieroGlobal();
    if (!r.data) return { data: null, error: r.error };
    const payments = (await list(db, ctx, "payments")).filter(
      (p) => p.estado === "registrado",
    );
    assertSingleCurrency([
      ...payments.map((p) => p.moneda),
      ...r.data.filas.map((f) => (f.moneda === "BS" ? "BOB" : "USD")),
    ]);
    return {
      data: {
        totalFacturado: r.data.totalFacturado,
        totalCobrado: payments.reduce((sum, p) => sum + Number(p.monto), 0),
        totalEnMora: r.data.totalMora,
      },
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function obtenerCargaLaboralPorAbogado(): Promise<
  RepositoryResponse<CargaAbogado[]>
> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin", "asociado_senior"]);
    const [cases, members, assignments] = await Promise.all([
      list(db, ctx, "cases"),
      list(db, ctx, "firm_memberships"),
      list(db, ctx, "case_members"),
    ]);
    const p = await profiles(
      db,
      members.map((m) => m.user_id),
    );
    const active = new Set(
      cases
        .filter((c) => !c.archivado && c.estado !== "cerrado")
        .map((c) => c.id),
    );
    return {
      data: members
        .filter((m) => m.role !== "cliente" && m.status === "activo")
        .map((m) => ({
          abogado: fullName(p.get(m.user_id)),
          casosActivos: new Set(
            assignments
              .filter(
                (a) =>
                  a.membership_id === m.id && a.activo && active.has(a.case_id),
              )
              .map((a) => a.case_id),
          ).size,
        })),
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function obtenerDistribucionCasos(): Promise<
  RepositoryResponse<DistribucionMateria[]>
> {
  try {
    const { db, ctx } = await serverContext();
    const totals = new Map<string, number>();
    for (const c of await list(db, ctx, "cases"))
      if (!c.archivado)
        totals.set(
          c.materia ?? "Sin materia",
          (totals.get(c.materia ?? "Sin materia") ?? 0) + 1,
        );
    return {
      data: [...totals].map(([materia, cantidad]) => ({ materia, cantidad })),
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
