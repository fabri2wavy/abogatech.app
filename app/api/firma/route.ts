import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/infrastructure/supabase/server";
import {
  resolveContext,
  FIRM_COOKIE,
  check,
  message,
} from "@/infrastructure/backend/context";
export async function GET() {
  try {
    const db = await createClient();
    const {
      data: { user },
    } = await db.auth.getUser();
    if (!user)
      return NextResponse.json({ error: "No autenticado" }, { status: 401 });
    const r = await db
      .from("firm_memberships")
      .select("firm_id,role,status,firms(nombre)")
      .eq("user_id", user.id)
      .eq("status", "activo");
    check(r.error);
    return NextResponse.json(
      { firmas: r.data },
      { headers: { "Cache-Control": "no-store" } },
    );
  } catch (e) {
    return NextResponse.json({ error: message(e) }, { status: 403 });
  }
}
export async function POST(request: Request) {
  if (request.headers.get("origin") !== new URL(request.url).origin)
    return NextResponse.json({ error: "Origen no permitido" }, { status: 403 });
  try {
    const { firmId } = await request.json();
    if (typeof firmId !== "string")
      return NextResponse.json({ error: "Firma requerida" }, { status: 400 });
    await resolveContext(await createClient(), firmId, false);
    (await cookies()).set(FIRM_COOKIE, firmId, {
      path: "/",
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      httpOnly: false,
    });
    return NextResponse.json({ success: true });
  } catch (e) {
    return NextResponse.json({ error: message(e) }, { status: 403 });
  }
}
