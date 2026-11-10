import {
  deudaDeFila,
  deudas as deudasEjemplo,
  municipalidadDeFila,
  municipalidades as municipalidadesEjemplo,
  obraDeFila,
  obras as obrasEjemplo,
  pagoDeFila,
  pagos as pagosEjemplo,
  predioDeFila,
  predios as prediosEjemplo,
  reclamoDeFila,
  reclamos as reclamosEjemplo,
  recordatorioDeFila,
  recordatorios as recordatoriosEjemplo,
  vecinoDeFila,
  vecinos as vecinosEjemplo,
  type Deuda,
  type Municipalidad,
  type Obra,
  type Pago,
  type Predio,
  type Reclamo,
  type Recordatorio,
  type Vecino,
} from '@almira/shared';
import { supabase } from './supabase';

// Todo lo que la app muestra. Con Supabase viene de la base, y las políticas RLS ya dejan
// pasar solo las filas del vecino; sin Supabase, de los datos de ejemplo.
export type FuenteDatos = {
  municipalidades: Municipalidad[];
  vecinos: Vecino[];
  predios: Predio[];
  deudas: Deuda[];
  pagos: Pago[];
  recordatorios: Recordatorio[];
  reclamos: Reclamo[];
  obras: Obra[];
};

export const DATOS_EJEMPLO: FuenteDatos = {
  municipalidades: municipalidadesEjemplo,
  vecinos: vecinosEjemplo,
  predios: prediosEjemplo,
  deudas: deudasEjemplo,
  pagos: pagosEjemplo,
  recordatorios: recordatoriosEjemplo,
  reclamos: reclamosEjemplo,
  obras: obrasEjemplo,
};

export const DATOS_VACIOS: FuenteDatos = {
  municipalidades: [],
  vecinos: [],
  predios: [],
  deudas: [],
  pagos: [],
  recordatorios: [],
  reclamos: [],
  obras: [],
};

async function leer<T>(
  tabla: string,
  convertir: (fila: Record<string, unknown>) => T,
  orden?: { columna: string; ascendente: boolean },
): Promise<T[]> {
  let consulta = supabase.from(tabla).select('*');
  if (orden) consulta = consulta.order(orden.columna, { ascending: orden.ascendente });
  const { data, error } = await consulta;
  if (error) throw new Error(`No se pudo leer ${tabla}`);
  return (data ?? []).map((fila) => convertir(fila as Record<string, unknown>));
}

// Lee todo en paralelo. Si falla alguna tabla, lanza el error: la app muestra el aviso en
// vez de datos a medias. Nunca se registran datos personales.
export async function cargarDatosRemotos(): Promise<FuenteDatos> {
  const [municipalidades, vecinos, predios, deudas, pagos, recordatorios, reclamos, obras] =
    await Promise.all([
      leer('municipalidades', municipalidadDeFila, { columna: 'nombre', ascendente: true }),
      leer('vecinos', vecinoDeFila),
      leer('predios', predioDeFila),
      leer('deudas', deudaDeFila, { columna: 'vencimiento', ascendente: true }),
      leer('pagos', pagoDeFila),
      leer('recordatorios', recordatorioDeFila),
      leer('reclamos', reclamoDeFila, { columna: 'creado_en', ascendente: false }),
      leer('obras', obraDeFila),
    ]);
  return { municipalidades, vecinos, predios, deudas, pagos, recordatorios, reclamos, obras };
}
