"use client";

import { useState } from "react";
import Image from "next/image";
import { ArrowUpRight, Globe, Mail } from "lucide-react";
import { AbogadoPerfil } from "@/infrastructure/data/abogadosMock";
import { Brand } from "@/components/ui/Brand";

export default function TarjetaVista({ perfil }: { perfil: AbogadoPerfil }) {
  const [photoFailed, setPhotoFailed] = useState(false);
  return (
    <main className="min-h-svh bg-[var(--color-surface)] px-4 py-8 sm:py-14 flex items-center justify-center">
      <article className="w-full max-w-md overflow-hidden rounded-3xl bg-white border border-[var(--color-surface-border)] shadow-[var(--shadow-lg)]">
        <header className="relative bg-[var(--color-navy)] px-7 pt-7 pb-24"><Brand light /><p className="mt-8 text-[10px] font-semibold tracking-[0.2em] text-[var(--color-brand-light)]">PERFIL PROFESIONAL</p></header>
        <div className="px-7 pb-8">
          <div className="relative -mt-16 h-28 w-28 rounded-2xl overflow-hidden border-4 border-white shadow-md bg-[var(--color-brand-dim)] flex items-center justify-center">
            {photoFailed ? <span className="text-3xl font-bold text-blue-700">{perfil.nombre.split(" ").map(part => part[0]).slice(0, 2).join("")}</span> : <Image src={perfil.fotoUrl} alt={perfil.nombre} fill sizes="112px" className="object-cover" onError={() => setPhotoFailed(true)} />}
          </div>
          <h1 className="mt-5 text-3xl font-bold tracking-tight">{perfil.nombre}</h1>
          <p className="mt-2 text-sm font-medium text-[var(--color-brand)]">{perfil.cargo}</p>
          <div className="mt-7 pt-6 border-t border-[var(--color-surface-border)]">
            <h2 className="text-xs font-semibold text-[var(--color-text-muted)] tracking-wider uppercase">Contacto profesional</h2>
            <a href={`mailto:${perfil.email}`} className="mt-4 flex items-center gap-3 text-sm text-[var(--color-text-secondary)] break-all hover:text-blue-600"><Mail size={17} className="shrink-0" />{perfil.email}</a>
            {perfil.linkedinPersonal && <a href={perfil.linkedinPersonal} target="_blank" rel="noopener noreferrer" className="mt-5 flex items-center gap-3 rounded-xl border border-[var(--color-surface-border)] p-4 text-sm font-medium hover:bg-blue-50"><Globe size={18} className="text-blue-600" />LinkedIn profesional<ArrowUpRight size={16} className="ml-auto" /></a>}
            <a href={`mailto:${perfil.email}`} className="mt-5 flex items-center justify-center gap-3 rounded-xl bg-[var(--color-brand)] px-5 py-4 text-sm font-semibold text-white hover:bg-[var(--color-brand-hover)] transition-colors">Contactar por correo<ArrowUpRight size={17} /></a>
          </div>
          <footer className="mt-8 text-center text-[10px] text-[var(--color-text-muted)]">Perfil compartido con <span className="font-semibold">ABOGATECH</span></footer>
        </div>
      </article>
    </main>
  );
}
