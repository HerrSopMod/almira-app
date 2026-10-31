// Reflejan las tablas de supabase/migrations, en camelCase.

export const ZONAS = ['Lima Centro', 'Lima Sur', 'Lima Este', 'Lima Norte'] as const;
export type Zona = (typeof ZONAS)[number];

export type RolPersonal = 'administrador' | 'operador';
export type CanalAviso = 'whatsapp' | 'sms' | 'app';
export type TipoDeuda = 'predial' | 'arbitrios';
export type EstadoDeuda = 'vigente' | 'vencida' | 'pagada';
export type MedioPago = 'billetera' | 'tarjeta' | 'pagoefectivo';
export type EstadoPago = 'pendiente' | 'confirmado' | 'rechazado';
export type TipoRecordatorio = 'preventivo' | 'mora' | 'previo_coactiva';
export type EstadoRecordatorio = 'programado' | 'enviado' | 'entregado' | 'fallido';
export type TipoReclamo = 'basura' | 'bache' | 'luminaria';
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
  latitud: number | null;
  longitud: number | null;
  plazo: string | null;
}

export interface Obra {
  id: string;
  municipalidadId: string;
  nombre: string;
  ubicacion: string;
  estado: EstadoObra;
  avancePct: number;
  meta: string;
  montoAsignado: number;
  montoEjecutado: number;
  fotos: number;
}
