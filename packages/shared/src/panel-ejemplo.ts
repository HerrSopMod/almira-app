// Cifras agregadas del panel municipal (docs/design/prototipo/web). Son de
// ejemplo, iguales a las del prototipo, y no se calculan con los datos de
// vecinos de datos-ejemplo.ts: el panel solo muestra agregados.

// Usuario de ejemplo del ingreso simulado (web-01). No hay autenticación real.
export const PERSONAL_PANEL_EJEMPLO = {
  usuario: 'responsable.rentas',
  cargo: 'Responsable municipal',
  area: 'Rentas',
  // Iniciales del avatar: el cargo y el área ("Responsable" de "Rentas").
  iniciales: 'RR',
} as const;

export interface MesRecaudacion {
  mes: string;
  millones: number;
  // Mes con vencimiento del impuesto predial: va en el color primario.
  vencimientoPredial: boolean;
}

export interface Cantidad {
  nombre: string;
  cantidad: number;
}

export interface VariantePrueba {
  letra: string;
  nombre: string;
  pagoPct: number;
}

export type OrigenCaso = 'Asistente' | 'SMS' | 'WhatsApp';
export type EstadoCaso = 'en_cola' | 'en_atencion' | 'atendido';

// Caso de atención humana (web-07). No lleva datos personales del vecino.
export interface CasoAtencion {
  codigo: string;
  motivo: string;
  origen: OrigenCaso;
  area: string;
  esperaMinutos: number | null;
  estado: EstadoCaso;
}

export interface PagoTributo {
  tributo: string;
  lineaBasePct: number;
  actualPct: number;
  metaPct: number;
}

export interface PasoEscalera {
  numero: 1 | 2 | 3;
  nombre: string;
  enviados: number;
  entregadosPct: number;
  pagaronPct: number;
}

export interface Control {
  etiqueta: string;
  porcentaje: number;
  detalle: string;
}

export interface PasoTexto {
  titulo: string;
  texto: string;
  // Paso donde la alerta supera el umbral (web-08): va con borde rojo.
  alerta?: boolean;
}

export type UnidadUmbral = 'evento' | '%' | 'por semana';

// Umbral de disparo (web-08): la alerta salta cuando "hoy" llega al umbral.
export interface Umbral {
  evento: string;
  umbral: number;
  hoy: number;
  unidad: UnidadUmbral;
}

export interface Acceso {
  hora: string;
  rol: string;
  accion: string;
}

export type EstadoArco = 'en_plazo' | 'atendida';

export interface SolicitudArco {
  tipo: string;
  recibida: string;
  estado: EstadoArco;
}

export interface PanelEjemplo {
  periodo: string;
  revisionMensual: string;
  ciclo: string;
  // Días máximos sin actualizar una obra publicada (web-06).
  frecuenciaObrasDias: number;
  recaudacion: { mes: number; variacionLineaBase: number };
  pagosATiempo: { porcentaje: number; puntos: number; meta: number };
  reclamosEnPlazo: { porcentaje: number; puntos: number; meta: number };
  avisos: { total: number; entregadosPct: number; pagaronPct: number };
  recaudacionMensual: MesRecaudacion[];
  pagosApp: { cantidad: number; variacionPresencial: number };
  // Montos en soles; el panel los muestra en miles.
  recaudacionPorZona: { zona: string; soles: number }[];
  pagosPorTributo: PagoTributo[];
  escalera: PasoEscalera[];
  // Días después del aviso en los que un pago cuenta como respuesta.
  diasRespuestaAviso: number;
  controlesAvisos: Control[];
  canales: Cantidad[];
  // Zona del distrito de cada reclamo de ejemplo, por código.
  zonaReclamo: Record<string, string>;
  reclamosPorArea: Cantidad[];
  reclamosFrecuentes: Cantidad[];
  aprendizaje: {
    avisosEntregados: number;
    pagosApp: number;
    consultasMapa: number;
    reclamosConEvidencia: number;
    aprende: string;
  };
  pruebaAB: { titulo: string; politica: string; nota: string; variantes: VariantePrueba[] };
  casos: CasoAtencion[];
  atencion: {
    umbralCola: number;
    // Minutos de espera desde los que el caso se marca en rojo (web-07).
    esperaLargaMinutos: number;
    derivadosPct: number;
    conversaciones: number;
    atencionesModulo: number;
    variacionModulo: number;
  };
  alertasActivas: string[];
  rutaIncidente: PasoTexto[];
  umbrales: Umbral[];
  auditoria: { nombre: string; porcentaje: number }[];
  registroAccesos: Acceso[];
  solicitudesArco: SolicitudArco[];
}

const LINCE: PanelEjemplo = {
  periodo: 'Octubre 2026',
  revisionMensual: '5 nov',
  ciclo: '4.ª cuota, vence 30 nov',
  frecuenciaObrasDias: 15,
  recaudacion: { mes: 1120400, variacionLineaBase: 7.7 },
  pagosATiempo: { porcentaje: 62, puntos: 9, meta: 70 },
  reclamosEnPlazo: { porcentaje: 84, puntos: 11, meta: 90 },
  avisos: { total: 18420, entregadosPct: 97, pagaronPct: 41 },
  recaudacionMensual: [
    { mes: 'May', millones: 1.42, vencimientoPredial: true },
    { mes: 'Jun', millones: 0.96, vencimientoPredial: false },
    { mes: 'Jul', millones: 1.01, vencimientoPredial: false },
    { mes: 'Ago', millones: 1.38, vencimientoPredial: true },
    { mes: 'Set', millones: 1.04, vencimientoPredial: false },
    { mes: 'Oct', millones: 1.12, vencimientoPredial: false },
  ],
  pagosApp: { cantidad: 6310, variacionPresencial: -18 },
  recaudacionPorZona: [
    { zona: 'Zona 1 · Risso', soles: 312000 },
    { zona: 'Zona 2 · Candamo', soles: 268000 },
    { zona: 'Zona 3 · Castilla', soles: 241000 },
    { zona: 'Zona 4 · Lobatón', soles: 176000 },
    { zona: 'Zona 5 · Conde', soles: 123000 },
  ],
  pagosPorTributo: [
    { tributo: 'Impuesto predial', lineaBasePct: 61, actualPct: 69, metaPct: 75 },
    { tributo: 'Arbitrios', lineaBasePct: 52, actualPct: 60, metaPct: 70 },
    { tributo: 'Multas', lineaBasePct: 38, actualPct: 49, metaPct: 55 },
  ],
  escalera: [
    { numero: 1, nombre: 'Recordatorio amable', enviados: 12480, entregadosPct: 97, pagaronPct: 41 },
    { numero: 2, nombre: 'Aviso de mora', enviados: 4360, entregadosPct: 95, pagaronPct: 27 },
    { numero: 3, nombre: 'Previo a coactiva', enviados: 1580, entregadosPct: 93, pagaronPct: 19 },
  ],
  diasRespuestaAviso: 7,
  controlesAvisos: [
    {
      etiqueta: 'Avisos a deudas ya pagadas (I3)',
      porcentaje: 0.2,
      detalle: 'Se verifica el pago antes de avisar',
    },
    { etiqueta: 'Vecinos sobre el tope (I4)', porcentaje: 0, detalle: 'Tope: 1 por día y 3 por semana' },
    {
      etiqueta: 'Envíos diferidos por saturación (I2)',
      porcentaje: 1.1,
      detalle: 'Ventana asignada: 24-26 nov',
    },
  ],
  canales: [
    { nombre: 'WhatsApp', cantidad: 11240 },
    { nombre: 'SMS', cantidad: 4820 },
    { nombre: 'Notificación app', cantidad: 2360 },
  ],
  zonaReclamo: {
    'R-01851': 'Zona 1',
    'R-01863': 'Zona 4',
    'R-01855': 'Zona 2',
    'R-01842': 'Zona 2',
    'R-01860': 'Zona 5',
    'R-01866': 'Zona 1',
    'R-01790': 'Zona 3',
  },
  reclamosPorArea: [
    { nombre: 'Obras', cantidad: 77 },
    { nombre: 'Limpieza', cantidad: 24 },
    { nombre: 'Fiscalización', cantidad: 18 },
    { nombre: 'Rentas', cantidad: 9 },
    { nombre: 'Depósito', cantidad: 6 },
  ],
  reclamosFrecuentes: [
    { nombre: 'Pistas y veredas', cantidad: 46 },
    { nombre: 'Alumbrado público', cantidad: 31 },
    { nombre: 'Limpieza pública', cantidad: 24 },
    { nombre: 'Vehículo mal estac.', cantidad: 18 },
    { nombre: 'Cobro indebido', cantidad: 9 },
  ],
  aprendizaje: {
    avisosEntregados: 18420,
    pagosApp: 6310,
    consultasMapa: 9740,
    reclamosConEvidencia: 128,
    aprende: 'Reforzar alumbrado en Zona 2',
  },
  pruebaAB: {
    titulo: 'Prueba A/B: recordatorio amable',
    politica: 'Política aprobada por el comité de datos e IA. Muestra: 6,000 vecinos.',
    nota: 'La variante B menciona la obra que financia el pago. Solo cambia el tono: nunca montos ni plazos.',
    variantes: [
      { letra: 'A', nombre: 'Formal', pagoPct: 35 },
      { letra: 'B', nombre: 'Con la obra', pagoPct: 41 },
    ],
  },
  casos: [
    {
      codigo: 'H-211',
      motivo: 'Fraccionamiento con deuda en dos predios',
      origen: 'Asistente',
      area: 'Rentas',
      esperaMinutos: 12,
      estado: 'en_cola',
    },
    {
      codigo: 'H-212',
      motivo: 'Vecino pide revisar multa ya reclamada',
      origen: 'Asistente',
      area: 'Fiscalización',
      esperaMinutos: 25,
      estado: 'en_cola',
    },
    {
      codigo: 'H-209',
      motivo: 'Adulta mayor sin smartphone: consulta de deuda',
      origen: 'SMS',
      area: 'Atención al vecino',
      esperaMinutos: 40,
      estado: 'en_cola',
    },
    {
      codigo: 'H-205',
      motivo: 'Duda sobre aviso previo a coactiva',
      origen: 'WhatsApp',
      area: 'Rentas',
      esperaMinutos: null,
      estado: 'atendido',
    },
  ],
  atencion: {
    umbralCola: 10,
    esperaLargaMinutos: 30,
    derivadosPct: 7.4,
    conversaciones: 3120,
    atencionesModulo: 412,
    variacionModulo: -18,
  },
  alertasActivas: [
    'el asistente ofreció un beneficio vencido en 3 respuestas. Supera el umbral y se escaló al comité de datos e IA sin esperar la revisión mensual.',
  ],
  rutaIncidente: [
    { titulo: 'Detección', texto: 'Muestreo: 3 respuestas erróneas' },
    { titulo: 'S3*', texto: 'Valida la gravedad' },
    { titulo: 'Canal algedónico', texto: 'Supera el umbral', alerta: true },
    { titulo: 'S5', texto: 'Comité y municipalidad' },
    { titulo: 'Corrección', texto: 'Actualizar la base de conocimiento' },
  ],
  umbrales: [
    { evento: 'Fuga de datos', umbral: 1, hoy: 0, unidad: 'evento' },
    { evento: 'Pagos erróneos', umbral: 0.5, hoy: 0.1, unidad: '%' },
    { evento: 'Respuestas graves del asistente', umbral: 2, hoy: 3, unidad: 'por semana' },
    { evento: 'Fallas masivas de envío', umbral: 5, hoy: 1.1, unidad: '%' },
  ],
  auditoria: [
    { nombre: 'Respuestas del asistente', porcentaje: 98.5 },
    { nombre: 'Clasificación', porcentaje: 96.2 },
    { nombre: 'Conciliación', porcentaje: 99.9 },
    { nombre: 'Mensajes A/B', porcentaje: 100 },
  ],
  registroAccesos: [
    { hora: '09:32', rol: 'Rentas', accion: 'Consultó el reclamo R-01851' },
    { hora: '09:18', rol: 'Obras', accion: 'Actualizó el avance de una obra' },
    { hora: '08:57', rol: 'Auditor S3*', accion: 'Revisó muestra de respuestas del asistente' },
    { hora: '08:40', rol: 'Atención', accion: 'Tomó el caso H-205' },
  ],
  solicitudesArco: [
    { tipo: 'Acceso', recibida: '2026-10-28', estado: 'en_plazo' },
    { tipo: 'Rectificación', recibida: '2026-10-24', estado: 'en_plazo' },
    { tipo: 'Oposición a WhatsApp', recibida: '2026-10-15', estado: 'atendida' },
  ],
};

// Cifras por municipalidad. El prototipo solo trae las de Lince.
const PANELES: Record<string, PanelEjemplo> = {
  'm-lince': LINCE,
};

export function panelEjemplo(municipalidadId: string): PanelEjemplo | undefined {
  return PANELES[municipalidadId];
}

// Variante con mejor pago y cuántos puntos supera a la siguiente.
export function mejorVariante(
  variantes: VariantePrueba[],
): { letra: string; puntos: number } | null {
  const [mejor, segunda] = [...variantes].sort((a, b) => b.pagoPct - a.pagoPct);
  if (!mejor || !segunda) return null;
  return { letra: mejor.letra, puntos: mejor.pagoPct - segunda.pagoPct };
}

export function superaUmbral(umbral: Umbral): boolean {
  return umbral.hoy >= umbral.umbral;
}
