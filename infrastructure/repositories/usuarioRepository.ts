import { browserContext } from "../backend/browser";
import { fullName, check, message } from "../backend/context";
import { list, profiles } from "../backend/data";
import type { UsuarioPerfil } from "@/domain/entities/UsuarioPerfil";
export type { UsuarioPerfil };
export function mapearUsuario(fila: {
  id: string;
  nombres: string | null;
  apellido_paterno: string | null;
  apellido_materno: string | null;
  rol: string;
}): UsuarioPerfil {
  return { id: fila.id, nombre_completo: fullName(fila), rol: fila.rol };
}
export async function obtenerAbogados(): Promise<UsuarioPerfil[]> {
  const { db, ctx } = await browserContext();
  const members = (await list(db, ctx, "firm_memberships")).filter(
    (m) => m.status === "activo" && m.role !== "cliente",
  );
  const p = await profiles(
    db,
    members.map((m) => m.user_id),
  );
  return members.map((m) => ({
    id: m.user_id,
    nombre_completo: fullName(p.get(m.user_id)),
    rol: m.role,
  }));
}
export async function obtenerPerfilActual(): Promise<UsuarioPerfil | null> {
  const { db, ctx } = await browserContext(false);
  const p = await profiles(db, [ctx.userId]);
  return {
    id: ctx.userId,
    nombre_completo: fullName(p.get(ctx.userId)),
    rol: ctx.role,
  };
}
export interface PerfilEditable {
  id: string;
  nombres: string;
  apellidoPaterno: string;
  apellidoMaterno: string;
  telefono: string;
  email: string;
  rol: string;
}
export async function obtenerPerfilEditable(): Promise<PerfilEditable | null> {
  const { db, ctx } = await browserContext(false);
  const p = (await profiles(db, [ctx.userId])).get(ctx.userId);
  if (!p) return null;
  return {
    id: p.id,
    nombres: p.nombres ?? "",
    apellidoPaterno: p.apellido_paterno ?? "",
    apellidoMaterno: p.apellido_materno ?? "",
    telefono: p.telefono ?? "",
    email: ctx.email,
    rol: ctx.role,
  };
}
export async function actualizarPerfilPropio(datos: {
  nombres: string;
  apellidoPaterno: string;
  apellidoMaterno: string;
  telefono: string;
}): Promise<{ success: boolean; error?: string }> {
  try {
    const { db, ctx } = await browserContext(false);
    const r = await db
      .from("profiles")
      .update({
        nombres: datos.nombres,
        apellido_paterno: datos.apellidoPaterno,
        apellido_materno: datos.apellidoMaterno,
        telefono: datos.telefono,
      })
      .eq("id", ctx.userId)
      .select("id")
      .single();
    check(r.error);
    return { success: true };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
export async function cambiarContrasena(
  nuevaContrasena: string,
): Promise<{ success: boolean; error?: string }> {
  try {
    const { db } = await browserContext(false);
    const r = await db.auth.updateUser({ password: nuevaContrasena });
    check(r.error);
    return { success: true };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
