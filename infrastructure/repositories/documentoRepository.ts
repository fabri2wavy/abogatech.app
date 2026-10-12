import { browserContext } from "../backend/browser";
import { check, fullName, requireRole } from "../backend/context";
import { list, one, insert, update, remove, profiles } from "../backend/data";
import type { Rows } from "@/domain/types/database";
import type { Documento } from "@/domain/entities/Documento";
const BUCKET = "documentos";
function map(r: Rows["documents"], author = "Tú"): Documento {
  return {
    id: r.id,
    nombre: r.nombre_archivo,
    ruta: r.storage_path,
    tamaño: r.tamano_bytes ?? 0,
    visibleCliente: r.visible_cliente,
    subidoPor: author,
    fechaSubida: new Date(r.created_at),
  };
}
export async function obtenerDocumentos(id: string): Promise<Documento[]> {
  const { db, ctx } = await browserContext();
  const rows = (await list(db, ctx, "documents")).filter(
    (r) => r.case_id === id && r.status === "activo",
  );
  const p = await profiles(
    db,
    rows.map((r) => r.subido_por ?? ""),
  );
  return rows.map((r) => map(r, fullName(p.get(r.subido_por ?? ""))));
}
export async function subirDocumento(
  expedienteId: string,
  file: File,
  visibleCliente: boolean,
): Promise<Documento | null> {
  const { db, ctx } = await browserContext();
  await one(db, ctx, "cases", expedienteId);
  const id = crypto.randomUUID();
  const name =
    file.name
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-zA-Z0-9.-]/g, "_") || "archivo";
  const path = `${ctx.firmId}/${expedienteId}/${id}/${name}`;
  // Storage exige que exista primero la fila de metadatos.
  const row = await insert(db, ctx, "documents", {
    id,
    case_id: expedienteId,
    nombre_archivo: file.name,
    storage_path: path,
    mime_type: file.type || "application/octet-stream",
    extension: name.includes(".") ? name.split(".").pop() : null,
    tamano_bytes: file.size,
    visible_cliente: visibleCliente,
    subido_por: ctx.userId,
  });
  const r = await db.storage.from(BUCKET).upload(path, file, { upsert: false });
  if (r.error) {
    // Solo admin puede borrar; los demás archivan la fila fallida con su permiso de UPDATE.
    try {
      if (ctx.role === "admin") await remove(db, ctx, "documents", id);
      else
        await update(db, ctx, "documents", id, {
          status: "archivado",
          archivado_at: new Date().toISOString(),
          archivado_por: ctx.userId,
        });
    } catch {
      throw new Error(
        "Falló la carga y la limpieza de metadatos. Contacta al administrador. Documento: " +
          id,
      );
    }
    throw new Error(r.error.message);
  }
  return map(row);
}
export async function obtenerUrlDescarga(ruta: string): Promise<string | null> {
  const { db, ctx } = await browserContext();
  if (!ruta.startsWith(ctx.firmId + "/"))
    throw new Error("Documento ajeno a la firma activa.");
  const r = await db.storage
    .from(BUCKET)
    .createSignedUrl(ruta, 300, { download: true });
  check(r.error);
  return r.data?.signedUrl ?? null;
}
export async function eliminarDocumento(
  id: string,
  _ruta: string,
): Promise<boolean> {
  void _ruta; // La ruta autorizada se obtiene del registro.
  const { db, ctx } = await browserContext();
  requireRole(ctx, ["admin"]);
  const row = await one(db, ctx, "documents", id);
  const r = await db.storage.from(BUCKET).remove([row.storage_path]);
  check(r.error);
  await remove(db, ctx, "documents", id);
  return true;
}
export async function actualizarVisibilidad(
  id: string,
  visibleCliente: boolean,
): Promise<boolean> {
  const { db, ctx } = await browserContext();
  await update(db, ctx, "documents", id, { visible_cliente: visibleCliente });
  return true;
}
