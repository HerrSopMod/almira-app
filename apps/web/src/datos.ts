import {
  deudas,
  obras,
  pagos,
  predios,
  reclamos,
  recordatorios,
  vecinos,
} from '@almira/shared';
import { useOutletContext } from 'react-router-dom';

export type ContextoPanel = { municipalidadId: string; municipalidadNombre: string };

export const useContextoPanel = () => useOutletContext<ContextoPanel>();

// El personal solo ve su municipalidad; en Supabase lo garantiza RLS.
export function datosDeMunicipalidad(municipalidadId: string) {
  const propios = <T extends { municipalidadId: string }>(filas: T[]) =>
    filas.filter((fila) => fila.municipalidadId === municipalidadId);
  return {
    vecinos: propios(vecinos),
    predios: propios(predios),
    deudas: propios(deudas),
    pagos: propios(pagos),
    recordatorios: propios(recordatorios),
    reclamos: propios(reclamos),
    obras: propios(obras),
  };
}
