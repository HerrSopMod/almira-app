// Cifras agregadas del panel municipal (docs/design/prototipo/web). Son de
// ejemplo, iguales a las del prototipo, y no se calculan con los datos de
// vecinos de datos-ejemplo.ts: el panel solo muestra agregados.

// Usuario de ejemplo del ingreso simulado (web-01). No hay autenticación real.
export const PERSONAL_PANEL_EJEMPLO = {
  usuario: 'responsable.rentas',
  cargo: 'Responsable municipal',
  area: 'Rentas',
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

export type OrigenCaso = 'Asistente IA' | 'SMS' | 'WhatsApp';
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
  reclamosPorArea: Cantidad[];
  reclamosFrecuentes: Cantidad[];
  aprendizaje: {
    avisosEntregados: number;
    pagosApp: number;
    consultasMapa: number;
    reclamosConEvidencia: number;
    aprende: string;
  };
  pruebaAB: { titulo: string; politica: string; variantes: VariantePrueba[] };
  casos: CasoAtencion[];
  alertasActivas: string[];
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
    variantes: [
      { letra: 'A', nombre: 'Formal', pagoPct: 35 },
      { letra: 'B', nombre: 'Con la obra', pagoPct: 41 },
    ],
  },
  casos: [
    {
      codigo: 'H-211',
      motivo: 'Fraccionamiento con deuda en dos predios',
      origen: 'Asistente IA',
      area: 'Rentas',
      esperaMinutos: 12,
      estado: 'en_cola',
    },
    {
      codigo: 'H-212',
      motivo: 'Vecino pide revisar multa ya reclamada',
      origen: 'Asistente IA',
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
  alertasActivas: [
    'el asistente ofreció un beneficio vencido en 3 respuestas. Supera el umbral y se escaló al comité de datos e IA sin esperar la revisión mensual.',
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
