"use server";

import type { Plantilla, TipoPlantilla } from "@/domain/entities/Plantilla";
import {
  obtenerPlantillas,
  crearPlantilla,
  actualizarPlantilla,
  eliminarPlantilla,
  generarDocumento,
} from "@/infrastructure/repositories/plantillasRepository";
import { serverContext } from "../backend/server";
import { requireRole, message } from "../backend/context";

/* ══════════════════════════════════════════════════════════════
   Contrato de respuesta para Server Actions
   ──────────────────────────────────────────────────────────────
   Todas las actions retornan este shape para que los Client
   Components puedan discriminar éxito/fallo.
   ══════════════════════════════════════════════════════════════ */

interface ActionResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}

/* ══════════════════════════════════════════════════════════════
   ACTION: Verificar si el usuario actual es Administrador
   ══════════════════════════════════════════════════════════════ */

export async function verificarAccesoAdmin(): Promise<
  ActionResponse<{ rol: string }>
> {
  try {
    const { ctx } = await serverContext();
    requireRole(ctx, ["admin"]);
    return { success: true, data: { rol: ctx.role } };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
export async function verificarAccesoPlantillas(): Promise<
  ActionResponse<{ rol: string }>
> {
  try {
    const { ctx } = await serverContext();
    requireRole(ctx, ["admin", "asociado_senior", "abogado"]);
    return { success: true, data: { rol: ctx.role } };
  } catch (e) {
    return { success: false, error: message(e) };
  }
}
export async function fetchPlantillas(): Promise<ActionResponse<Plantilla[]>> {
  try {
    const res = await obtenerPlantillas();

    if (res.error) {
      return { success: false, error: res.error };
    }

    return { success: true, data: res.data ?? [] };
  } catch (err) {
    const mensaje =
      err instanceof Error ? err.message : "Error al obtener plantillas.";
    return { success: false, error: mensaje };
  }
}

/* ══════════════════════════════════════════════════════════════
   ACTION: Crear una nueva plantilla
   ══════════════════════════════════════════════════════════════ */

export async function crearPlantillaAction(payload: {
  nombre: string;
  tipo: TipoPlantilla;
  descripcion?: string;
  contenido: string;
}): Promise<ActionResponse<Plantilla>> {
  try {
    if (!payload.nombre.trim()) {
      return { success: false, error: "El nombre es obligatorio." };
    }

    if (!payload.contenido.trim()) {
      return { success: false, error: "El contenido no puede estar vacío." };
    }

    const res = await crearPlantilla({
      nombre: payload.nombre.trim(),
      tipo: payload.tipo,
      descripcion: payload.descripcion?.trim(),
      contenido: payload.contenido.trim(),
    });

    if (res.error) {
      return { success: false, error: res.error };
    }

    return { success: true, data: res.data! };
  } catch (err) {
    const mensaje =
      err instanceof Error ? err.message : "Error al crear plantilla.";
    return { success: false, error: mensaje };
  }
}

/* ══════════════════════════════════════════════════════════════
   ACTION: Actualizar una plantilla existente
   ══════════════════════════════════════════════════════════════ */

export async function actualizarPlantillaAction(
  id: string,
  payload: {
    nombre?: string;
    tipo?: TipoPlantilla;
    descripcion?: string;
    contenido?: string;
  },
): Promise<ActionResponse<Plantilla>> {
  try {
    const res = await actualizarPlantilla(id, {
      nombre: payload.nombre?.trim(),
      tipo: payload.tipo,
      descripcion: payload.descripcion?.trim(),
      contenido: payload.contenido?.trim(),
    });

    if (res.error) {
      return { success: false, error: res.error };
    }

    return { success: true, data: res.data! };
  } catch (err) {
    const mensaje =
      err instanceof Error ? err.message : "Error al actualizar plantilla.";
    return { success: false, error: mensaje };
  }
}

/* ══════════════════════════════════════════════════════════════
   ACTION: Eliminar una plantilla
   ══════════════════════════════════════════════════════════════ */

export async function eliminarPlantillaAction(
  id: string,
): Promise<ActionResponse<boolean>> {
  try {
    const res = await eliminarPlantilla(id);

    if (res.error) {
      return { success: false, error: res.error };
    }

    return { success: true, data: true };
  } catch (err) {
    const mensaje =
      err instanceof Error ? err.message : "Error al eliminar plantilla.";
    return { success: false, error: mensaje };
  }
}

/* ══════════════════════════════════════════════════════════════
   ACTION: Generar un documento desde plantilla + expediente
   ══════════════════════════════════════════════════════════════ */

export async function generarDocumentoAction(
  plantillaId: string,
  expedienteId: string,
): Promise<ActionResponse<string>> {
  try {
    const res = await generarDocumento(plantillaId, expedienteId);

    if (res.error) {
      return { success: false, error: res.error };
    }

    return { success: true, data: res.data! };
  } catch (err) {
    const mensaje =
      err instanceof Error ? err.message : "Error al generar documento.";
    return { success: false, error: mensaje };
  }
}
