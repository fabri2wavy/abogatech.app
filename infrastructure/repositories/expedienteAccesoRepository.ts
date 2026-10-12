import { browserContext } from "../backend/browser";
import { check, message, requireRole } from "../backend/context";
import { one, membershipForUser } from "../backend/data";
import { obtenerAbogados } from "./usuarioRepository";
export async function obtenerAbogadosYSocios() {
  return obtenerAbogados();
}
export async function compartirExpediente(
  expedienteId: string,
  abogadoId: string,
  _otorgadoPor?: string,
): Promise<{ success: boolean; error?: string }> {
  void _otorgadoPor; // No aceptar un actor proporcionado por el navegador.
  try {
    const { db, ctx } = await browserContext();
    requireRole(ctx, ["admin", "asociado_senior"]);
    await one(db, ctx, "cases", expedienteId);
    const m = await membershipForUser(db, ctx, abogadoId);
    const existing = await db
      .from("case_members")
      .select("id, activo")
      .eq("firm_id", ctx.firmId)
      .eq("case_id", expedienteId)
      .eq("membership_id", m.id)
      .maybeSingle();
    check(existing.error);
    if (existing.data?.activo)
      return {
        success: false,
        error: "Este usuario ya tiene acceso al expediente.",
      };
    const r = existing.data
      ? await db
          .from("case_members")
          .update({ activo: true })
          .eq("firm_id", ctx.firmId)
          .eq("id", existing.data.id)
          .select("id")
          .single()
      : await db.from("case_members").insert({
          firm_id: ctx.firmId,
          case_id: expedienteId,
          membership_id: m.id,
          role: "colaborador",
          asignado_por: ctx.userId,
        });
    check(r.error);
    return { success: true };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
