"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowRight, Eye, EyeOff } from "lucide-react";
import { iniciarSesion } from "@/infrastructure/repositories/authRepository";

import { AuthCard } from "@/components/ui/AuthCard";
import { FormField } from "@/components/ui/FormField";
import { Alert } from "@/components/ui/Alert";
import { Button } from "@/components/ui/Button";
import styles from "./page.module.css";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [mensaje, setMensaje] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setMensaje("");

    try {
      const resultado = await iniciarSesion(email.trim(), password);
      if (!resultado.success) {
        setMensaje(`Error al iniciar sesión. ${resultado.error || "Inténtalo nuevamente."}`);
        setLoading(false);
        return;
      }
      setMensaje("Sesión iniciada. Abriendo tu espacio de trabajo…");
      router.push("/dashboard");
    } catch {
      setMensaje("Error de conexión. Inténtalo nuevamente en unos momentos.");
      setLoading(false);
    }
  };

  const isError = mensaje.toLowerCase().includes("error");

  return (
    <AuthCard>
      <Alert
        variant={isError ? "error" : "success"}
        visible={!!mensaje}
      >
        {mensaje}
      </Alert>

      <form onSubmit={handleLogin} className={styles.form}>
        <FormField
          label="Correo electrónico"
          id="login-email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          placeholder="nombre@tuorganizacion.com"
          autoComplete="username"
          variant="light"
          disabled={loading}
        />

        <div className={styles.passwordField}>
          <FormField
            label="Contraseña"
            id="login-password"
            type={showPassword ? "text" : "password"}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            placeholder="••••••••"
            autoComplete="current-password"
            variant="light"
            disabled={loading}
            className={styles.passwordInput}
          />
          <button type="button" className={styles.passwordToggle} aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"} aria-pressed={showPassword} onClick={() => setShowPassword(!showPassword)}>
            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        </div>

        <div className={styles.buttonGroup}>
          <Button
            type="submit"
            variant="primary"
            size="lg"
            fullWidth
            loading={loading}
          >
            {loading ? "Ingresando…" : "Ingresar a mi espacio"}
            {!loading && <ArrowRight size={17} />}
          </Button>
        </div>
      </form>
    </AuthCard>
  );
}
