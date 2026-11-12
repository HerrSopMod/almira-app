// Cliente mínimo de la API de Gemini (REST). Sin dependencias de Deno.
import { ACCIONES_VALIDAS, type Accion, type MensajeHistorial } from './tipos.ts';

export type RespuestaHttp = {
  ok: boolean;
  status: number;
  json(): Promise<unknown>;
};

export type FetchLike = (
  url: string,
  init: { method: string; headers: Record<string, string>; body: string; signal?: AbortSignal },
) => Promise<RespuestaHttp>;

/** Fallo del servicio del modelo. Su detalle va solo a los logs del servidor. */
export class ErrorGemini extends Error {
  constructor(
    public readonly tipo: 'cuota' | 'tiempo' | 'servicio',
    public readonly estado?: number,
  ) {
    super(`gemini:${tipo}${estado ? `:${estado}` : ''}`);
  }
}

export type PeticionGemini = {
  fetch: FetchLike;
  clave: string;
  modelo: string;
  /** Instrucción de sistema, con el contexto del vecino al final. */
  sistema: string;
  historial: MensajeHistorial[];
  mensaje: string;
  temperatura?: number;
  maxTokens?: number;
  tiempoMs?: number;
};

const ESQUEMA = {
  type: 'object',
  properties: {
    respuesta: { type: 'string' },
    acciones: { type: 'array', items: { type: 'string', enum: [...ACCIONES_VALIDAS] } },
  },
  required: ['respuesta'],
};

function cuerpo(p: PeticionGemini, conEsquema: boolean) {
  return {
    systemInstruction: { parts: [{ text: p.sistema }] },
    contents: [
      ...p.historial.map((m) => ({
        role: m.rol === 'usuario' ? 'user' : 'model',
        parts: [{ text: m.texto }],
      })),
      { role: 'user', parts: [{ text: p.mensaje }] },
    ],
    generationConfig: {
      temperature: p.temperatura ?? 0.25,
      maxOutputTokens: p.maxTokens ?? 600,
      responseMimeType: 'application/json',
      ...(conEsquema ? { responseJsonSchema: ESQUEMA } : {}),
    },
  };
}

async function enviar(p: PeticionGemini, conEsquema: boolean): Promise<RespuestaHttp> {
  const control = new AbortController();
  const reloj = setTimeout(() => control.abort(), p.tiempoMs ?? 20_000);
  try {
    return await p.fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(p.modelo)}:generateContent`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': p.clave },
        body: JSON.stringify(cuerpo(p, conEsquema)),
        signal: control.signal,
      },
    );
  } catch (error) {
    if ((error as { name?: string })?.name === 'AbortError') throw new ErrorGemini('tiempo');
    throw new ErrorGemini('servicio');
  } finally {
    clearTimeout(reloj);
  }
}

/** Lee la respuesta del modelo: JSON {respuesta, acciones}; si no lo es, usa el texto tal cual. */
export function interpretar(texto: string): { respuesta: string; acciones: Accion[] } {
  const limpio = texto.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
  try {
    const datos = JSON.parse(limpio) as { respuesta?: unknown; acciones?: unknown };
    if (typeof datos.respuesta === 'string' && datos.respuesta.trim()) {
      const acciones = Array.isArray(datos.acciones)
        ? datos.acciones.filter((a): a is Accion => ACCIONES_VALIDAS.includes(a as Accion))
        : [];
      return { respuesta: datos.respuesta.trim(), acciones: [...new Set(acciones)] };
    }
  } catch {
    // No era JSON: se usa el texto.
  }
  return { respuesta: limpio, acciones: [] };
}

export async function llamarGemini(p: PeticionGemini): Promise<{ respuesta: string; acciones: Accion[] }> {
  let r = await enviar(p, true);
  // Si el modelo no acepta el esquema, se reintenta una vez sin él (la instrucción ya pide JSON).
  if (r.status === 400) r = await enviar(p, false);
  if (r.status === 429) throw new ErrorGemini('cuota', 429);
  if (!r.ok) throw new ErrorGemini('servicio', r.status);

  const datos = (await r.json()) as {
    candidates?: { content?: { parts?: { text?: string }[] } }[];
  };
  const texto = (datos.candidates?.[0]?.content?.parts ?? []).map((x) => x.text ?? '').join('').trim();
  if (!texto) throw new ErrorGemini('servicio', r.status);
  return interpretar(texto);
}
