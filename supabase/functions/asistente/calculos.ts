// Cálculos del asistente. Los totales se calculan aquí, en código, y se entregan al modelo ya
// hechos: el modelo nunca suma ni resta.
import type { FilaDeuda } from './tipos.ts';

export const aCentimos = (valor: number | string | null | undefined): number =>
  Math.round(Number(valor ?? 0) * 100);

export const formatearSoles = (centimos: number): string =>
  `S/ ${(centimos / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

/** Fecha de hoy en Lima, como YYYY-MM-DD. */
export function fechaLima(ahora: Date): string {
  // El formato en-CA ya entrega YYYY-MM-DD.
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Lima',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(ahora);
}

const ETIQUETA_TRIBUTO: Record<string, string> = {
  predial: 'Impuesto predial',
  arbitrios: 'Arbitrios municipales',
  coactivo: 'Cobranza coactiva',
  multa: 'Multas',
  otros: 'Otros',
};

export type ResumenDeuda = {
  saldo_total_pendiente: string;
  saldo_por_tributo: Record<string, string>;
  periodos_pendientes: number;
  periodos_vencidos: number;
  monto_vencido: string;
  hay_deuda_coactiva: boolean;
  proximos_vencimientos: {
    concepto: string;
    periodo: string | null;
    vencimiento: string;
    saldo: string;
    vencida: boolean;
  }[];
};

export const esPendiente = (d: FilaDeuda) => d.estado !== 'pagada' && aCentimos(d.saldo) > 0;

export function resumirDeudas(deudas: FilaDeuda[], hoy: string): ResumenDeuda {
  const pendientes = deudas.filter(esPendiente);
  const porTributo = new Map<string, number>();
  let total = 0;
  let vencido = 0;
  let vencidos = 0;
  for (const d of pendientes) {
    const c = aCentimos(d.saldo);
    total += c;
    porTributo.set(d.tipo, (porTributo.get(d.tipo) ?? 0) + c);
    if (d.vencimiento && d.vencimiento < hoy) {
      vencido += c;
      vencidos += 1;
    }
  }
  const saldoPorTributo: Record<string, string> = {};
  for (const [tipo, c] of porTributo) saldoPorTributo[ETIQUETA_TRIBUTO[tipo] ?? tipo] = formatearSoles(c);

  const proximos = pendientes
    .filter((d) => d.vencimiento)
    .sort((a, b) => (a.vencimiento as string).localeCompare(b.vencimiento as string))
    .slice(0, 5)
    .map((d) => ({
      concepto: d.concepto,
      periodo: d.periodo,
      vencimiento: d.vencimiento as string,
      saldo: formatearSoles(aCentimos(d.saldo)),
      vencida: (d.vencimiento as string) < hoy,
    }));

  return {
    saldo_total_pendiente: formatearSoles(total),
    saldo_por_tributo: saldoPorTributo,
    periodos_pendientes: pendientes.length,
    periodos_vencidos: vencidos,
    monto_vencido: formatearSoles(vencido),
    hay_deuda_coactiva: pendientes.some((d) => d.tipo === 'coactivo'),
    proximos_vencimientos: proximos,
  };
}
