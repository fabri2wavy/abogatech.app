import "server-only";
import { createClient } from "@supabase/supabase-js";
// Solo para Auth: los datos de negocio se escriben con la sesión y RLS/RPC autorizadas.
export function authAdmin() {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!key)
    throw new Error(
      "Falta configurar la clave privada de administración de Auth en el servidor.",
    );
  return createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
