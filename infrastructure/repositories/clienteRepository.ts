import { browserContext } from "../backend/browser";
import { check, message } from "../backend/context";
import { list, one, insert, update, remove } from "../backend/data";
import {
  mapClient,
  mapCase,
  mappedFields,
  clientFields,
} from "../backend/mappers";
import type { Cliente } from "@/domain/entities/Cliente";
import type { Expediente } from "@/domain/entities/Expediente";
export interface DatosNuevoCliente {
  /* Auth */
  email: string;

  nombres: string;
  apellidoPaterno: string;
  apellidoMaterno?: string;
  telefono: string;

  ci?: string;
  expedido?: string;
  nacionalidad?: string;
  fechaNacimiento?: string;
  estadoCivil?: string;
  profesion?: string;
  direccion?: string;

  /** Nombre o descripción de quien refirió al cliente. */
  referidoPor?: string;
  /** Teléfono, email u otro dato de contacto del referidor. */
  contactoReferidor?: string;

  etapaComercial?: "potencial" | "activo";
  tipoCliente?: "persona" | "empresa";
  nombreEmpresa?: string | null;
  representanteLegal?: string | null;
  areaEspecialidad?: string | null;

  telefonoLaboral?: string;
  direccionOficina?: string;
}

export async function crearCliente(
  datos: DatosNuevoCliente,
): Promise<{ success: boolean; data?: Cliente; error?: string }> {
  try {
    const { db, ctx } = await browserContext();
    if (datos.areaEspecialidad)
      throw new Error(
        "El esquema actual no incluye el campo área de especialidad del cliente.",
      );
    const row = await insert(db, ctx, "clients", {
      ...mappedFields(datos, clientFields),
      creado_por: ctx.userId,
    });
    return { success: true, data: mapClient(row) };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
export async function obtenerClientes(): Promise<Cliente[]> {
  const { db, ctx } = await browserContext();
  return (await list(db, ctx, "clients")).map(mapClient);
}
export async function obtenerClientePorId(id: string): Promise<Cliente | null> {
  const { db, ctx } = await browserContext();
  return mapClient(await one(db, ctx, "clients", id));
}
export async function obtenerExpedientesPorCliente(
  clienteId: string,
): Promise<Expediente[]> {
  const { db, ctx } = await browserContext();
  return (await list(db, ctx, "cases"))
    .filter((r) => r.client_id === clienteId)
    .map(mapCase);
}
export async function actualizarCliente(
  id: string,
  datos: Partial<Cliente>,
): Promise<boolean> {
  const { db, ctx } = await browserContext();
  if (datos.areaEspecialidad || datos.nit || datos.abogadoContacto)
    throw new Error(
      "La base actual no tiene campos para área de especialidad, NIT o abogado de contacto.",
    );
  await update(db, ctx, "clients", id, mappedFields(datos, clientFields));
  return true;
}
export async function eliminarCliente(
  id: string,
): Promise<{ success: boolean; error?: string }> {
  try {
    const { db, ctx } = await browserContext();
    const r = await db
      .from("cases")
      .select("id")
      .eq("firm_id", ctx.firmId)
      .eq("client_id", id)
      .limit(1);
    check(r.error);
    if (r.data?.length) return { success: false, error: "HAS_CASES" };
    await remove(db, ctx, "clients", id);
    return { success: true };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
export async function obtenerTotalClientes(): Promise<number> {
  const { db, ctx } = await browserContext();
  const r = await db
    .from("clients")
    .select("id", { count: "exact", head: true })
    .eq("firm_id", ctx.firmId);
  check(r.error);
  return r.count ?? 0;
}
