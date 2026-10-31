import type {
  CanalAviso,
  Deuda,
  EstadoDeuda,
  EstadoObra,
  EstadoPago,
  EstadoReclamo,
  EstadoRecordatorio,
  MedioPago,
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

export function formatearFechaCorta(fechaIso: string): string {
  const [anio, mes, dia] = fechaIso.slice(0, 10).split('-');
  const nombreMes = MESES[Number(mes) - 1] ?? '';
  return `${Number(dia)} ${nombreMes.charAt(0).toUpperCase()}${nombreMes.slice(1, 3)} ${anio}`;
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
  vigente: 'Vigente',
  vencida: 'Vencida',
  pagada: 'Pagada',
};

export const ETIQUETA_ESTADO_RECLAMO: Record<EstadoReclamo, string> = {
  en_atencion: 'En atención',
  derivado: 'Derivado',
  resuelto: 'Resuelto',
};

export const ETIQUETA_ESTADO_OBRA: Record<EstadoObra, string> = {
  en_ejecucion: 'En ejecución',
  finalizada: 'Finalizada',
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
  billetera: 'Billetera digital',
  tarjeta: 'Tarjeta de débito o crédito',
  pagoefectivo: 'PagoEfectivo / Banca por internet',
};

export const ETIQUETA_TIPO_RECORDATORIO: Record<TipoRecordatorio, string> = {
  preventivo: 'Aviso preventivo',
  mora: 'Aviso de mora',
  previo_coactiva: 'Aviso previo a cobranza coactiva',
};

export const ETIQUETA_TIPO_RECLAMO: Record<TipoReclamo, string> = {
  basura: 'Recojo de basura',
  bache: 'Bache en la pista',
  luminaria: 'Luminaria apagada',
};
