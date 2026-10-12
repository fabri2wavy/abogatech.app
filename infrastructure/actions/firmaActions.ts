"use server";
import { serverContext } from "../backend/server";
import { createClient } from "../supabase/server";
import { check, message, requireRole } from "../backend/context";
import type { FirmRole } from "@/domain/types/database";

export async function obtenerSuscripcionActual() {
  const { db, ctx } = await serverContext(false);
  const r = await db
    .from("subscriptions")
    .select("*")
    .eq("firm_id", ctx.firmId);
  check(r.error);
  return r.data;
}
export async function crearInvitacionEquipo(
  email: string,
  role: Exclude<FirmRole, "cliente">,
) {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    const r = await db.rpc("create_staff_invitation", {
      p_firm_id: ctx.firmId,
      p_email: email,
      p_role: role,
      p_expires_in_days: 7,
    });
    check(r.error);
    return { success: true, invitationId: r.data as string };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
export async function crearInvitacionPortal(clientId: string, email: string) {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    const r = await db.rpc("create_client_portal_invitation", {
      p_firm_id: ctx.firmId,
      p_client_id: clientId,
      p_email: email,
      p_expires_in_days: 7,
    });
    check(r.error);
    return { success: true, invitationId: r.data as string };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
export async function aceptarInvitacion(invitationId: string) {
  try {
    const db = await createClient();
    const r = await db.rpc("accept_firm_invitation", {
      p_invitation_id: invitationId,
    });
    check(r.error);
    return { success: true, membershipId: r.data as string };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
export async function revocarInvitacion(invitationId: string) {
  try {
    const { db, ctx } = await serverContext(false);
    requireRole(ctx, ["admin"]);
    const invitation = await db
      .from("firm_invitations")
      .select("id")
      .eq("firm_id", ctx.firmId)
      .eq("id", invitationId)
      .single();
    check(invitation.error);
    const r = await db.rpc("revoke_firm_invitation", {
      p_invitation_id: invitationId,
    });
    check(r.error);
    return { success: true };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
