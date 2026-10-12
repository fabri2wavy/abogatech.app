import { browserContext } from "../backend/browser";
import { FIRM_COOKIE, message } from "../backend/context";
/* ══════════════════════════════════════════════════════════════
   Repositorio de Autenticación (Client-Side)
   ──────────────────────────────────────────────────────────────
   Centraliza TODA interacción con supabase.auth para que los
   componentes de la capa de presentación (app/, components/)
   NUNCA importen ni instancien el cliente de Supabase.

   Regla de Arquitectura:
     UI → authRepository → Supabase Client SDK
   ══════════════════════════════════════════════════════════════ */

import { createClient } from "@/infrastructure/supabase/client";

/* ── Iniciar sesión ─────────────────────────────────────────── */
export async function iniciarSesion(
  email: string,
  password: string,
): Promise<{ success: boolean; error?: string }> {
  const supabase = createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    if (error.name === "AuthRetryableFetchError" && !error.status) {
      return {
        success: false,
        error:
          "No se pudo conectar con el servicio de autenticación. Comprueba tu conexión e inténtalo nuevamente.",
      };
    }

    if (error.code === "invalid_credentials") {
      return {
        success: false,
        error: "El correo o la contraseña no son correctos.",
      };
    }

    if (error.code === "email_not_confirmed") {
      return {
        success: false,
        error: "Confirma tu correo electrónico antes de ingresar.",
      };
    }

    if (error.status === 429) {
      return {
        success: false,
        error:
          "Se realizaron demasiados intentos. Espera unos minutos antes de volver a ingresar.",
      };
    }

    return {
      success: false,
      error:
        "El servicio de autenticación no pudo completar la solicitud. Inténtalo nuevamente en unos momentos.",
    };
  }

  try {
    await browserContext();
  } catch (e) {
    return { success: false, error: message(e) };
  }
  return { success: true };
}

/* ── Registrar usuario (dev-only) ───────────────────────────── */
export async function registrarUsuario(
  email: string,
  password: string,
): Promise<{ success: boolean; error?: string }> {
  const supabase = createClient();
  const { error } = await supabase.auth.signUp({ email, password });

  if (error) {
    return { success: false, error: error.message };
  }

  return { success: true };
}

/* ── Cerrar sesión ──────────────────────────────────────────── */
export async function cerrarSesion(): Promise<void> {
  const supabase = createClient();
  await supabase.auth.signOut();
  document.cookie = `${FIRM_COOKIE}=; Path=/; Max-Age=0; SameSite=Lax`;
}

/* ── Obtener ID del usuario autenticado actual ──────────────── */
export async function obtenerUsuarioActualId(): Promise<string | null> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  return user?.id ?? null;
}

/* ── Obtener perfil completo con rol (para sidebar/header) ──── */
export interface PerfilConRol {
  email: string;
  rol: string;
}

export async function obtenerPerfilConRol(): Promise<PerfilConRol | null> {
  const { ctx } = await browserContext(false);
  return { email: ctx.email, rol: ctx.role };
}
