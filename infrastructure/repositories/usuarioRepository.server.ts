import { serverContext } from "../backend/server";
import { profiles } from "../backend/data";
import { fullName } from "../backend/context";
import type { UsuarioPerfil } from "@/domain/entities/UsuarioPerfil";
export async function obtenerPerfilActualServer(): Promise<UsuarioPerfil | null> {
  const { db, ctx } = await serverContext(false);
  const p = (await profiles(db, [ctx.userId])).get(ctx.userId);
  return { id: ctx.userId, nombre_completo: fullName(p), rol: ctx.role };
}
