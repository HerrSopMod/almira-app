// Escalera de avisos y textos de los mensajes (pantallas 09 a 11 del prototipo).
import { formatearDiaMes, formatearSoles, totalDeuda } from './formato';
import type { Deuda, Obra, Recordatorio, TipoDeuda, TipoRecordatorio } from './types';

// De menor a mayor presión.
export const TIPOS_RECORDATORIO: TipoRecordatorio[] = ['preventivo', 'mora', 'previo_coactiva'];

export const NIVEL_TIPO_RECORDATORIO: Record<TipoRecordatorio, number> = {
  preventivo: 1,
  mora: 2,
  previo_coactiva: 3,
};

export const DETALLE_TIPO_RECORDATORIO: Record<TipoRecordatorio, string> = {
  preventivo: 'Antes de que venza',
  mora: 'Después del vencimiento',
  previo_coactiva: 'Lo ejecuta la municipalidad, no Almira',
};

// Cómo se nombra cada deuda dentro de una frase: "Tu arbitrio vence pronto",
// "tu multa podría pasar…", "tus arbitrios podrían pasar…".
const PALABRAS_DEUDA: Record<TipoDeuda, { titulo: string; corto: string; plural: boolean }> = {
  arbitrios: { titulo: 'arbitrio', corto: 'arbitrios', plural: true },
  multa: { titulo: 'multa', corto: 'multa', plural: false },
  predial: { titulo: 'impuesto predial', corto: 'impuesto predial', plural: false },
};

export function fechaAviso(recordatorio: Recordatorio): string {
  return recordatorio.entregadoEn ?? recordatorio.programadoPara;
}

// Los avisos que ya le llegaron al vecino, del más nuevo al más antiguo.
export function avisosRecibidos(recordatorios: Recordatorio[]): Recordatorio[] {
  return recordatorios
    .filter((aviso) => aviso.estado === 'enviado' || aviso.estado === 'entregado')
    .sort((a, b) => fechaAviso(b).localeCompare(fechaAviso(a)));
}

// Peldaño de la escalera donde está el vecino: el aviso más alto de una deuda
// que sigue pendiente. Si no hay ninguno, devuelve null.
export function tipoAvisoActual(
  recordatorios: Recordatorio[],
  deudas: Deuda[],
): TipoRecordatorio | null {
  const pendientes = new Set(
    deudas.filter((deuda) => deuda.estado !== 'pagada').map((deuda) => deuda.id),
  );
  let actual: TipoRecordatorio | null = null;
  for (const aviso of avisosRecibidos(recordatorios)) {
    if (!pendientes.has(aviso.deudaId)) continue;
    if (!actual || NIVEL_TIPO_RECORDATORIO[aviso.tipo] > NIVEL_TIPO_RECORDATORIO[actual]) {
      actual = aviso.tipo;
    }
  }
  return actual;
}

export function tituloAviso(tipo: TipoRecordatorio, deuda: Pick<Deuda, 'tipo'>): string {
  const nombre = PALABRAS_DEUDA[deuda.tipo].titulo;
  switch (tipo) {
    case 'preventivo':
      return `Tu ${nombre} vence pronto`;
    case 'mora':
      return `Tu ${nombre} está en mora`;
    case 'previo_coactiva':
      return `Tu ${nombre} podría pasar a cobranza coactiva`;
  }
}

// La obra que se menciona en los mensajes: una en ejecución con nombre corto,
// de preferencia la que se financia con tributos del distrito.
export function obraParaAvisos(obras: Obra[]): Obra | undefined {
  const candidatas = obras.filter(
    (obra) => obra.publicada && obra.estado === 'en_ejecucion' && obra.nombreCorto,
  );
  return candidatas.find((obra) => obra.porcentajeTributos !== null) ?? candidatas[0];
}

type DatosMensaje = {
  tipo: TipoRecordatorio;
  deuda: Pick<Deuda, 'tipo' | 'concepto' | 'montoInsoluto' | 'interesMoratorio' | 'vencimiento'>;
  nombre: string;
  obra?: Pick<Obra, 'nombreCorto'>;
  // El prototipo redacta distinto el final del recordatorio amable en el detalle
  // del aviso (pantalla 10) y en los ejemplos (pantalla 11).
  version?: 'detalle' | 'ejemplo';
};

function enMinuscula(texto: string): string {
  return texto.charAt(0).toLowerCase() + texto.slice(1);
}

export function mensajeAviso({
  tipo,
  deuda,
  nombre,
  obra,
  version = 'detalle',
}: DatosMensaje): string {
  const { corto, plural } = PALABRAS_DEUDA[deuda.tipo];
  const tu = plural ? 'tus' : 'tu';
  const concepto = enMinuscula(deuda.concepto);
  const monto = formatearSoles(totalDeuda(deuda));
  const fecha = formatearDiaMes(deuda.vencimiento);

  switch (tipo) {
    case 'preventivo': {
      const inicio = `Hola, ${nombre}. ${plural ? 'Tus' : 'Tu'} ${concepto} de ${monto} ${
        plural ? 'vencen' : 'vence'
      } el ${fecha}. Pagar a tiempo te evita intereses`;
      if (!obra?.nombreCorto) return `${inicio}.`;
      const aporte = `financia obras como el ${obra.nombreCorto}.`;
      return version === 'detalle'
        ? `${inicio}, y tu aporte ${aporte}`
        : `${inicio}. Tu aporte ${aporte}`;
    }
    case 'mora':
      return `${nombre}, ${tu} ${concepto} de ${monto} ${
        plural ? 'vencieron' : 'venció'
      } el ${fecha}. Puedes pagar en la app o simular cuotas. ¿Dudas? Responde a este mensaje.`;
    case 'previo_coactiva':
      return `${nombre}, ${tu} ${corto} ${
        plural ? 'podrían' : 'podría'
      } pasar a cobranza coactiva, a cargo de la municipalidad. Aún puedes pagar o pedir orientación. Si ya reclamaste, este aviso es solo informativo.`;
  }
}
