import type {
  CanalAviso,
  Deuda,
  EstadoDeuda,
  EstadoObra,
  EstadoPago,
  EstadoReclamo,
  EstadoRecordatorio,
  MedioPago,
  Municipalidad,
  TipoReclamo,
  TipoRecordatorio,
} from './types';

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
] as const;

// Sin Intl: Hermes no trae todos los locales en todas las plataformas.
export function formatearSoles(monto: number): string {
  const [enteros = '0', decimales = '00'] = Math.abs(monto).toFixed(2).split('.');
  const conMiles = enteros.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return `${monto < 0 ? '-' : ''}S/ ${conMiles}.${decimales}`;
}

export function formatearFecha(fechaIso: string): string {
  const [anio, mes, dia] = fechaIso.slice(0, 10).split('-');
  return `${Number(dia)} de ${MESES[Number(mes) - 1]} de ${anio}`;
}

// "28 oct 2026", como en el prototipo.
export function formatearFechaCorta(fechaIso: string): string {
  const [anio, mes, dia] = fechaIso.slice(0, 10).split('-');
  const nombreMes = MESES[Number(mes) - 1] ?? '';
  return `${Number(dia)} ${nombreMes.slice(0, 3)} ${anio}`;
}

// "2026-11-01T09:41:00" -> "9:41 h". Lee la hora escrita en la fecha, sin convertir zonas.
export function formatearHora(fechaIso: string): string {
  const [hora = '0', minutos = '00'] = fechaIso.slice(11, 16).split(':');
  return `${Number(hora)}:${minutos} h`;
}

// "Vence 30 nov 2026" o, si la fecha ya pasó, "Venció 15 oct 2026".
export function textoVencimiento(vencimientoIso: string, hoyIso: string): string {
  const fecha = formatearFechaCorta(vencimientoIso);
  return vencimientoIso.slice(0, 10) < hoyIso.slice(0, 10) ? `Venció ${fecha}` : `Vence ${fecha}`;
}

// Fechas ISO sin hora: se trabaja en UTC para no depender de la zona del teléfono.
function aDia(fechaIso: string): number {
  const [anio, mes, dia] = fechaIso.slice(0, 10).split('-').map(Number);
  return Date.UTC(anio!, mes! - 1, dia!);
}

const UN_DIA = 24 * 60 * 60 * 1000;

function esHabil(dia: number): boolean {
  const semana = new Date(dia).getUTCDay();
  return semana !== 0 && semana !== 6;
}

// Último día del plazo de un reclamo, en días hábiles (lunes a viernes, sin
// feriados). El día de creación cuenta como el primero si es hábil.
export function fechaLimitePlazo(creadoEnIso: string, plazoDias: number): string {
  let dia = aDia(creadoEnIso);
  let contados = esHabil(dia) ? 1 : 0;
  while (contados < plazoDias) {
    dia += UN_DIA;
    if (esHabil(dia)) contados += 1;
  }
  return new Date(dia).toISOString().slice(0, 10);
}

// "Quedan 3 d" (días hábiles después de hoy), "Vence hoy" o "Vencido".
export function etiquetaPlazo(fechaLimiteIso: string, hoyIso: string): string {
  const limite = aDia(fechaLimiteIso);
  const hoy = aDia(hoyIso);
  if (hoy > limite) return 'Vencido';
  if (hoy === limite) return 'Vence hoy';
  let quedan = 0;
  for (let dia = hoy + UN_DIA; dia <= limite; dia += UN_DIA) {
    if (esHabil(dia)) quedan += 1;
  }
  return `Quedan ${quedan} d`;
}

// "Municipalidad de Lince" -> "Lince". Si el nombre no sigue ese formato, se usa entero.
export function nombreDistrito(municipalidad: Pick<Municipalidad, 'nombre'>): string {
  return municipalidad.nombre.replace(/^Municipalidad(\s+(Distrital|Provincial))?\s+de\s+/i, '');
}

export function totalDeuda(deuda: Deuda): number {
  return deuda.montoInsoluto + deuda.interesMoratorio;
}

export function sumarDeudas(deudas: Deuda[]): number {
  return deudas.reduce((suma, deuda) => suma + totalDeuda(deuda), 0);
}

export function deudasPendientes(deudas: Deuda[]): Deuda[] {
  return deudas.filter((deuda) => deuda.estado !== 'pagada');
}

export const ETIQUETA_ESTADO_DEUDA: Record<EstadoDeuda, string> = {
  vigente: 'Por vencer',
  vencida: 'En mora',
  pagada: 'Pagada',
};

export const ETIQUETA_ESTADO_RECLAMO: Record<EstadoReclamo, string> = {
  en_atencion: 'En atención',
  derivado: 'Derivado',
  resuelto: 'Resuelto',
};

export const ETIQUETA_ESTADO_OBRA: Record<EstadoObra, string> = {
  en_ejecucion: 'En ejecución',
  finalizada: 'Concluida',
};

export const ETIQUETA_ESTADO_PAGO: Record<EstadoPago, string> = {
  pendiente: 'Pendiente',
  confirmado: 'Confirmado',
  rechazado: 'Rechazado',
};

export const ETIQUETA_ESTADO_RECORDATORIO: Record<EstadoRecordatorio, string> = {
  programado: 'Programado',
  enviado: 'Enviado',
  entregado: 'Entregado',
  fallido: 'Fallido',
};

export const ETIQUETA_CANAL: Record<CanalAviso, string> = {
  whatsapp: 'WhatsApp',
  sms: 'SMS',
  app: 'Notificación en la app',
};

export const ETIQUETA_MEDIO_PAGO: Record<MedioPago, string> = {
  yape: 'Yape',
  plin: 'Plin',
  tarjeta: 'Tarjeta de débito o crédito',
  banca_movil: 'Banca móvil o agente',
};

export const DETALLE_MEDIO_PAGO: Record<MedioPago, string> = {
  yape: 'Confirma desde tu app',
  plin: 'Confirma desde tu app',
  tarjeta: 'Visa, Mastercard',
  banca_movil: 'Con código de pago',
};

export const ETIQUETA_TIPO_RECORDATORIO: Record<TipoRecordatorio, string> = {
  preventivo: 'Recordatorio amable',
  mora: 'Aviso de mora',
  previo_coactiva: 'Aviso previo a cobranza coactiva',
};

export const ETIQUETA_TIPO_RECLAMO: Record<TipoReclamo, string> = {
  pistas_veredas: 'Pistas y veredas',
  alumbrado: 'Alumbrado público',
  limpieza: 'Limpieza pública',
  vehiculo_mal_estacionado: 'Vehículo mal estacionado',
  deposito_vehicular: 'Depósito vehicular',
  cobro_indebido: 'Cobro indebido',
  otro: 'Otro',
};
