// Asistente y simulación de cuotas (pantallas 12 a 14 del prototipo).
// No hay IA: el asistente responde con textos fijos según reglas simples.
import { formatearFecha, formatearSoles, sumarDeudas, totalDeuda } from './formato';
import type { Deuda } from './types';

export const PREGUNTAS_SUGERIDAS = ['¿Puedo pagar en cuotas?', '¿Por qué tengo esta multa?'] as const;

// Tiempo de espera de ejemplo para Atención al vecino (pantallas 11 y 14).
export const MINUTOS_ESPERA_EJEMPLO = 12;

export type AccionAsistente = 'simular_cuotas';

export type RespuestaAsistente = {
  texto: string;
  accion?: AccionAsistente;
};

export function bienvenidaAsistente(nombre: string): string {
  return `Hola, ${nombre}. Soy el asistente de Almira. Puedo explicarte tus deudas y simular cuotas. Yo oriento: la decisión es de la municipalidad.`;
}

export const RESPUESTA_SIN_REGLA =
  'Por ahora solo respondo las preguntas sugeridas. Elige una o toca «Hablar con una persona».';

// Minúsculas y sin tildes, para comparar lo que escribe el vecino.
function normalizar(texto: string): string {
  return texto
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '');
}

function respuestaCuotas(pendientes: Deuda[]): RespuestaAsistente {
  if (pendientes.length === 0) {
    return { texto: 'No tienes deudas pendientes, así que no hay nada que fraccionar.' };
  }
  return {
    texto: 'Puedo simular cuotas con los beneficios vigentes. La decisión es de la municipalidad.',
    accion: 'simular_cuotas',
  };
}

function respuestaMulta(pendientes: Deuda[]): RespuestaAsistente {
  const multas = pendientes.filter((deuda) => deuda.tipo === 'multa');
  if (multas.length === 0) {
    return { texto: 'No tienes multas pendientes en esta municipalidad.' };
  }
  const detalle = multas
    .map(
      (multa) =>
        `${multa.concepto} de ${formatearSoles(totalDeuda(multa))} (${multa.periodo}), con vencimiento el ${formatearFecha(multa.vencimiento)}`,
    )
    .join('; ');
  const intro = multas.length === 1 ? 'Tienes una multa' : 'Tienes estas multas';
  return {
    texto: `${intro}: ${detalle}. Es una sanción que registró tu municipalidad. Si crees que es incorrecta, puedes reclamarla desde Reclamos. La decisión es de la municipalidad.`,
  };
}

// Reglas fijas: "cuota" o "fraccion" lleva a cuotas; "multa", a la multa.
// Cualquier otra cosa recibe un mensaje que orienta a las preguntas sugeridas.
export function responderAsistente(pregunta: string, deudas: Deuda[]): RespuestaAsistente {
  const texto = normalizar(pregunta);
  const pendientes = deudas.filter((deuda) => deuda.estado !== 'pagada');
  if (/cuota|fraccion/.test(texto)) return respuestaCuotas(pendientes);
  if (/multa/.test(texto)) return respuestaMulta(pendientes);
  return { texto: RESPUESTA_SIN_REGLA };
}

export type AlcanceSimulacion = 'mora' | 'toda';

// "Solo en mora" toma las deudas vencidas; "Toda mi deuda", todas las pendientes.
export function deudasASimular(deudas: Deuda[], alcance: AlcanceSimulacion): Deuda[] {
  return deudas.filter((deuda) =>
    alcance === 'mora' ? deuda.estado === 'vencida' : deuda.estado !== 'pagada',
  );
}

export const CUOTAS_MINIMAS = 2;
export const CUOTAS_MAXIMAS = 12;
export const CUOTAS_INICIALES = 6;

// Tasa ilustrativa del prototipo (1 % mensual). No es la tasa de ninguna
// municipalidad: el fraccionamiento real lo aprueba Rentas según su ordenanza.
export const TASA_ILUSTRATIVA_MENSUAL = 0.01;

export type Simulacion = {
  deuda: number;
  cuotas: number;
  cuotaMensual: number;
  interes: number;
  total: number;
};

const redondear = (monto: number) => Math.round(monto * 100) / 100;

// Cuota fija (sistema francés) sobre el saldo, con la tasa mensual indicada.
export function simularCuotas(
  deudas: Deuda[],
  cuotas: number,
  tasaMensual: number = TASA_ILUSTRATIVA_MENSUAL,
): Simulacion {
  const deuda = redondear(sumarDeudas(deudas));
  const cuotaExacta =
    tasaMensual === 0 ? deuda / cuotas : (deuda * tasaMensual) / (1 - (1 + tasaMensual) ** -cuotas);
  const total = redondear(cuotaExacta * cuotas);
  return {
    deuda,
    cuotas,
    cuotaMensual: redondear(cuotaExacta),
    interes: redondear(total - deuda),
    total,
  };
}
