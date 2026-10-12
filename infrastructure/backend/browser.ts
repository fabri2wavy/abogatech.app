import { createClient } from "../supabase/client";
import { FIRM_COOKIE, resolveContext } from "./context";
export async function browserContext(operational = true) {
  const db = createClient();
  const selected =
    typeof document === "undefined"
      ? undefined
      : document.cookie
          .split("; ")
          .find((c) => c.startsWith(FIRM_COOKIE + "="))
          ?.split("=")[1];
  const ctx = await resolveContext(
    db,
    selected ? decodeURIComponent(selected) : undefined,
    operational,
  );
  return { db, ctx };
}
