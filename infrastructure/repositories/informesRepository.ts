import { browserContext } from "../backend/browser";
import { list, insert } from "../backend/data";
import type { Rows } from "@/domain/types/database";
import type { InformeAvance } from "@/domain/entities/InformeAvance";
function map(r: Rows["case_reports"]): InformeAvance {
  return {
    id: r.id,
    expedienteId: r.case_id,
    mesAnio: r.periodo.slice(0, 7),
    resumenProceso: r.resumen_proceso ?? "",
    estadoActual: r.estado_actual ?? "",
    medidasPrecautorias: r.medidas_precautorias ?? "",
    comentario: r.comentario ?? "",
    creadoPor: r.creado_por ?? "",
    createdAt: r.created_at,
  };
}
export async function crearInforme(
  d: Omit<InformeAvance, "id" | "createdAt">,
): Promise<InformeAvance | null> {
  const { db, ctx } = await browserContext();
  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(d.mesAnio))
    throw new Error("El periodo debe tener formato AAAA-MM.");
  return map(
    await insert(db, ctx, "case_reports", {
      case_id: d.expedienteId,
      periodo: d.mesAnio + "-01",
      resumen_proceso: d.resumenProceso,
      estado_actual: d.estadoActual,
      medidas_precautorias: d.medidasPrecautorias,
      comentario: d.comentario,
      creado_por: ctx.userId,
    }),
  );
}
export async function obtenerInformesPorExpediente(
  id: string,
): Promise<InformeAvance[]> {
  const { db, ctx } = await browserContext();
  return (await list(db, ctx, "case_reports"))
    .filter((r) => r.case_id === id)
    .sort((a, b) => b.periodo.localeCompare(a.periodo))
    .map(map);
}
