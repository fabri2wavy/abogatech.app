import Image from "next/image";
import { BriefcaseBusiness, CalendarDays, LockKeyhole, Sparkles } from "lucide-react";
import styles from "./AuthCard.module.css";

interface AuthCardProps {
  children: React.ReactNode;
  title?: string;
  subtitle?: string;
}

function LoginLogo() {
  return (
    <Image
      src="/brand/abogatech_logo_png.png"
      alt="ABOGATECH"
      width={500}
      height={500}
      sizes="160px"
      priority
      className={styles.headerLogo}
    />
  );
}

export function AuthCard({ children, title = "Tu próximo gran caso empieza aquí.", subtitle = "Ingresa a tu espacio de trabajo y conecta cada parte de tu práctica legal." }: AuthCardProps) {
  return (
    <main className={styles.root}>
      <section className={styles.showcase} aria-label="Conoce ABOGATECH">
        <header className={styles.brandHeader}>
          <LoginLogo />
          <span className={styles.edition}>LEGAL TECH</span>
        </header>

        <div className={styles.story}>
          <span className={styles.eyebrow}><span /> EL DERECHO EVOLUCIONA. TÚ TAMBIÉN.</span>
          <h2>Tu práctica legal.<br /><span>Una nueva dimensión.</span></h2>
          <p>Menos tareas dispersas. Más claridad para decidir.<br className={styles.desktopBreak} /> Todo tu trabajo, conectado en un solo lugar.</p>

          <div className={styles.ecosystem}>
            <div className={styles.orbit} aria-hidden="true" />
            <div className={styles.logoPlate}>
              <Image src="/brand/abogatech-logo.png" alt="Logo de ABOGATECH en azul y plata" width={400} height={400} priority className={styles.heroLogo} />
            </div>
            <div className={styles.features}>
              <div className={styles.feature}><BriefcaseBusiness size={18} /><span>Expedientes<small>Cada detalle, en su lugar</small></span></div>
              <div className={styles.feature}><CalendarDays size={18} /><span>Agenda legal<small>Tu tiempo, bajo control</small></span></div>
              <div className={styles.feature}><Sparkles size={18} /><span>Inteligencia artificial<small>Una nueva forma de trabajar</small></span></div>
            </div>
          </div>
        </div>

        <footer className={styles.showcaseFooter}>
          <span>CONSTRUIDO PARA LA PRÁCTICA LEGAL DE HOY.</span>
          <span className={styles.footerLine} />
          <span>ABOGATECH</span>
        </footer>
      </section>

      <section className={styles.access} aria-labelledby="login-title">
        <div className={styles.mobileBrand}><LoginLogo /></div>
        <div className={styles.accessTop}><LockKeyhole size={14} /> TU ESPACIO DE TRABAJO</div>
        <div className={styles.card}>
          <span className={styles.welcome}>BIENVENIDO A ABOGATECH</span>
          <h1 id="login-title">{title}</h1>
          <p className={styles.subtitle}>{subtitle}</p>
          <div className={styles.content}>{children}</div>
          <div className={styles.accessNote}><LockKeyhole size={15} /><span>Acceso exclusivo para usuarios autorizados.</span></div>
        </div>
        <footer className={styles.footer}><span>© {new Date().getFullYear()} ABOGATECH</span><span>Derecho + Tecnología</span></footer>
      </section>
    </main>
  );
}
