"use client";

import React, { useEffect, useState } from "react";
import { Briefcase, Users, Calendar, CalendarClock, Clock, AlertCircle, Coffee, ArrowUpRight, BookOpen, ChartNoAxesCombined, UsersRound } from "lucide-react";
import { obtenerTotalClientes } from "@/infrastructure/repositories/clienteRepository";
import { obtenerTotalExpedientes } from "@/infrastructure/repositories/expedienteRepository";
import Link from "next/link";
import { DashboardWelcome } from "@/components/layout/DashboardWelcome";
import styles from "./Overview.module.css";
import { EventoAgendaDetallado } from "@/domain/entities/EventoAgenda";

/* ══════════════════════════════════════════════════════════════
   Helpers de fecha / hora
   ══════════════════════════════════════════════════════════════ */

function esHoy(fechaISO: string): boolean {
  const fecha = new Date(fechaISO);
  const hoy = new Date();
  return (
    fecha.getFullYear() === hoy.getFullYear() &&
    fecha.getMonth() === hoy.getMonth() &&
    fecha.getDate() === hoy.getDate()
  );
}

function esManana(fechaISO: string): boolean {
  const fecha = new Date(fechaISO);
  const manana = new Date();
  manana.setDate(manana.getDate() + 1);
  return (
    fecha.getFullYear() === manana.getFullYear() &&
    fecha.getMonth() === manana.getMonth() &&
    fecha.getDate() === manana.getDate()
  );
}

function formatearHora(fechaISO: string): string {
  return new Date(fechaISO).toLocaleTimeString("es-ES", {
    hour: "2-digit",
    minute: "2-digit",
  });
}

const TIPO_EVENTO_LABEL: Record<string, { label: string; className: string }> = {
  audiencia: {
    label: "Audiencia",
    className: "bg-purple-100 text-purple-700 border border-purple-200",
  },
  reunion: {
    label: "Reunión",
    className: "bg-sky-100 text-sky-700 border border-sky-200",
  },
  vencimiento: {
    label: "Vencimiento",
    className: "bg-rose-100 text-rose-700 border border-rose-200",
  },
  tarea: {
    label: "Tarea",
    className: "bg-amber-100 text-amber-700 border border-amber-200",
  },
};

/* ══════════════════════════════════════════════════════════════
   Props
   ══════════════════════════════════════════════════════════════ */

interface AdminDashboardProps {
  nombre: string;
  eventos: EventoAgendaDetallado[];
}

/* ══════════════════════════════════════════════════════════════
   Componente: Panel de Próximos Eventos
   ══════════════════════════════════════════════════════════════ */

function PanelProximosEventos({ eventos }: { eventos: EventoAgendaDetallado[] }) {
  const eventosHoy = eventos.filter((e) => esHoy(e.fechaInicio));
  const eventosManana = eventos.filter((e) => esManana(e.fechaInicio));
  const hayEventos = eventosHoy.length > 0 || eventosManana.length > 0;

  if (!hayEventos) {
    return (
      <div
        id="panel-proximos-eventos-vacio"
        className="rounded-xl border border-blue-100 bg-white
                   p-6 shadow-sm animate-in fade-in duration-500"
      >
        <div className="flex items-center gap-4">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-blue-50">
            <Coffee className="w-6 h-6 text-blue-600" strokeWidth={1.5} />
          </div>
          <div>
            <h3 className="text-base font-bold text-gray-900">
              Agenda libre para hoy
            </h3>
            <p className="text-sm text-gray-500 mt-0.5">
              No hay audiencias ni vencimientos programados para hoy o mañana. ¡Buen momento para avanzar!
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      id="panel-proximos-eventos"
      className="rounded-xl border border-gray-200 bg-white shadow-sm overflow-hidden
                 animate-in fade-in duration-500"
    >
      {/* Header */}
      <div className="px-5 py-4 border-b border-gray-100 bg-gradient-to-r from-indigo-50/60 to-sky-50/60">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-indigo-100">
            <CalendarClock className="w-5 h-5 text-indigo-600" strokeWidth={1.5} />
          </div>
          <div>
            <h3 className="text-sm font-bold text-gray-900">Próximos Eventos</h3>
            <p className="text-xs text-gray-500">
              {eventosHoy.length} hoy · {eventosManana.length} mañana
            </p>
          </div>
        </div>
      </div>

      {/* Eventos de HOY */}
      {eventosHoy.length > 0 && (
        <div className="px-5 py-3">
          <div className="flex items-center gap-2 mb-3">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-700 border border-blue-200">
              <AlertCircle className="w-3 h-3" />
              Hoy
            </span>
          </div>
          <div className="space-y-2">
            {eventosHoy.map((evento) => {
              const tipoCfg = TIPO_EVENTO_LABEL[evento.tipoEvento] ?? TIPO_EVENTO_LABEL.tarea;
              return (
                <div
                  key={evento.id}
                  className="flex items-center gap-4 rounded-lg border border-blue-100 bg-blue-50/40
                             px-4 py-3 transition-all duration-150 hover:shadow-sm hover:bg-blue-50/70"
                >
                  {/* Hora */}
                  <div className="flex-shrink-0 text-center min-w-[52px]">
                    <span className="text-sm font-bold text-gray-900">
                      {formatearHora(evento.fechaInicio)}
                    </span>
                  </div>

                  {/* Separador */}
                  <div className="w-px h-8 bg-blue-200 flex-shrink-0" />

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-900 truncate" title={evento.titulo}>
                      {evento.titulo}
                    </p>
                    {evento.expediente && (
                      <p className="text-xs text-gray-500 truncate mt-0.5">
                        Caso {evento.expediente.numeroCaso} — {evento.expediente.titulo}
                      </p>
                    )}
                  </div>

                  {/* Badge tipo */}
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium flex-shrink-0 ${tipoCfg.className}`}>
                    {tipoCfg.label}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Eventos de MAÑANA */}
      {eventosManana.length > 0 && (
        <div className={`px-5 py-3 ${eventosHoy.length > 0 ? "border-t border-gray-100" : ""}`}>
          <div className="flex items-center gap-2 mb-3">
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-700 border border-amber-200">
              <Clock className="w-3 h-3" />
              Mañana
            </span>
          </div>
          <div className="space-y-2">
            {eventosManana.map((evento) => {
              const tipoCfg = TIPO_EVENTO_LABEL[evento.tipoEvento] ?? TIPO_EVENTO_LABEL.tarea;
              return (
                <div
                  key={evento.id}
                  className="flex items-center gap-4 rounded-lg border border-gray-100 bg-gray-50/50
                             px-4 py-3 transition-all duration-150 hover:shadow-sm hover:bg-gray-50"
                >
                  {/* Hora */}
                  <div className="flex-shrink-0 text-center min-w-[52px]">
                    <span className="text-sm font-bold text-gray-900">
                      {formatearHora(evento.fechaInicio)}
                    </span>
                  </div>

                  {/* Separador */}
                  <div className="w-px h-8 bg-gray-200 flex-shrink-0" />

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-gray-900 truncate" title={evento.titulo}>
                      {evento.titulo}
                    </p>
                    {evento.expediente && (
                      <p className="text-xs text-gray-500 truncate mt-0.5">
                        Caso {evento.expediente.numeroCaso} — {evento.expediente.titulo}
                      </p>
                    )}
                  </div>

                  {/* Badge tipo */}
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium flex-shrink-0 ${tipoCfg.className}`}>
                    {tipoCfg.label}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

/* ══════════════════════════════════════════════════════════════
   Componente Principal: AdminDashboard
   ══════════════════════════════════════════════════════════════ */

export default function AdminDashboard({ nombre, eventos }: AdminDashboardProps) {
  const [totalCasos, setTotalCasos] = useState<number | null>(null);
  const [totalClientes, setTotalClientes] = useState<number | null>(null);

  /* Conteo de audiencias Hoy + Mañana (dato real) */
  const audienciasProximas = eventos.filter(
    (e) => esHoy(e.fechaInicio) || esManana(e.fechaInicio)
  ).length;

  useEffect(() => {
    async function cargarMetricas() {
      // Cargamos ambas en paralelo para mayor velocidad
      const [casos, clientes] = await Promise.all([
        obtenerTotalExpedientes(),
        obtenerTotalClientes()
      ]);
      setTotalCasos(casos);
      setTotalClientes(clientes);
    }
    cargarMetricas();
  }, []);

  const metrics = [
    { label: "Expedientes", value: totalCasos, icon: Briefcase, href: "/dashboard/casos", detail: "Tu gestión de casos, centralizada" },
    { label: "Clientes registrados", value: totalClientes, icon: Users, href: "/dashboard/clientes", detail: "Cada relación, en un solo lugar" },
    { label: "Eventos próximos", value: audienciasProximas, icon: Calendar, href: "/dashboard/agenda", detail: "Programados para hoy y mañana" },
  ];
  const shortcuts = [
    { label: "Tu equipo", detail: "Personas que impulsan tu práctica", href: "/dashboard/equipo", icon: UsersRound },
    { label: "Reportes de gestión", detail: "Información para tomar decisiones", href: "/dashboard/reportes", icon: ChartNoAxesCombined },
    { label: "Plantillas legales", detail: "El punto de partida de tus documentos", href: "/dashboard/plantillas", icon: BookOpen },
  ];

  return (
    <div className={styles.overview}>
      <DashboardWelcome nombre={nombre} label="TU DESPACHO, CONECTADO" description="Una perspectiva clara de tus casos, tu equipo y lo que viene. Todo empieza aquí." />
      <section aria-label="Resumen de actividad" className={styles.metrics}>
        {metrics.map(({ label, value, icon: Icon, href, detail }) => (
          <Link href={href} key={label} className={styles.metric}>
            <div className={styles.metricTop}><span className={styles.metricIcon}><Icon size={19} strokeWidth={1.7} /></span><ArrowUpRight size={16} /></div>
            <span className={styles.metricLabel}>{label}</span>
            <strong className={styles.metricValue}>{value === null ? <span className="skeleton block h-10 w-16" aria-label="Cargando" /> : value}</strong>
            <span className={styles.metricDetail}>{detail}</span>
          </Link>
        ))}
      </section>
      <div className={styles.panels}>
        <section>
          <div className={styles.sectionHeader}><h2>En tu agenda</h2><Link href="/dashboard/agenda">Ver agenda <ArrowUpRight size={14} /></Link></div>
          <PanelProximosEventos eventos={eventos} />
        </section>
        <section>
          <div className={styles.sectionHeader}><h2>Tu espacio, a un clic</h2></div>
          <div className={styles.shortcuts}>{shortcuts.map(({ label, detail, href, icon: Icon }) => (
            <Link href={href} key={href} className={styles.shortcut}><span className={styles.shortcutIcon}><Icon size={18} strokeWidth={1.7} /></span><span><strong>{label}</strong><small>{detail}</small></span><ArrowUpRight size={15} /></Link>
          ))}</div>
        </section>
      </div>
    </div>
  );
}
