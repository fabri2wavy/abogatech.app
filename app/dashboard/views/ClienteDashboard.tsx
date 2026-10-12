"use client";

import Link from "next/link";
import { ArrowUpRight, BriefcaseBusiness, FileText, MessageSquareText } from "lucide-react";
import { DashboardWelcome } from "@/components/layout/DashboardWelcome";

export default function ClienteDashboard({ nombre }: { nombre: string }) {
  return (
    <div className="max-w-5xl mx-auto space-y-6">
      <DashboardWelcome nombre={nombre} label="TU PORTAL PERSONAL" description="Mantén cerca la información de tus procesos y consulta lo que tu equipo legal comparte contigo." href="/dashboard/casos" action="Consultar mis expedientes" />
      <section className="rounded-2xl border border-[var(--color-surface-border)] bg-white p-6 md:p-8">
        <div className="flex items-center gap-3 mb-6"><span className="p-3 bg-blue-50 text-blue-600 rounded-xl"><BriefcaseBusiness size={22} /></span><div><h2 className="text-lg font-bold">Tus procesos, más cerca</h2><p className="text-sm text-[var(--color-text-secondary)]">Un espacio para seguir el trabajo de tu equipo legal.</p></div></div>
        <div className="grid sm:grid-cols-2 gap-5 mb-6">
          <div className="p-5 rounded-xl bg-[var(--color-surface)]"><FileText size={20} className="text-blue-600 mb-3" /><h3 className="font-semibold text-sm">Documentos compartidos</h3><p className="text-sm text-[var(--color-text-secondary)] mt-2">Consulta los documentos que tu abogado habilite en cada expediente.</p></div>
          <div className="p-5 rounded-xl bg-[var(--color-surface)]"><MessageSquareText size={20} className="text-blue-600 mb-3" /><h3 className="font-semibold text-sm">Avances de tus casos</h3><p className="text-sm text-[var(--color-text-secondary)] mt-2">Revisa las actualizaciones que tu equipo comparta sobre tus procesos.</p></div>
        </div>
        <Link href="/dashboard/casos" className="inline-flex items-center gap-3 text-sm font-semibold text-blue-600 hover:text-blue-800">Ir a mis expedientes <ArrowUpRight size={16} /></Link>
      </section>
    </div>
  );
}
