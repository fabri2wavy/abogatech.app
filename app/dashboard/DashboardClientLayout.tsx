"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { ArrowUpRight, BookOpen, BriefcaseBusiness, CalendarDays, ChartNoAxesCombined, ChevronRight, CircleUserRound, ClipboardList, Landmark, LayoutDashboard, Menu, Settings2, ShieldCheck, Sparkles, Users, UsersRound, X, type LucideIcon } from "lucide-react";
import BotonSalir from "@/components/layout/BotonSalir";
import PerfilUsuario from "@/components/layout/PerfilUsuario";
import WidgetAsistente from "@/components/WidgetAsistente";
import { Brand } from "@/components/ui/Brand";
import styles from "./DashboardClientLayout.module.css";

type NavItem = { href: string; label: string; icon: LucideIcon; section?: string };
const inicio: NavItem = { href: "/dashboard", label: "Vista general", icon: LayoutDashboard };
const casos: NavItem = { href: "/dashboard/casos", label: "Expedientes", icon: BriefcaseBusiness };
const clientes: NavItem = { href: "/dashboard/clientes", label: "Clientes", icon: Users };
const agenda: NavItem = { href: "/dashboard/agenda", label: "Agenda", icon: CalendarDays };
const finanzas: NavItem = { href: "/dashboard/finanzas", label: "Finanzas", icon: Landmark };
const plantillas: NavItem = { href: "/dashboard/plantillas", label: "Plantillas", icon: BookOpen };
const equipo: NavItem = { href: "/dashboard/equipo", label: "Equipo", icon: UsersRound };
const reportes: NavItem = { href: "/dashboard/reportes", label: "Reportes", icon: ChartNoAxesCombined };
const perfil: NavItem = { href: "/dashboard/perfil", label: "Mi perfil", icon: CircleUserRound, section: "MI CUENTA" };
const roleLabels: Record<string, string> = { admin: "Administración", abogado: "Abogado", asociado_senior: "Asociado senior", finanzas: "Finanzas", cliente: "Portal del cliente" };

function getNavItems(rol: string): NavItem[] {
  if (rol === "admin") return [inicio, casos, clientes, agenda, finanzas, plantillas, equipo, reportes,
    { href: "/dashboard/configuracion", label: "Configuración", icon: Settings2, section: "ADMINISTRACIÓN" },
    { href: "/dashboard/auditoria", label: "Auditoría", icon: ClipboardList }];
  if (rol === "abogado" || rol === "asociado_senior") return [inicio, { ...casos, label: "Mis casos" }, { ...clientes, label: "Mis clientes" }, agenda, plantillas, ...(rol === "asociado_senior" ? [equipo, finanzas, reportes] : []), perfil];
  if (rol === "finanzas") return [inicio, finanzas, perfil];
  return [inicio, { ...casos, label: "Mis expedientes" }];
}

export default function DashboardClientLayout({ children, rol, userId }: { children: React.ReactNode; rol: string; userId: string | null }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const pathname = usePathname();
  const sidebarRef = useRef<HTMLElement>(null);
  const menuRef = useRef<HTMLButtonElement>(null);
  const restoreFocusRef = useRef(false);
  const navItems = getNavItems(rol);
  const isActive = (href: string) => href === "/dashboard" ? pathname === href : pathname.startsWith(href);
  const currentPage = navItems.find(item => isActive(item.href))?.label ?? "Mi espacio";
  const hasAssistant = rol === "abogado" || rol === "admin";

  useEffect(() => {
    if (!sidebarOpen) {
      if (restoreFocusRef.current) menuRef.current?.focus();
      restoreFocusRef.current = false;
      return;
    }
    restoreFocusRef.current = true;
    const sidebar = sidebarRef.current;
    const focusable = () => sidebar?.querySelectorAll<HTMLElement>('a[href], button:not([disabled])');
    focusable()?.[0]?.focus();
    const close = () => setSidebarOpen(false);
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") close();
      if (event.key !== "Tab") return;
      const elements = focusable();
      if (!elements?.length) return;
      const first = elements[0];
      const last = elements[elements.length - 1];
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
      else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
    };
    const desktop = window.matchMedia("(min-width: 1024px)");
    const onResize = () => { if (desktop.matches) setSidebarOpen(false); };
    document.addEventListener("keydown", onKeyDown);
    desktop.addEventListener("change", onResize);
    return () => { document.removeEventListener("keydown", onKeyDown); desktop.removeEventListener("change", onResize); };
  }, [sidebarOpen]);

  return (
    <div className={styles.root}>
      <a href="#workspace-content" className={styles.skipLink}>Ir al contenido</a>
      {sidebarOpen && <button className={styles.overlay} aria-label="Cerrar menú" onClick={() => setSidebarOpen(false)} tabIndex={-1} />}
      <aside id="workspace-navigation" ref={sidebarRef} className={`${styles.sidebar} ${sidebarOpen ? styles.open : ""}`} aria-label="Menú principal">
        <div className={styles.sidebarBrand}>
          <Link href="/dashboard" onClick={() => setSidebarOpen(false)} aria-label="ABOGATECH, inicio"><Brand light /></Link>
          <button className={styles.closeMenu} aria-label="Cerrar menú" onClick={() => setSidebarOpen(false)}><X size={20} /></button>
        </div>
        <div className={styles.workspaceLabel}><span className={styles.workspaceIcon}><BriefcaseBusiness size={15} /></span><span>Mi espacio de trabajo<small>{roleLabels[rol] ?? "Mi cuenta"}</small></span></div>
        <nav className={styles.nav} aria-label="Módulos">
          <p className={styles.sectionLabel}>PLATAFORMA</p>
          {navItems.map(({ href, label, icon: Icon, section }) => (
            <div key={href}>
              {section && <p className={styles.sectionLabel}>{section}</p>}
              <Link href={href} aria-current={isActive(href) ? "page" : undefined} className={`${styles.navItem} ${isActive(href) ? styles.active : ""}`} onClick={() => setSidebarOpen(false)}>
                <Icon size={18} strokeWidth={1.7} /><span>{label}</span>{isActive(href) && <span className={styles.activeDot} />}
              </Link>
            </div>
          ))}
        </nav>
        {hasAssistant && <Link href="/asistente" className={styles.assistantCard}><span className={styles.assistantIcon}><Sparkles size={18} /></span><span>ABOGATECH IA<small>Potencia tu práctica legal</small></span><ArrowUpRight size={16} /></Link>}
        <div className={styles.sidebarFooter}><PerfilUsuario /><BotonSalir /></div>
      </aside>

      <div className={styles.workspace} inert={sidebarOpen}>
        <header className={styles.topbar}>
          <div className={styles.breadcrumb}>
            <button ref={menuRef} className={styles.menuButton} onClick={() => setSidebarOpen(true)} aria-label="Abrir menú" aria-expanded={sidebarOpen} aria-controls="workspace-navigation"><Menu size={22} /></button>
            <span className={styles.breadcrumbBrand}>Workspace</span><ChevronRight size={14} className={styles.breadcrumbBrand} /><span>{currentPage}</span>
          </div>
          <span className={styles.roleBadge}><ShieldCheck size={14} /><span>{roleLabels[rol] ?? "Mi cuenta"}</span></span>
        </header>
        <main id="workspace-content" tabIndex={-1} className={styles.content}><div className={styles.contentInner}>{children}</div><footer className={styles.contentFooter}>ABOGATECH<span>Derecho + Tecnología</span></footer></main>
      </div>
      {userId && hasAssistant && <div hidden={sidebarOpen} inert={sidebarOpen}><WidgetAsistente abogadoId={userId} /></div>}
    </div>
  );
}
