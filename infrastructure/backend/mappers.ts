import type { Rows } from "@/domain/types/database";
import type { Cliente } from "@/domain/entities/Cliente";
import type { Expediente } from "@/domain/entities/Expediente";
import { fullName } from "./context";
export function mapClient(r: Rows["clients"]): Cliente {
  return {
    id: r.id,
    nombreCompleto:
      r.tipo === "empresa" ? r.nombre_empresa || fullName(r) : fullName(r),
    rol: "cliente",
    email: r.email ?? "",
    telefono: r.telefono ?? "",
    tipoCliente: r.tipo as Cliente["tipoCliente"],
    etapaComercial: r.etapa_comercial as Cliente["etapaComercial"],
    nombreEmpresa: r.nombre_empresa,
    nombresLegales: r.nombres ?? "",
    apellidoPaterno: r.apellido_paterno ?? "",
    apellidoMaterno: r.apellido_materno ?? "",
    ci: r.ci ?? "",
    expedido: r.expedido ?? "",
    nacionalidad: r.nacionalidad ?? "",
    fechaNacimiento: r.fecha_nacimiento ?? "",
    estadoCivil: r.estado_civil ?? "",
    profesion: r.profesion ?? "",
    direccion: r.direccion ?? "",
    referidoPor: r.referido_por ?? "",
    contactoReferidor: r.contacto_referidor ?? "",
    representanteLegal: r.representante_legal,
    telefonoLaboral: r.telefono_laboral ?? "",
    direccionOficina: r.direccion_oficina ?? "",
  };
}
export const clientFields = {
  nombres: "nombres",
  nombresLegales: "nombres",
  apellidoPaterno: "apellido_paterno",
  apellidoMaterno: "apellido_materno",
  email: "email",
  telefono: "telefono",
  ci: "ci",
  expedido: "expedido",
  nacionalidad: "nacionalidad",
  fechaNacimiento: "fecha_nacimiento",
  estadoCivil: "estado_civil",
  profesion: "profesion",
  direccion: "direccion",
  referidoPor: "referido_por",
  contactoReferidor: "contacto_referidor",
  etapaComercial: "etapa_comercial",
  tipoCliente: "tipo",
  nombreEmpresa: "nombre_empresa",
  representanteLegal: "representante_legal",
  telefonoLaboral: "telefono_laboral",
  direccionOficina: "direccion_oficina",
} as const;
export function mappedFields(
  input: object,
  mapping: Record<string, string>,
): Record<string, unknown> {
  const source = input as Record<string, unknown>;
  const result: Record<string, unknown> = {};
  for (const [from, to] of Object.entries(mapping))
    if (source[from] !== undefined)
      result[to] = source[from] === "" ? null : source[from];
  return result;
}
export const caseFields = {
  numeroCaso: "numero_caso",
  titulo: "titulo",
  clienteId: "client_id",
  materia: "materia",
  juzgado: "juzgado",
  parteContraria: "parte_contraria",
  informeDespacho: "informe_despacho",
  informeCliente: "informe_cliente",
  estado: "estado",
  rolCliente: "rol_cliente",
  tipoProceso: "tipo_proceso",
  nurej: "nurej",
  numeroFiscalia: "numero_fiscalia",
  numeroFelcc: "numero_felcc",
  juezActual: "juez_actual",
  secretarioActuario: "secretario_actuario",
  fiscalActual: "fiscal_actual",
  investigadorAsignado: "investigador_asignado",
  etapaProcesal: "etapa_procesal",
  cuantia: "cuantia",
} as const;
export function mapCase(r: Rows["cases"]): Expediente {
  return {
    id: r.id,
    numeroCaso: r.numero_caso,
    titulo: r.titulo,
    materia: r.materia ?? "",
    juzgado: r.juzgado ?? "",
    parteContraria: r.parte_contraria ?? "",
    informeDespacho: r.informe_despacho ?? "",
    informeCliente: r.informe_cliente ?? "",
    estado: r.estado as Expediente["estado"],
    clienteId: r.client_id,
    fechaCreacion: new Date(r.created_at),
    fechaActualizacion: new Date(r.updated_at),
    archivado: r.archivado,
    rolCliente: r.rol_cliente ?? "",
    tipoProceso: r.tipo_proceso ?? "",
    nurej: r.nurej ?? "",
    numeroFiscalia: r.numero_fiscalia ?? "",
    numeroFelcc: r.numero_felcc ?? "",
    juezActual: r.juez_actual ?? "",
    secretarioActuario: r.secretario_actuario ?? "",
    fiscalActual: r.fiscal_actual ?? "",
    investigadorAsignado: r.investigador_asignado ?? "",
    etapaProcesal: r.etapa_procesal ?? "",
    cuantia: r.cuantia == null ? "" : String(r.cuantia),
  };
}
