"use server";
import { serverContext } from "../backend/server";
import { list, insert, update, remove } from "../backend/data";
import { message, requireRole } from "../backend/context";
import type { ConfiguracionGlobal } from "@/domain/entities/ConfiguracionGlobal";
import type { RepositoryResponse } from "@/domain/types/RepositoryResponse";
export type CreateConfiguracionDTO = Omit<
  ConfiguracionGlobal,
  "id" | "creado_en"
>;
export type UpdateConfiguracionDTO = Partial<CreateConfiguracionDTO>;
export async function obtenerConfiguraciones(
  categoria?: string,
): Promise<RepositoryResponse<ConfiguracionGlobal[]>> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    return {
      data: (await list(db, ctx, "firm_settings")).filter(
        (r) => !categoria || r.categoria === categoria,
      ),
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function crearConfiguracion(
  p: CreateConfiguracionDTO,
): Promise<RepositoryResponse<ConfiguracionGlobal>> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    return {
      data: await insert(db, ctx, "firm_settings", {
        categoria: p.categoria,
        valor: p.valor,
        activo: p.activo,
        creado_por: ctx.userId,
      }),
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function actualizarConfiguracion(
  id: string,
  p: UpdateConfiguracionDTO,
): Promise<RepositoryResponse<ConfiguracionGlobal>> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    return {
      data: await update(db, ctx, "firm_settings", id, {
        categoria: p.categoria,
        valor: p.valor,
        activo: p.activo,
      }),
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
export async function eliminarConfiguracion(
  id: string,
): Promise<RepositoryResponse<boolean>> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    await remove(db, ctx, "firm_settings", id);
    return { data: true, error: null };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
