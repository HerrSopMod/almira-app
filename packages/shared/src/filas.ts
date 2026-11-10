import type {
  CanalAviso,
  Deuda,
  Municipalidad,
  Obra,
  Pago,
  Predio,
  Recordatorio,
  Reclamo,
  Vecino,
  Zona,
} from './types';

// Convierten las filas que devuelve Supabase (snake_case) a los tipos de la app (camelCase).
// Las columnas numeric pueden llegar como número o como texto, según el cliente.
export type Fila = Record<string, unknown>;

const texto = (fila: Fila, columna: string) => String(fila[columna] ?? '');
const textoONulo = (fila: Fila, columna: string) =>
  fila[columna] === null || fila[columna] === undefined ? null : String(fila[columna]);
const numero = (fila: Fila, columna: string) => Number(fila[columna] ?? 0);
const numeroONulo = (fila: Fila, columna: string) =>
  fila[columna] === null || fila[columna] === undefined ? null : Number(fila[columna]);

export const municipalidadDeFila = (f: Fila): Municipalidad => ({
  id: texto(f, 'id'),
  slug: texto(f, 'slug'),
  nombre: texto(f, 'nombre'),
  zona: texto(f, 'zona') as Zona,
  telefonoAyuda: textoONulo(f, 'telefono_ayuda'),
  avisoDestacado: textoONulo(f, 'aviso_destacado'),
  urlPago: textoONulo(f, 'url_pago'),
  activa: f.activa === true,
});

export const vecinoDeFila = (f: Fila): Vecino => ({
  id: texto(f, 'id'),
  municipalidadId: texto(f, 'municipalidad_id'),
  userId: textoONulo(f, 'user_id'),
  dni: texto(f, 'dni'),
  codigoContribuyente: textoONulo(f, 'codigo_contribuyente'),
  nombre: texto(f, 'nombre'),
  telefono: textoONulo(f, 'telefono'),
  canalPreferido: texto(f, 'canal_preferido') as CanalAviso,
});

export const predioDeFila = (f: Fila): Predio => ({
  id: texto(f, 'id'),
  municipalidadId: texto(f, 'municipalidad_id'),
  vecinoId: texto(f, 'vecino_id'),
  codigo: texto(f, 'codigo'),
  direccion: texto(f, 'direccion'),
});

export const deudaDeFila = (f: Fila): Deuda => ({
  id: texto(f, 'id'),
  municipalidadId: texto(f, 'municipalidad_id'),
  vecinoId: texto(f, 'vecino_id'),
  predioId: textoONulo(f, 'predio_id'),
  tipo: texto(f, 'tipo') as Deuda['tipo'],
  concepto: texto(f, 'concepto'),
  periodo: texto(f, 'periodo'),
  montoInsoluto: numero(f, 'monto_insoluto'),
  interesMoratorio: numero(f, 'interes_moratorio'),
  vencimiento: texto(f, 'vencimiento'),
  estado: texto(f, 'estado') as Deuda['estado'],
});

export const pagoDeFila = (f: Fila): Pago => ({
  id: texto(f, 'id'),
  municipalidadId: texto(f, 'municipalidad_id'),
  vecinoId: texto(f, 'vecino_id'),
  deudaId: texto(f, 'deuda_id'),
  monto: numero(f, 'monto'),
  medio: texto(f, 'medio') as Pago['medio'],
  estado: texto(f, 'estado') as Pago['estado'],
  referencia: textoONulo(f, 'referencia'),
  creadoEn: texto(f, 'creado_en'),
});

export const recordatorioDeFila = (f: Fila): Recordatorio => ({
  id: texto(f, 'id'),
  municipalidadId: texto(f, 'municipalidad_id'),
  vecinoId: texto(f, 'vecino_id'),
  deudaId: texto(f, 'deuda_id'),
  codigo: texto(f, 'codigo'),
  tipo: texto(f, 'tipo') as Recordatorio['tipo'],
  canal: texto(f, 'canal') as CanalAviso,
  estado: texto(f, 'estado') as Recordatorio['estado'],
  programadoPara: texto(f, 'programado_para'),
  entregadoEn: textoONulo(f, 'entregado_en'),
});

export const reclamoDeFila = (f: Fila): Reclamo => ({
  id: texto(f, 'id'),
  municipalidadId: texto(f, 'municipalidad_id'),
  vecinoId: texto(f, 'vecino_id'),
  codigo: texto(f, 'codigo'),
  tipo: texto(f, 'tipo') as Reclamo['tipo'],
  titulo: texto(f, 'titulo'),
  descripcion: textoONulo(f, 'descripcion'),
  estado: texto(f, 'estado') as Reclamo['estado'],
  area: textoONulo(f, 'area'),
  fotoRuta: texto(f, 'foto_ruta'),
  direccion: textoONulo(f, 'direccion'),
  latitud: numeroONulo(f, 'latitud'),
  longitud: numeroONulo(f, 'longitud'),
  plazo: textoONulo(f, 'plazo'),
  plazoDias: numeroONulo(f, 'plazo_dias'),
  creadoEn: texto(f, 'creado_en'),
});

export const obraDeFila = (f: Fila): Obra => ({
  id: texto(f, 'id'),
  municipalidadId: texto(f, 'municipalidad_id'),
  nombre: texto(f, 'nombre'),
  nombreCorto: textoONulo(f, 'nombre_corto'),
  ubicacion: texto(f, 'ubicacion'),
  estado: texto(f, 'estado') as Obra['estado'],
  avancePct: numero(f, 'avance_pct'),
  meta: texto(f, 'meta'),
  montoAsignado: numero(f, 'monto_asignado'),
  montoEjecutado: numero(f, 'monto_ejecutado'),
  fotos: numero(f, 'fotos'),
  publicada: f.publicada === true,
  inicio: textoONulo(f, 'inicio'),
  actualizadaEn: texto(f, 'actualizada_en'),
  porcentajeTributos: numeroONulo(f, 'porcentaje_tributos'),
  hitos: Array.isArray(f.hitos) ? f.hitos.map(String) : [],
  latitud: numeroONulo(f, 'latitud'),
  longitud: numeroONulo(f, 'longitud'),
});
