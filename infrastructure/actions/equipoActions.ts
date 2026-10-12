"use server";
import { serverContext } from "../backend/server";
import { authAdmin } from "../backend/admin";
import { check, message, requireRole } from "../backend/context";
import type { MiembroEquipo } from "@/domain/entities/MiembroEquipo";
type DatosNuevoMiembro = Omit<MiembroEquipo, "id" | "estadoLaboral"> & {
  password: string;
};
export async function registrarNuevoMiembro(
  datos: DatosNuevoMiembro,
): Promise<
  { success: true; data: MiembroEquipo } | { success: false; error: string }
> {
  let newUser: string | undefined;
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    if (!datos.email?.trim() || !datos.password || datos.password.length < 8)
      throw new Error(
        "Indica un correo y una contraseña de al menos 8 caracteres.",
      );
    const admin = authAdmin();
    const result = await admin.auth.admin.createUser({
      email: datos.email.trim(),
      password: datos.password,
      email_confirm: true,
    });
    check(result.error);
    newUser = result.data.user?.id;
    if (!newUser) throw new Error("No se pudo crear el usuario.");
    const r = await db.rpc("app_save_member", {
      p_firm_id: ctx.firmId,
      p_user_id: newUser,
      p_fields: {
        nombres: datos.nombres,
        apellido_paterno: datos.apellidoPaterno,
        apellido_materno: datos.apellidoMaterno,
        telefono: datos.telefono,
        role: datos.rol,
        cargo: datos.cargo,
        especialidad: datos.especialidad,
        estado_laboral: "activo",
      },
      p_create: true,
    });
    check(r.error);
    const { password: unusedPassword, ...member } = datos;
    void unusedPassword;
    return {
      success: true,
      data: { ...member, id: newUser, estadoLaboral: "activo" },
    };
  } catch (e) {
    if (newUser) {
      const cleanup = await authAdmin().auth.admin.deleteUser(newUser);
      if (cleanup.error)
        return {
          success: false,
          error:
            message(e) +
            " No se pudo retirar la cuenta Auth recién creada; requiere revisión administrativa.",
        };
    }
    return { success: false, error: message(e) };
  }
}
export async function actualizarMiembroAction(
  id: string,
  datos: Partial<MiembroEquipo>,
): Promise<{ success: boolean; error?: string }> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    const r = await db.rpc("app_save_member", {
      p_firm_id: ctx.firmId,
      p_user_id: id,
      p_create: false,
      p_fields: {
        nombres: datos.nombres,
        apellido_paterno: datos.apellidoPaterno,
        apellido_materno: datos.apellidoMaterno,
        telefono: datos.telefono,
        role: datos.rol,
        cargo: datos.cargo,
        especialidad: datos.especialidad,
        estado_laboral: datos.estadoLaboral,
      },
    });
    check(r.error);
    return { success: true };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
export async function eliminarMiembroAction(
  id: string,
): Promise<{ success: boolean; error?: string }> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    // Revocar la membresía mantiene el historial y las cuentas usadas en otras firmas.
    const r = await db
      .from("firm_memberships")
      .update({ status: "suspendido" })
      .eq("firm_id", ctx.firmId)
      .eq("user_id", id)
      .select("id")
      .single();
    check(r.error);
    return { success: true };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}

export async function obtenerEmailsEquipo(): Promise<Record<string, string>> {
  const { db, ctx } = await serverContext();
  requireRole(ctx, ["admin"]);
  const r = await db
    .from("firm_memberships")
    .select("user_id")
    .eq("firm_id", ctx.firmId)
    .eq("status", "activo")
    .neq("role", "cliente");
  check(r.error);
  const admin = authAdmin();
  const emails: Record<string, string> = {};
  for (const member of r.data ?? []) {
    const user = await admin.auth.admin.getUserById(member.user_id);
    check(user.error);
    if (user.data.user?.email) emails[member.user_id] = user.data.user.email;
  }
  return emails;
}
