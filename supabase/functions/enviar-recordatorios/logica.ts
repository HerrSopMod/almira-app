// Reglas de los recordatorios por WhatsApp, sin Deno ni Supabase para poder probarlas con Meta
// simulada. Qué avisar y a quién lo calcula SQL (`recordatorios_candidatos`); aquí solo se valida
// de nuevo lo esencial, se arma el mensaje y se envía una vez por (contribuyente, tipo, periodo).
import { formatearSoles } from '../_shared/soles.ts';
import { enmascararTelefono, enviarPlantilla, type EnvLike, type FetchLike } from '../_shared/whatsapp.ts';

export type TipoRecordatorio = 'vencimiento' | 'pendiente' | 'pago_confirmado' | 'bienvenida';

/** Una fila de `recordatorios_candidatos`. No lleva DNI ni número de cuponera. */
export type Candidato = {
  vecino_id: string;
  municipalidad_id: string;
  municipalidad: string;
  nombre: string;
  numero: string;
  tipo: TipoRecordatorio;
  periodo: string;
  tipos: string[];
  monto: number | string;
  fecha: string | null;
  referencia: string | null;
  con_coactivo: boolean;
  saldo_pendiente: number | string;
  whatsapp_activo: boolean;
  optout_at: string | null;
  consentimiento_at: string | null;
};

export const PLANTILLAS = {
  vencimiento: 'almira_vencimiento',
  pendiente: 'almira_pendiente',
  /** Variante neutra para quien tiene deuda en cobranza coactiva: solo informa. */
  pendienteInformativa: 'almira_pendiente_info',
  pago_confirmado: 'almira_pago_confirmado',
  bienvenida: 'almira_bienvenida',
} as const;

export const HORA_INICIO = 9;
export const HORA_FIN = 20;
export const LIMITE_POR_EJECUCION = 300;
export const PAUSA_ENTRE_ENVIOS_MS = 150;
export const REINTENTOS = 3;
export const MAX_BIENVENIDAS_POR_DIA = 3;

/** Hora (0-23) en Lima. Lima no tiene horario de verano: siempre UTC-5. */
export const horaLima = (ahora: Date): number => (ahora.getUTCHours() + 19) % 24;

/** Los avisos solo salen de 9:00 a 20:00, hora de Lima. */
export const dentroDeHorario = (ahora: Date): boolean => {
  const h = horaLima(ahora);
  return h >= HORA_INICIO && h < HORA_FIN;
};

const aNumero = (v: number | string | null | undefined): number => Number(v ?? 0);

export type Elegibilidad = { ok: true } | { ok: false; motivo: string };

/** Vuelve a comprobar lo que SQL ya filtró, por si llega algo que no debería salir. */
export function elegible(c: Candidato, ahora: Date): Elegibilidad {
  if (!c.whatsapp_activo) return { ok: false, motivo: 'inactivo' };
  if (c.optout_at) return { ok: false, motivo: 'baja' };
  if (!c.consentimiento_at) return { ok: false, motivo: 'sin_consentimiento' };
  if (!/^\+[1-9]\d{7,14}$/.test(c.numero ?? '')) return { ok: false, motivo: 'numero_invalido' };
  if (c.tipo !== 'bienvenida' && !dentroDeHorario(ahora)) return { ok: false, motivo: 'fuera_de_horario' };
  if (c.tipo === 'vencimiento' || c.tipo === 'pendiente') {
    // Nunca se avisa de una deuda que no existe.
    if (aNumero(c.saldo_pendiente) <= 0) return { ok: false, motivo: 'saldo_cero' };
  }
  if (c.tipo === 'vencimiento' && (!c.fecha || aNumero(c.monto) <= 0)) return { ok: false, motivo: 'sin_deuda' };
  if (c.tipo === 'pago_confirmado' && (aNumero(c.monto) <= 0 || !c.referencia)) {
    return { ok: false, motivo: 'sin_pago' };
  }
  return { ok: true };
}

// --- Texto de las variables ---

const MESES = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/** "2026-11-15" -> "15 de noviembre". */
export function fechaCorta(iso: string): string {
  const [, mes, dia] = iso.split('-').map(Number);
  return mes && dia && MESES[mes - 1] ? `${dia} de ${MESES[mes - 1]}` : iso;
}

const NOMBRE_TRIBUTO: Record<string, string> = {
  predial: 'impuesto predial',
  arbitrios: 'arbitrios municipales',
  multa: 'multa',
  coactivo: 'cobranza coactiva',
  otros: 'obligación',
};

export function nombreDeTributos(tipos: string[]): string {
  const nombres = [...new Set(tipos.map((t) => NOMBRE_TRIBUTO[t] ?? 'obligación'))];
  if (nombres.length <= 1) return nombres[0] ?? 'obligación';
  return `${nombres.slice(0, -1).join(', ')} y ${nombres[nombres.length - 1]}`;
}

/** "Municipalidad Distrital de Lince" / "Municipalidad de Lince" -> "Lince". */
export const municipalidadCorta = (nombre: string): string =>
  nombre.replace(/^municipalidad\s+(?:distrital\s+|provincial\s+|metropolitana\s+)?de\s+/i, '').trim() || nombre;

/** El monto va sin "S/ ": la plantilla ya lo trae. */
export const montoSinMoneda = (monto: number | string): string =>
  formatearSoles(aNumero(monto)).replace(/^S\/\s*/, '');

export type MensajePlantilla = { plantilla: string; variables: string[] };

type DatosMensaje = Pick<
  Candidato,
  'tipo' | 'nombre' | 'municipalidad' | 'tipos' | 'monto' | 'fecha' | 'referencia' | 'con_coactivo'
>;

/** Lo que se envía: solo nombre, municipalidad, tributo, monto, fechas y número de operación. */
export function construirMensaje(c: DatosMensaje): MensajePlantilla | null {
  const muni = municipalidadCorta(c.municipalidad);
  switch (c.tipo) {
    case 'vencimiento':
      return c.fecha
        ? {
            plantilla: PLANTILLAS.vencimiento,
            variables: [c.nombre, muni, nombreDeTributos(c.tipos), fechaCorta(c.fecha)],
          }
        : null;
    case 'pendiente':
      return c.con_coactivo
        ? { plantilla: PLANTILLAS.pendienteInformativa, variables: [c.nombre, muni] }
        : { plantilla: PLANTILLAS.pendiente, variables: [c.nombre, montoSinMoneda(c.monto), muni] };
    case 'pago_confirmado':
      return c.referencia
        ? { plantilla: PLANTILLAS.pago_confirmado, variables: [c.nombre, montoSinMoneda(c.monto), c.referencia] }
        : null;
    case 'bienvenida':
      return { plantilla: PLANTILLAS.bienvenida, variables: [c.nombre] };
  }
}

/**
 * Última barrera: ninguna variable puede parecer un DNI (8 dígitos) ni una cuponera (10 dígitos).
 * Los montos y el número de operación no llegan a tantos dígitos seguidos.
 */
export const variablesSeguras = (variables: string[]): boolean =>
  variables.every((v) => !/\d{8,}/.test(v.replace(/\s/g, '')));

// --- Registro y envío ---

export type RegistroNuevo = {
  municipalidad_id: string;
  vecino_id: string;
  tipo: TipoRecordatorio;
  periodo: string;
  plantilla: string;
};

export type Marca = {
  vecino_id: string;
  tipo: TipoRecordatorio;
  periodo: string;
  estado: 'enviado' | 'fallido';
  wa_message_id?: string | null;
  error_resumen?: string | null;
};

export interface AlmacenEnvio {
  /** Inserta el registro en cola. Devuelve false si ya existía (tipo y periodo ya enviados). */
  reclamar(r: RegistroNuevo): Promise<boolean>;
  marcar(m: Marca): Promise<void>;
}

export interface Almacen extends AlmacenEnvio {
  candidatos(ahora: Date): Promise<Candidato[]>;
}

export type DependenciasEnvio = {
  almacen: AlmacenEnvio;
  fetchMeta: FetchLike;
  env: EnvLike;
  pausa: (ms: number) => Promise<void>;
  log: (...partes: unknown[]) => void;
};

export type ResultadoUnico = { estado: 'enviado' | 'fallido' | 'duplicado' | 'omitido'; motivo?: string };

/** Envía un aviso: lo reclama (idempotencia), lo manda con reintentos y deja el resultado. */
export async function enviarUno(c: Candidato, ahora: Date, dep: DependenciasEnvio): Promise<ResultadoUnico> {
  const apto = elegible(c, ahora);
  if (!apto.ok) return { estado: 'omitido', motivo: apto.motivo };
  const mensaje = construirMensaje(c);
  if (!mensaje) return { estado: 'omitido', motivo: 'sin_mensaje' };

  const registro: RegistroNuevo = {
    municipalidad_id: c.municipalidad_id,
    vecino_id: c.vecino_id,
    tipo: c.tipo,
    periodo: c.periodo,
    plantilla: mensaje.plantilla,
  };
  if (!(await dep.almacen.reclamar(registro))) return { estado: 'duplicado' };

  const marca = { vecino_id: c.vecino_id, tipo: c.tipo, periodo: c.periodo };
  if (!variablesSeguras(mensaje.variables)) {
    await dep.almacen.marcar({ ...marca, estado: 'fallido', error_resumen: 'dato_sensible' });
    return { estado: 'fallido', motivo: 'dato_sensible' };
  }

  const enviar = () => enviarPlantilla(dep.fetchMeta, dep.env, c.numero, mensaje.plantilla, mensaje.variables);
  let resultado = await enviar();
  for (let intento = 1; !resultado.ok && resultado.transitorio && intento < REINTENTOS; intento++) {
    await dep.pausa(500 * 2 ** (intento - 1));
    resultado = await enviar();
  }

  if (resultado.ok) {
    await dep.almacen.marcar({ ...marca, estado: 'enviado', wa_message_id: resultado.id });
    return { estado: 'enviado' };
  }
  // Solo el código de error y el teléfono enmascarado.
  dep.log(`Envío fallido (${c.tipo}) a ${enmascararTelefono(c.numero)}: ${resultado.codigo}`);
  await dep.almacen.marcar({ ...marca, estado: 'fallido', error_resumen: resultado.codigo });
  return { estado: 'fallido', motivo: resultado.codigo };
}

export type Resumen = {
  candidatos: number;
  enviados: number;
  fallidos: number;
  omitidos: number;
  duplicados: number;
  fuera_de_horario?: boolean;
};

/** Procesa los candidatos en lote, con una pausa corta entre envíos. */
export async function procesarCandidatos(
  candidatos: Candidato[],
  ahora: Date,
  dep: DependenciasEnvio,
): Promise<Resumen> {
  const resumen: Resumen = { candidatos: candidatos.length, enviados: 0, fallidos: 0, omitidos: 0, duplicados: 0 };
  if (!dentroDeHorario(ahora)) return { ...resumen, omitidos: candidatos.length, fuera_de_horario: true };

  for (const c of candidatos.slice(0, LIMITE_POR_EJECUCION)) {
    const r = await enviarUno(c, ahora, dep);
    if (r.estado === 'enviado') resumen.enviados++;
    else if (r.estado === 'fallido') resumen.fallidos++;
    else if (r.estado === 'duplicado') resumen.duplicados++;
    else resumen.omitidos++;
    if (r.estado === 'enviado' || r.estado === 'fallido') await dep.pausa(PAUSA_ENTRE_ENVIOS_MS);
  }
  return resumen;
}
