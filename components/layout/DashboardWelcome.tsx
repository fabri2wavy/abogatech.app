import Link from "next/link";
import { ArrowUpRight, CalendarDays } from "lucide-react";
import styles from "./DashboardWelcome.module.css";

export function DashboardWelcome({ nombre, label, description, href = "/dashboard/agenda", action = "Ver mi agenda" }: { nombre: string; label: string; description: string; href?: string; action?: string }) {
  const fecha = new Date().toLocaleDateString("es-BO", { weekday: "long", day: "numeric", month: "long" });
  return (
    <section className={styles.welcome}>
      <div className={styles.copy}>
        <span className={styles.eyebrow}>{label}</span>
        <h1>Hola, {nombre || "bienvenido"}<span>.</span></h1>
        <p>{description}</p>
        <Link href={href} className={styles.action}>{action}<ArrowUpRight size={16} /></Link>
      </div>
      <div className={styles.date}><CalendarDays size={15} /><span>{fecha}</span></div>
      <div className={styles.geometry} aria-hidden="true"><span /><span /><span /></div>
    </section>
  );
}
