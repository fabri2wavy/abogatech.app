import type { SupabaseClient } from "@supabase/supabase-js";
import type { FirmRole, Rows } from "@/domain/types/database";

export const FIRM_COOKIE = "abogatech_firm_id";
export type FirmContext = {
  userId: string;
  email: string;
  firmId: string;
  membershipId: string;
  role: FirmRole;
};
export function subscriptionIsOperational(
  s: Pick<Rows["subscriptions"], "status" | "trial_end">,
  now = Date.now(),
): boolean {
  // Misma regla que private.firm_is_operational; no inventar una política de cobro distinta.
  return (
    s.status === "active" ||
    s.status === "past_due" ||
    (s.status === "trialing" && !!s.trial_end && Date.parse(s.trial_end) > now)
  );
}
export function selectMembership(
  memberships: Rows["firm_memberships"][],
  requested?: string,
): Rows["firm_memberships"] {
  const active = memberships.filter((m) => m.status === "activo");
  const selected = requested
    ? active.find((m) => m.firm_id === requested)
    : active.length === 1
      ? active[0]
      : undefined;
  if (!selected)
    throw new Error(
      active.length > 1 && !requested
        ? "Selecciona una firma antes de continuar."
        : "No tienes una membresía activa para esta firma.",
    );
  return selected;
}
export async function resolveContext(
  db: SupabaseClient,
  requested?: string,
  operational = true,
): Promise<FirmContext> {
  const {
    data: { user },
    error,
  } = await db.auth.getUser();
  if (error || !user)
    throw new Error("Sesión expirada. Inicia sesión nuevamente.");
  const memberships = await db
    .from("firm_memberships")
    .select("*")
    .eq("user_id", user.id)
    .eq("status", "activo");
  if (memberships.error) throw new Error(memberships.error.message);
  const m = selectMembership(memberships.data ?? [], requested);
  if (operational) {
    const subscriptions = await db
      .from("subscriptions")
      .select("*")
      .eq("firm_id", m.firm_id);
    if (subscriptions.error) throw new Error(subscriptions.error.message);
    if (!(subscriptions.data ?? []).some((s) => subscriptionIsOperational(s)))
      throw new Error(
        "La prueba ha vencido o la suscripción no está activa. Contacta al administrador de la plataforma.",
      );
  }
  return {
    userId: user.id,
    email: user.email ?? "",
    firmId: m.firm_id,
    membershipId: m.id,
    role: m.role as FirmRole,
  };
}
export function requireRole(ctx: FirmContext, roles: readonly FirmRole[]) {
  if (!roles.includes(ctx.role))
    throw new Error("No tienes permisos para esta operación.");
}
export function message(error: unknown): string {
  return error instanceof Error
    ? error.message
    : "No se pudo completar la operación.";
}
export function check(error: { message: string } | null) {
  if (error) throw new Error(error.message);
}
export function fullName(
  p?: {
    nombres: string | null;
    apellido_paterno: string | null;
    apellido_materno: string | null;
  } | null,
) {
  return p
    ? [p.nombres, p.apellido_paterno, p.apellido_materno]
        .filter(Boolean)
        .join(" ") || "Sin registrar"
    : "Sin registrar";
}
