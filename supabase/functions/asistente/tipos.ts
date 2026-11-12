// Tipos de la función `asistente`. Sin dependencias de Deno: se prueba con vitest.

export type Accion = 'ver_estado_cuenta' | 'pagar' | 'ver_historial' | 'descargar_cuponera';
export const ACCIONES_VALIDAS: readonly Accion[] = [
  'ver_estado_cuenta',
  'pagar',
  'ver_historial',
  'descargar_cuponera',
];

export type MensajeHistorial = { rol: 'usuario' | 'asistente'; texto: string };

export type FilaDeuda = {
  tipo: string;
  concepto: string;
  periodo: string | null;
  anio: number | null;
  trimestre: number | null;
  monto_insoluto: number | string;
  gastos_emision: number | string;
  interes_actualizacion: number | string;
  interes_moratorio: number | string;
  descuento: number | string;
  pagos_aplicados: number | string;
  saldo: number | string;
  estado: string;
  vencimiento: string | null;
  fecha_pago: string | null;
  nro_valor: string | null;
  exp_coactivo: string | null;
};

export type FilaPago = {
  monto: number | string;
  medio: string | null;
  referencia: string | null;
  creado_en: string | null;
};

export type DatosContribuyente = {
  nombre: string;
  codigoContribuyente: string | null;
  municipalidad: { nombre: string; telefonoAyuda: string | null };
  predios: { codigo: string; direccion: string }[];
  deudas: FilaDeuda[];
  pagos: FilaPago[];
};

export type Respuesta = {
  respuesta: string;
  acciones: Accion[];
  error?: 'limite' | 'servicio' | 'sin_vinculo';
};
