import "server-only";
import { cookies } from "next/headers";
import { createClient } from "../supabase/server";
import { FIRM_COOKIE, resolveContext } from "./context";
export async function serverContext(operational = true) {
  const db = await createClient();
  const ctx = await resolveContext(
    db,
    (await cookies()).get(FIRM_COOKIE)?.value,
    operational,
  );
  return { db, ctx };
}
