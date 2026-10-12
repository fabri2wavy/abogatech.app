import type { SupabaseClient } from "@supabase/supabase-js";
import type { Rows } from "@/domain/types/database";
import { check, type FirmContext } from "./context";
export type FirmTable = {
  [K in keyof Rows]: Rows[K] extends { firm_id: string | null } ? K : never;
}[keyof Rows];
export async function list<T extends FirmTable>(
  db: SupabaseClient,
  ctx: FirmContext,
  table: T,
): Promise<Rows[T][]> {
  // Paginar evita truncar silenciosamente listados y cálculos a 1000 registros.
  const result: Rows[T][] = [];
  for (let offset = 0; ; offset += 500) {
    const r = await db
      .from(table)
      .select("*")
      .eq("firm_id", ctx.firmId)
      .order("id")
      .range(offset, offset + 499);
    check(r.error);
    const rows = (r.data ?? []) as Rows[T][];
    result.push(...rows);
    if (rows.length < 500) return result;
  }
}
export async function one<T extends FirmTable>(
  db: SupabaseClient,
  ctx: FirmContext,
  table: T,
  id: string,
): Promise<Rows[T]> {
  const r = await db
    .from(table)
    .select("*")
    .eq("firm_id", ctx.firmId)
    .eq("id", id)
    .single();
  check(r.error);
  if (!r.data) throw new Error("Registro no encontrado.");
  return r.data as Rows[T];
}
export async function insert<T extends FirmTable>(
  db: SupabaseClient,
  ctx: FirmContext,
  table: T,
  payload: Partial<Rows[T]>,
): Promise<Rows[T]> {
  const r = await db
    .from(table)
    .insert({ ...payload, firm_id: ctx.firmId })
    .select()
    .single();
  check(r.error);
  return r.data as Rows[T];
}
export async function update<T extends FirmTable>(
  db: SupabaseClient,
  ctx: FirmContext,
  table: T,
  id: string,
  payload: Partial<Rows[T]>,
): Promise<Rows[T]> {
  const {
    id: ignoredId,
    firm_id: ignoredFirm,
    ...fields
  } = payload as Partial<Rows[T]> & { id?: string; firm_id?: string };
  void ignoredId;
  void ignoredFirm;
  const r = await db
    .from(table)
    .update(fields)
    .eq("firm_id", ctx.firmId)
    .eq("id", id)
    .select()
    .single();
  check(r.error);
  return r.data as Rows[T];
}
export async function remove(
  db: SupabaseClient,
  ctx: FirmContext,
  table: FirmTable,
  id: string,
) {
  const r = await db
    .from(table)
    .delete()
    .eq("firm_id", ctx.firmId)
    .eq("id", id)
    .select("id");
  check(r.error);
  if (!r.data?.length)
    throw new Error("Registro inexistente o sin permiso para eliminarlo.");
}
export async function profiles(
  db: SupabaseClient,
  ids: string[],
): Promise<Map<string, Rows["profiles"]>> {
  const result = new Map<string, Rows["profiles"]>();
  const unique = [...new Set(ids.filter(Boolean))];
  for (let i = 0; i < unique.length; i += 100) {
    const r = await db
      .from("profiles")
      .select("*")
      .in("id", unique.slice(i, i + 100));
    check(r.error);
    for (const p of r.data ?? []) result.set(p.id, p);
  }
  return result;
}
export async function membershipForUser(
  db: SupabaseClient,
  ctx: FirmContext,
  userId: string,
) {
  const r = await db
    .from("firm_memberships")
    .select("*")
    .eq("firm_id", ctx.firmId)
    .eq("user_id", userId)
    .eq("status", "activo")
    .single();
  check(r.error);
  if (!r.data || r.data.role === "cliente")
    throw new Error("El usuario no pertenece al equipo activo de esta firma.");
  return r.data as Rows["firm_memberships"];
}
