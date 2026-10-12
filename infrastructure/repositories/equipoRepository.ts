import { browserContext } from "../backend/browser";
import { list, profiles } from "../backend/data";
import {
  actualizarMiembroAction,
  obtenerEmailsEquipo,
} from "../actions/equipoActions";
import type { MiembroEquipo } from "@/domain/entities/MiembroEquipo";
export async function obtenerEquipo(): Promise<MiembroEquipo[]> {
  const { db, ctx } = await browserContext();
  const [members, details] = await Promise.all([
    list(db, ctx, "firm_memberships"),
    list(db, ctx, "firm_member_details"),
  ]);
  const staff = members.filter(
    (m) => m.role !== "cliente" && m.status === "activo",
  );
  const p = await profiles(
    db,
    staff.map((m) => m.user_id),
  );
  const emails = ctx.role === "admin" ? await obtenerEmailsEquipo() : {};
  return staff.map((m) => {
    const person = p.get(m.user_id);
    const d = details.find((d) => d.user_id === m.user_id);
    return {
      id: m.user_id,
      nombres: person?.nombres ?? "",
      apellidoPaterno: person?.apellido_paterno ?? "",
      apellidoMaterno: person?.apellido_materno ?? "",
      email: emails[m.user_id] ?? (m.user_id === ctx.userId ? ctx.email : null),
      telefono: person?.telefono ?? null,
      rol: m.role,
      cargo: d?.cargo ?? "",
      especialidad: d?.especialidad ?? null,
      estadoLaboral: (d?.estado_laboral ??
        "activo") as MiembroEquipo["estadoLaboral"],
    };
  });
}
export async function obtenerMiembroPorId(
  id: string,
): Promise<MiembroEquipo | null> {
  return (await obtenerEquipo()).find((m) => m.id === id) ?? null;
}
export async function actualizarMiembro(
  id: string,
  datos: Partial<MiembroEquipo>,
): Promise<boolean> {
  const r = await actualizarMiembroAction(id, datos);
  if (!r.success) throw new Error(r.error);
  return true;
}
