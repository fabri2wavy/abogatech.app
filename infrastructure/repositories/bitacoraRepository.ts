import { browserContext } from "../backend/browser";
import { list, insert, profiles } from "../backend/data";
import { fullName } from "../backend/context";
import type { Rows } from "@/domain/types/database";
import type { EntradaBitacora } from "@/domain/entities/EntradaBitacora";
function map(r: Rows["case_notes"], name: string): EntradaBitacora {
  return {
    id: r.id,
    expedienteId: r.case_id,
    contenido: r.contenido,
    visibleCliente: r.visible_cliente,
    creadoPor: r.creado_por ?? "",
    autorNombre: name,
    creadoEn: new Date(r.created_at),
  };
}
export async function obtenerBitacoraPorExpediente(
  id: string,
): Promise<EntradaBitacora[]> {
  const { db, ctx } = await browserContext();
  const rows = (await list(db, ctx, "case_notes")).filter(
    (r) => r.case_id === id,
  );
  const p = await profiles(
    db,
    rows.map((r) => r.creado_por ?? ""),
  );
  return rows
    .map((r) => map(r, fullName(p.get(r.creado_por ?? ""))))
    .sort((a, b) => b.creadoEn.getTime() - a.creadoEn.getTime());
}
export async function crearEntradaBitacora(
  expedienteId: string,
  contenido: string,
  visibleCliente: boolean,
  _usuarioId: string,
): Promise<EntradaBitacora | null> {
  void _usuarioId; // El autor se obtiene de la sesión.
  const { db, ctx } = await browserContext();
  const r = await insert(db, ctx, "case_notes", {
    case_id: expedienteId,
    contenido,
    visible_cliente: visibleCliente,
    creado_por: ctx.userId,
  });
  return map(r, "Tú");
}
