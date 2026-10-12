import { browserContext } from "../backend/browser";
import {
  list,
  insert,
  update,
  remove,
  profiles,
  membershipForUser,
} from "../backend/data";
import type {
  EventoAgenda,
  EventoAgendaDetallado,
  TipoEventoAgenda,
} from "@/domain/entities/EventoAgenda";
import type { Rows } from "@/domain/types/database";
type CrearEventoPayload = Omit<EventoAgenda, "id" | "creadoEn" | "creadoPor">;
export interface FiltrosAgenda {
  abogadoId?: string;
  fechaInicio?: string;
  fechaFin?: string;
  tipo?: TipoEventoAgenda;
}
function map(r: Rows["agenda_events"], userId = ""): EventoAgenda {
  return {
    id: r.id,
    titulo: r.titulo,
    descripcion: r.descripcion,
    tipoEvento: r.tipo as EventoAgenda["tipoEvento"],
    estado: r.estado as EventoAgenda["estado"],
    fechaInicio: r.fecha_inicio,
    fechaFin: r.fecha_fin,
    expedienteId: r.case_id,
    asignadoA: userId,
    creadoPor: r.creado_por ?? "",
    creadoEn: r.created_at,
  };
}
export async function obtenerEventos(
  filtros?: FiltrosAgenda,
): Promise<EventoAgendaDetallado[]> {
  const { db, ctx } = await browserContext();
  const [events, members, cases] = await Promise.all([
    list(db, ctx, "agenda_events"),
    list(db, ctx, "firm_memberships"),
    list(db, ctx, "cases"),
  ]);
  const p = await profiles(
    db,
    members.map((m) => m.user_id),
  );
  return events
    .map((r) => {
      const m = members.find((m) => m.id === r.assigned_membership_id);
      const person = p.get(m?.user_id ?? "");
      const c = cases.find((c) => c.id === r.case_id);
      return {
        ...map(r, m?.user_id),
        expediente: c ? { numeroCaso: c.numero_caso, titulo: c.titulo } : null,
        asignado: {
          nombres: person?.nombres ?? "",
          apellidoPaterno: person?.apellido_paterno ?? "",
          apellidoMaterno: person?.apellido_materno ?? "",
        },
      };
    })
    .filter(
      (r) =>
        (!filtros?.abogadoId || r.asignadoA === filtros.abogadoId) &&
        (!filtros?.tipo || r.tipoEvento === filtros.tipo) &&
        (!filtros?.fechaInicio ||
          Date.parse(r.fechaInicio) >= Date.parse(filtros.fechaInicio)) &&
        (!filtros?.fechaFin ||
          Date.parse(r.fechaInicio) <= Date.parse(filtros.fechaFin)),
    )
    .sort((a, b) => Date.parse(a.fechaInicio) - Date.parse(b.fechaInicio));
}
export async function crearEvento(
  p: CrearEventoPayload,
): Promise<EventoAgenda> {
  const { db, ctx } = await browserContext();
  const m = p.asignadoA ? await membershipForUser(db, ctx, p.asignadoA) : null;
  return map(
    await insert(db, ctx, "agenda_events", {
      titulo: p.titulo,
      descripcion: p.descripcion,
      tipo: p.tipoEvento,
      estado: p.estado,
      fecha_inicio: p.fechaInicio,
      fecha_fin: p.fechaFin,
      case_id: p.expedienteId || null,
      assigned_membership_id: m?.id ?? null,
      creado_por: ctx.userId,
    }),
    p.asignadoA,
  );
}
export async function actualizarEvento(
  id: string,
  p: Partial<CrearEventoPayload>,
): Promise<void> {
  const { db, ctx } = await browserContext();
  const fields: Partial<Rows["agenda_events"]> = {};
  if (p.titulo !== undefined) fields.titulo = p.titulo;
  if (p.descripcion !== undefined) fields.descripcion = p.descripcion;
  if (p.tipoEvento !== undefined) fields.tipo = p.tipoEvento;
  if (p.estado !== undefined) fields.estado = p.estado;
  if (p.fechaInicio !== undefined) fields.fecha_inicio = p.fechaInicio;
  if (p.fechaFin !== undefined) fields.fecha_fin = p.fechaFin;
  if (p.expedienteId !== undefined) fields.case_id = p.expedienteId || null;
  if (p.asignadoA !== undefined)
    fields.assigned_membership_id = p.asignadoA
      ? (await membershipForUser(db, ctx, p.asignadoA)).id
      : null;
  await update(db, ctx, "agenda_events", id, fields);
}
export async function eliminarEvento(id: string): Promise<void> {
  const { db, ctx } = await browserContext();
  await remove(db, ctx, "agenda_events", id);
}
