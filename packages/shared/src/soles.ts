// Sin imports: la Edge Function enviar-recordatorios (Deno) también importa este archivo.

export const conComas = (enteros: string) => enteros.replace(/\B(?=(\d{3})+(?!\d))/g, ',');

export type OpcionesSoles = {
  // Montos redondos del panel web: "S/ 1,120,400".
  sinDecimales?: boolean;
  // Montos en miles del panel web: "S/ 312 mil".
  enMiles?: boolean;
};

// Sin Intl: Hermes no trae todos los locales en todas las plataformas.
export function formatearSoles(monto: number, opciones: OpcionesSoles = {}): string {
  const signo = monto < 0 ? '-' : '';
  if (opciones.enMiles) {
    return `${signo}S/ ${conComas(Math.round(Math.abs(monto) / 1000).toString())} mil`;
  }
  if (opciones.sinDecimales) {
    return `${signo}S/ ${conComas(Math.round(Math.abs(monto)).toString())}`;
  }
  const [enteros = '0', decimales = '00'] = Math.abs(monto).toFixed(2).split('.');
  return `${signo}S/ ${conComas(enteros)}.${decimales}`;
}
