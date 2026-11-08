// Reclamos con evidencia (pantallas 15 a 18 del prototipo).
// La clasificación y el área salen de reglas fijas, no de IA. Quien atiende y
// resuelve el reclamo es la municipalidad.
import { etiquetaPlazo, fechaLimitePlazo } from './formato';
import type { EstadoReclamo, Reclamo, TipoReclamo } from './types';

// Mismo orden que los chips de la pantalla 17.
export const TIPOS_RECLAMO: TipoReclamo[] = [
  'pistas_veredas',
  'alumbrado',
  'limpieza',
  'vehiculo_mal_estacionado',
  'deposito_vehicular',
  'cobro_indebido',
  'otro',
];

// Área responsable de cada categoría, la misma que usan los datos de ejemplo y el panel.
export const AREA_TIPO_RECLAMO: Record<TipoReclamo, string> = {
  pistas_veredas: 'Obras',
  alumbrado: 'Obras',
  limpieza: 'Limpieza',
  vehiculo_mal_estacionado: 'Fiscalización',
  deposito_vehicular: 'Depósito',
  cobro_indebido: 'Rentas',
  otro: 'Atención al vecino',
};

// Plazo de ejemplo en días hábiles. El prototipo solo muestra el de Pistas y
// veredas (10 días); se usa el mismo para todas las categorías.
export const PLAZO_DIAS_RECLAMO = 10;

// Palabras que delatan cada categoría (en minúsculas y sin tildes).
const PALABRAS_TIPO: [TipoReclamo, RegExp][] = [
  ['pistas_veredas', /bache|hueco|pista|vereda|asfalto|pavimento|sardinel/],
  ['alumbrado', /poste|luz|foco|alumbrado|luminaria|oscur/],
  ['limpieza', /basura|residuo|desmonte|desperdicio|sucio|limpieza|barr(en|ido)/],
  ['vehiculo_mal_estacionado', /estaciona|parquea|bloquea|rampa|cochera/],
  ['deposito_vehicular', /deposito|grua|remolc/],
  ['cobro_indebido', /cobr|pague|pagad|recibo|arbitrio|predial|deuda/],
];

function normalizar(texto: string): string {
  return texto
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '');
}

// Primera categoría cuyas palabras aparecen en la descripción; si ninguna, "otro".
export function clasificarReclamo(descripcion: string): TipoReclamo {
  const texto = normalizar(descripcion);
  return PALABRAS_TIPO.find(([, palabras]) => palabras.test(texto))?.[0] ?? 'otro';
}

// "R-01866" -> "R-01867": sigue al mayor código de la municipalidad.
export function siguienteCodigoReclamo(reclamos: Pick<Reclamo, 'codigo'>[]): string {
  const mayor = reclamos.reduce((maximo, { codigo }) => {
    const numero = Number(/^R-(\d+)$/.exec(codigo)?.[1] ?? 0);
    return Math.max(maximo, numero);
  }, 0);
  return `R-${String(mayor + 1).padStart(5, '0')}`;
}

// Título corto para un reclamo nuevo: la primera frase de la descripción, hasta 40 letras.
export function tituloReclamo(descripcion: string): string {
  const frase = descripcion.trim().split(/[.,;\n]/)[0]!.trim();
  let corte = frase;
  if (frase.length > 40) {
    // Palabras enteras mientras quepan en 40 letras.
    corte = '';
    for (const palabra of frase.split(/\s+/)) {
      const siguiente = corte ? `${corte} ${palabra}` : palabra;
      if (siguiente.length > 40) break;
      corte = siguiente;
    }
    corte = `${corte}…`;
  }
  return corte.charAt(0).toUpperCase() + corte.slice(1);
}

export type PlazoReclamo = {
  etiqueta: string;
  // Solo si se conoce el plazo en días hábiles.
  quedan: number | null;
  total: number | null;
};

// Plazo de un reclamo abierto: "Quedan 3 d" y cuántos días hábiles le quedan de
// cuántos. Si está resuelto o no tiene plazo, devuelve null.
export function plazoReclamo(
  reclamo: Pick<Reclamo, 'estado' | 'creadoEn' | 'plazoDias' | 'plazo'>,
  hoyIso: string,
): PlazoReclamo | null {
  if (reclamo.estado === 'resuelto') return null;
  if (reclamo.plazoDias) {
    const etiqueta = etiquetaPlazo(fechaLimitePlazo(reclamo.creadoEn, reclamo.plazoDias), hoyIso);
    const quedan = Number(/^Quedan (\d+) d$/.exec(etiqueta)?.[1] ?? 0);
    return { etiqueta, quedan, total: reclamo.plazoDias };
  }
  return reclamo.plazo ? { etiqueta: reclamo.plazo, quedan: null, total: null } : null;
}

export type EstadoPaso = 'hecho' | 'actual' | 'pendiente';

export type PasoSeguimiento = { titulo: string; estado: EstadoPaso };

const PASOS = ['Recibido', 'Clasificado', 'Derivado al área', 'En atención', 'Resuelto'] as const;

// Paso en curso según el estado del reclamo (pantalla 18).
const PASO_ACTUAL: Record<EstadoReclamo, number> = {
  derivado: 2,
  en_atencion: 3,
  resuelto: 4,
};

export function pasosSeguimiento(estado: EstadoReclamo): PasoSeguimiento[] {
  const actual = PASO_ACTUAL[estado];
  return PASOS.map((titulo, indice) => ({
    titulo,
    estado:
      indice < actual || estado === 'resuelto' ? 'hecho' : indice === actual ? 'actual' : 'pendiente',
  }));
}
