// Reflejan las tablas de supabase/migrations, en camelCase.

export const ZONAS = ['Lima Centro', 'Lima Sur', 'Lima Este', 'Lima Norte'] as const;
export type Zona = (typeof ZONAS)[number];

export type RolPersonal = 'administrador' | 'operador';
export type CanalAviso = 'whatsapp' | 'sms' | 'app';
export type TipoDeuda = 'predial' | 'arbitrios' | 'multa';
export type EstadoDeuda = 'vigente' | 'vencida' | 'pagada';
export type MedioPago = 'yape' | 'plin' | 'tarjeta' | 'banca_movil';
export type EstadoPago = 'pendiente' | 'confirmado' | 'rechazado';
export type TipoRecordatorio = 'preventivo' | 'mora' | 'previo_coactiva';
export type EstadoRecordatorio = 'programado' | 'enviado' | 'entregado' | 'fallido';
export type TipoReclamo =
  | 'pistas_veredas'
  | 'alumbrado'
  | 'limpieza'
  | 'vehiculo_mal_estacionado'
  | 'deposito_vehicular'
  | 'cobro_indebido'
  | 'otro';
export type EstadoReclamo = 'en_atencion' | 'derivado' | 'resuelto';
export type EstadoObra = 'en_ejecucion' | 'finalizada';

export interface Municipalidad {
  id: string;
  slug: string;
  nombre: string;
  zona: Zona;
  telefonoAyuda: string | null;
  avisoDestacado: string | null;
  activa: boolean;
}

export interface Personal {
  id: string;
  municipalidadId: string;
  userId: string;
  nombre: string;
  rol: RolPersonal;
}

export interface Vecino {
  id: string;
  municipalidadId: string;
  userId: string | null;
  dni: string;
  codigoContribuyente: string | null;
  nombre: string;
  telefono: string | null;
  canalPreferido: CanalAviso;
}

export interface Predio {
  id: string;
  municipalidadId: string;
  vecinoId: string;
  codigo: string;
  direccion: string;
}

export interface Deuda {
  id: string;
  municipalidadId: string;
  vecinoId: string;
  predioId: string | null;
  tipo: TipoDeuda;
  concepto: string;
  periodo: string;
  montoInsoluto: number;
  interesMoratorio: number;
  vencimiento: string;
  estado: EstadoDeuda;
}

export interface Pago {
  id: string;
  municipalidadId: string;
  vecinoId: string;
  deudaId: string;
  monto: number;
  medio: MedioPago;
  estado: EstadoPago;
  referencia: string | null;
  creadoEn: string;
}

export interface Recordatorio {
  id: string;
  municipalidadId: string;
  vecinoId: string;
  deudaId: string;
  codigo: string;
  tipo: TipoRecordatorio;
  canal: CanalAviso;
  estado: EstadoRecordatorio;
  programadoPara: string;
  entregadoEn: string | null;
}

export interface Reclamo {
  id: string;
  municipalidadId: string;
  vecinoId: string;
  codigo: string;
  tipo: TipoReclamo;
  titulo: string;
  descripcion: string | null;
  estado: EstadoReclamo;
  area: string | null;
  fotoRuta: string;
  direccion: string | null;
  latitud: number | null;
  longitud: number | null;
  plazo: string | null;
  plazoDias: number | null;
  creadoEn: string;
}

export interface Obra {
  id: string;
  municipalidadId: string;
  nombre: string;
  // Nombre para los mensajes de aviso: va después de "obras como el" (por ejemplo,
  // "parque Castilla"). Si es null, el mensaje no menciona la obra.
  nombreCorto: string | null;
  ubicacion: string;
  estado: EstadoObra;
  avancePct: number;
  meta: string;
  montoAsignado: number;
  montoEjecutado: number;
  fotos: number;
  publicada: boolean;
  inicio: string | null;
  actualizadaEn: string;
  // Parte del presupuesto que sale de tributos del distrito; el resto son transferencias.
  porcentajeTributos: number | null;
  hitos: string[];
  // Sin coordenadas, la obra sale en la lista pero no en el mapa.
  latitud: number | null;
  longitud: number | null;
}
