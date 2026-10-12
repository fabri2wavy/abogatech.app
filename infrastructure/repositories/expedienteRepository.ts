import { browserContext } from "../backend/browser";
import { check, fullName, message } from "../backend/context";
import { list, one, update, remove, profiles } from "../backend/data";
import {
  mapCase,
  mapClient,
  caseFields,
  mappedFields,
} from "../backend/mappers";
import type { Expediente } from "@/domain/entities/Expediente";

async function hydrated(archived?: boolean) {
  const { db, ctx } = await browserContext();
  const [cases, clients, members, assignments] = await Promise.all([
    list(db, ctx, "cases"),
    list(db, ctx, "clients"),
    list(db, ctx, "firm_memberships"),
    list(db, ctx, "case_members"),
  ]);
  const p = await profiles(
    db,
    members.map((m) => m.user_id),
  );
  return cases
    .filter((c) => archived === undefined || c.archivado === archived)
    .map((c) => {
      const client = clients.find((cl) => cl.id === c.client_id);
      const assigned = assignments.find(
        (a) => a.case_id === c.id && a.activo && a.role === "responsable",
      );
      const member = members.find((m) => m.id === assigned?.membership_id);
      const name = client
        ? mapClient(client).nombreCompleto
        : "Cliente no disponible";
      return {
        ...mapCase(c),
        nombreCliente: name,
        cliente: {
          id: c.client_id,
          nombre_completo: name,
          nombres: client?.nombres ?? "",
          apellido_paterno: client?.apellido_paterno ?? "",
          apellido_materno: client?.apellido_materno ?? "",
          telefono: client?.telefono ?? "",
          email: client?.email ?? "",
        },
        abogado_id: member?.user_id,
        abogado_nombre: member
          ? fullName(p.get(member.user_id))
          : "Sin asignar",
      };
    })
    .sort((a, b) => b.fechaCreacion.getTime() - a.fechaCreacion.getTime());
}
export async function obtenerExpedientes() {
  return hydrated(false);
}
export async function obtenerExpedientesArchivados() {
  return hydrated(true);
}
export async function obtenerExpedientePorId(id: string) {
  return (await hydrated()).find((c) => c.id === id) ?? null;
}
export async function crearExpediente(
  datos: Omit<
    Expediente,
    "id" | "fechaCreacion" | "fechaActualizacion" | "estado"
  >,
): Promise<Expediente | null> {
  const { db, ctx } = await browserContext();
  if (
    datos.historialJuzgados ||
    datos.oficiosSolicitados ||
    datos.medidasPreviasRemate
  )
    throw new Error(
      "La base suministrada no tiene los campos de historial de juzgados, oficios ni medidas previas al remate.",
    );
  const r = await db.rpc("app_save_case", {
    p_firm_id: ctx.firmId,
    p_id: null,
    p_fields: mappedFields(datos, caseFields),
    p_assignee:
      datos.abogado_id || (ctx.role === "abogado" ? ctx.userId : null),
    p_set_assignee: true,
  });
  check(r.error);
  return mapCase(r.data);
}
export async function actualizarExpediente(
  id: string,
  datos: Partial<Omit<Expediente, "estado">> & { estado?: string },
): Promise<boolean> {
  const { db, ctx } = await browserContext();
  if (
    datos.historialJuzgados ||
    datos.oficiosSolicitados ||
    datos.medidasPreviasRemate
  )
    throw new Error(
      "Estos campos adicionales no existen en el esquema suministrado.",
    );
  const r = await db.rpc("app_save_case", {
    p_firm_id: ctx.firmId,
    p_id: id,
    p_fields: mappedFields(datos, caseFields),
    p_assignee: datos.abogado_id || null,
    p_set_assignee: datos.abogado_id !== undefined,
  });
  check(r.error);
  return true;
}
export async function obtenerTotalExpedientes(): Promise<number> {
  return (await obtenerExpedientes()).length;
}
export async function archivarExpediente(id: string): Promise<boolean> {
  const { db, ctx } = await browserContext();
  await update(db, ctx, "cases", id, {
    archivado: true,
    archivado_at: new Date().toISOString(),
    archivado_por: ctx.userId,
  });
  return true;
}
export async function restaurarExpediente(id: string): Promise<boolean> {
  const { db, ctx } = await browserContext();
  await update(db, ctx, "cases", id, {
    archivado: false,
    archivado_at: null,
    archivado_por: null,
  });
  return true;
}
export async function eliminarExpedienteDefinitivo(
  id: string,
): Promise<{ success: boolean; error?: string }> {
  try {
    const { db, ctx } = await browserContext();
    const c = await one(db, ctx, "cases", id);
    if (!c.archivado)
      throw new Error("Archiva el expediente antes de eliminarlo.");
    const docs = await db
      .from("documents")
      .select("id")
      .eq("firm_id", ctx.firmId)
      .eq("case_id", id)
      .limit(1);
    check(docs.error);
    if (docs.data?.length)
      throw new Error(
        "Elimina primero los documentos del expediente para conservar la coherencia con Storage.",
      );
    await remove(db, ctx, "cases", id);
    return { success: true };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
