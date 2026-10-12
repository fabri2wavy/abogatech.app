"use server";
import { serverContext } from "../backend/server";
import { list, one, insert, update, remove } from "../backend/data";
import { message, requireRole } from "../backend/context";
import { mapClient } from "../backend/mappers";
import type { Plantilla, TipoPlantilla } from "@/domain/entities/Plantilla";
import type { RepositoryResponse } from "@/domain/types/RepositoryResponse";
import { procesarPlantilla } from "@/domain/services/documentGenerator";
export interface CreatePlantillaDTO {
  nombre: string;
  tipo: TipoPlantilla;
  descripcion?: string;
  contenido: string;
}
export interface UpdatePlantillaDTO {
  nombre?: string;
  tipo?: TipoPlantilla;
  descripcion?: string;
  contenido?: string;
}
export async function obtenerPlantillas(): Promise<
  RepositoryResponse<Plantilla[]>
> {
  try {
    const { db, ctx } = await serverContext();
    return {
      data: (await list(db, ctx, "document_templates")) as Plantilla[],
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function crearPlantilla(
  p: CreatePlantillaDTO,
): Promise<RepositoryResponse<Plantilla>> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin", "asociado_senior", "abogado"]);
    return {
      data: (await insert(db, ctx, "document_templates", {
        nombre: p.nombre,
        tipo: p.tipo,
        descripcion: p.descripcion,
        contenido: p.contenido,
        creado_por: ctx.userId,
      })) as Plantilla,
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function actualizarPlantilla(
  id: string,
  p: UpdatePlantillaDTO,
): Promise<RepositoryResponse<Plantilla>> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin", "asociado_senior", "abogado"]);
    return {
      data: (await update(db, ctx, "document_templates", id, {
        nombre: p.nombre,
        tipo: p.tipo,
        descripcion: p.descripcion,
        contenido: p.contenido,
      })) as Plantilla,
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function eliminarPlantilla(
  id: string,
): Promise<RepositoryResponse<boolean>> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin", "asociado_senior", "abogado"]);
    await remove(db, ctx, "document_templates", id);
    return { data: true, error: null };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function generarDocumento(
  plantillaId: string,
  expedienteId: string,
): Promise<RepositoryResponse<string>> {
  try {
    const { db, ctx } = await serverContext();
    const p = await one(db, ctx, "document_templates", plantillaId);
    const c = await one(db, ctx, "cases", expedienteId);
    const cl = await one(db, ctx, "clients", c.client_id);
    return {
      data: procesarPlantilla(p.contenido, {
        nombreCliente: mapClient(cl).nombreCompleto,
        ciCliente: [cl.ci, cl.expedido].filter(Boolean).join(" "),
        numeroCaso: c.numero_caso,
        materia: c.materia ?? "",
        juzgado: c.juzgado ?? "",
        domicilioCliente: cl.direccion ?? "",
      }),
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
