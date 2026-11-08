import { deudasPendientes, sumarDeudas, totalDeuda } from './formato';
import type { Deuda } from './types';

// Deudas pendientes que el vecino marcó para pagar, en el orden de la lista.
// Las pagadas nunca cuentan, aunque su id siga marcado.
export function deudasSeleccionadas(deudas: Deuda[], idsMarcados: readonly string[]): Deuda[] {
  const marcados = new Set(idsMarcados);
  return deudasPendientes(deudas).filter((deuda) => marcados.has(deuda.id));
}

// "Total seleccionado" de Pagar: se recalcula al marcar o desmarcar.
export function totalSeleccionado(deudas: Deuda[], idsMarcados: readonly string[]): number {
  return sumarDeudas(deudasSeleccionadas(deudas, idsMarcados));
}

export type RepartoDeuda = {
  total: number;
  cantidad: number;
  enMora: number;
  porVencer: number;
  // Porcentajes enteros que suman 100 (o 0 si no hay deuda).
  porcentajeEnMora: number;
  porcentajePorVencer: number;
};

// Barra "En mora / Por vencer" del Destacado de Inicio.
export function repartoDeuda(deudas: Deuda[]): RepartoDeuda {
  const pendientes = deudasPendientes(deudas);
  const sumar = (estado: Deuda['estado']) =>
    pendientes
      .filter((deuda) => deuda.estado === estado)
      .reduce((suma, deuda) => suma + totalDeuda(deuda), 0);
  const enMora = sumar('vencida');
  const porVencer = sumar('vigente');
  const total = enMora + porVencer;
  const porcentajeEnMora = total > 0 ? Math.round((enMora / total) * 100) : 0;
  return {
    total,
    cantidad: pendientes.length,
    enMora,
    porVencer,
    porcentajeEnMora,
    porcentajePorVencer: total > 0 ? 100 - porcentajeEnMora : 0,
  };
}

// Vencimiento más cercano de las deudas pendientes desde hoy (incluido), o null
// si todas ya vencieron o no hay deudas.
export function proximoVencimiento(deudas: Deuda[], hoyIso: string): string | null {
  const hoy = hoyIso.slice(0, 10);
  const futuras = deudasPendientes(deudas)
    .map((deuda) => deuda.vencimiento.slice(0, 10))
    .filter((fecha) => fecha >= hoy)
    .sort();
  return futuras[0] ?? null;
}
