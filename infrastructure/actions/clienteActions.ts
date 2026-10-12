"use server";
import { serverContext } from "../backend/server";
import { update } from "../backend/data";
import { message, requireRole } from "../backend/context";
import type { Rows } from "@/domain/types/database";
export async function convertirClienteActivo(
  clienteId: string,
  datos: Record<string, unknown>,
): Promise<{ success: boolean; error?: string }> {
  try {
    const { db, ctx } = await serverContext();
    requireRole(ctx, ["admin", "asociado_senior", "abogado"]);
    const allowed = [
      "ci",
      "expedido",
      "fecha_nacimiento",
      "nacionalidad",
      "estado_civil",
      "profesion",
      "direccion",
      "telefono",
      "telefono_laboral",
      "direccion_oficina",
    ];
    const fields: Record<string, string | null> = {};
    for (const key of allowed)
      if (typeof datos[key] === "string" || datos[key] === null)
        fields[key] = datos[key] as string | null;
    await update(db, ctx, "clients", clienteId, {
      ...fields,
      etapa_comercial: "activo",
    } as Partial<Rows["clients"]>);
    return { success: true };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
