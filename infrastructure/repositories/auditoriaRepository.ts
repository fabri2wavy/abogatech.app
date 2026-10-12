"use server";
import { serverContext } from "../backend/server";
import { list } from "../backend/data";
import { message } from "../backend/context";
import type { AuditoriaLog } from "@/domain/entities/AuditoriaLog";
import type { RepositoryResponse } from "@/domain/types/RepositoryResponse";
export type CreateAuditoriaLogDTO = Omit<
  AuditoriaLog,
  "id" | "creado_en" | "usuario_id"
>;
export async function obtenerLogs(): Promise<
  RepositoryResponse<AuditoriaLog[]>
> {
  try {
    const { db, ctx } = await serverContext();
    return {
      data: (await list(db, ctx, "audit_logs"))
        .sort((a, b) => b.created_at.localeCompare(a.created_at))
        .map((r) => ({
          id: r.id,
          usuario_id: r.actor_user_id ?? "",
          accion:
            (
              {
                insert: "CREAR",
                update: "EDITAR",
                delete: "ELIMINAR",
              } as Record<string, string>
            )[r.accion] ?? r.accion,
          entidad: r.entidad,
          entidad_id: r.entidad_id ?? "",
          detalles: { anteriores: r.datos_anteriores, nuevos: r.datos_nuevos },
          creado_en: r.created_at,
        })),
      error: null,
    };
  } catch (e) {
    return { data: null, error: message(e) };
  }
}
