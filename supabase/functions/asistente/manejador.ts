// Manejador de la función `asistente`, con sus dependencias inyectadas para poder probarlo sin
// Deno, sin Supabase y sin Gemini. `index.ts` lo conecta con los servicios reales.
import { fechaLima } from './calculos.ts';
import { contextoComoTexto, ocultarDocumentos } from './contexto.ts';
import { ErrorGemini, llamarGemini, type FetchLike } from './gemini.ts';
import { instruccionSistema } from './prompt.ts';
import type { DatosContribuyente, FilaDeuda, FilaPago, MensajeHistorial, Respuesta } from './tipos.ts';

export const MAX_MENSAJE = 500;
export const MAX_HISTORIAL = 10;
export const MODELO_POR_DEFECTO = 'gemini-3.5-flash-lite';
export const LIMITE_POR_HORA = 30;

export const MENSAJE_SERVICIO =
  'Ahora mismo no puedo responderte. Inténtalo de nuevo en unos minutos o comunícate con tu municipalidad.';
export const MENSAJE_LIMITE =
  'Hoy hablamos bastante. Vuelve a escribirme dentro de un rato y con gusto te sigo ayudando.';
export const MENSAJE_SIN_VINCULO = 'Vincula tu cuponera para que pueda ayudarte con tus tributos.';

// --- Lo mínimo que se usa del cliente de Supabase ---
export interface ConsultaLike extends PromiseLike<{ data: unknown; error: unknown }> {
  select(columnas: string): ConsultaLike;
  eq(columna: string, valor: unknown): ConsultaLike;
  order(columna: string, opciones?: { ascending: boolean }): ConsultaLike;
  limit(n: number): ConsultaLike;
}
export interface ClienteLike {
  auth: { getUser(jwt?: string): Promise<{ data: { user: { id: string } | null }; error: unknown }> };
  rpc(nombre: string, parametros: Record<string, unknown>): PromiseLike<{ data: unknown; error: unknown }>;
  from(tabla: string): ConsultaLike;
}

export type Dependencias = {
  /** Cliente de Supabase que actúa con el JWT del usuario (no con la service key). */
  crearCliente: (jwt: string) => ClienteLike;
  fetchGemini: FetchLike;
  env: (nombre: string) => string | undefined;
  ahora: () => Date;
  log: (...partes: unknown[]) => void;
};

export const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (cuerpo: unknown, status = 200) =>
  new Response(JSON.stringify(cuerpo), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });

const COLUMNAS_VECINO = 'id, municipalidad_id, nombre, nombres, apellidos, codigo_contribuyente';
const COLUMNAS_DEUDA =
  'tipo, concepto, periodo, anio, trimestre, monto_insoluto, gastos_emision, interes_actualizacion, ' +
  'interes_moratorio, descuento, pagos_aplicados, saldo, estado, vencimiento, fecha_pago, nro_valor, exp_coactivo';

/** Limpia el historial: últimos 10, solo roles válidos, con largo máximo y sin documentos. */
export function limpiarHistorial(entrada: unknown): MensajeHistorial[] {
  if (!Array.isArray(entrada)) return [];
  const limpio: MensajeHistorial[] = [];
  for (const m of entrada.slice(-MAX_HISTORIAL)) {
    const rol = (m as { rol?: unknown })?.rol;
    const texto = (m as { texto?: unknown })?.texto;
    if ((rol === 'usuario' || rol === 'asistente') && typeof texto === 'string' && texto.trim()) {
      limpio.push({ rol, texto: ocultarDocumentos(texto.trim().slice(0, MAX_MENSAJE)) });
    }
  }
  return limpio;
}

async function leer<T>(consulta: ConsultaLike): Promise<T[]> {
  const { data, error } = await consulta;
  if (error) throw new Error('lectura');
  return (data as T[] | null) ?? [];
}

export function crearManejador(dep: Dependencias) {
  return async (solicitud: Request): Promise<Response> => {
    if (solicitud.method === 'OPTIONS') return new Response(null, { headers: CORS });
    if (solicitud.method !== 'POST') return json({ error: 'Método no permitido' }, 405);

    const autorizacion = solicitud.headers.get('Authorization') ?? '';
    const jwt = autorizacion.startsWith('Bearer ') ? autorizacion.slice(7).trim() : '';
    if (!jwt) return json({ error: 'No autorizado' }, 401);

    let cuerpo: { mensaje?: unknown; historial?: unknown; municipalidadId?: unknown };
    try {
      cuerpo = await solicitud.json();
    } catch {
      return json({ error: 'Solicitud inválida' }, 400);
    }
    const mensaje = typeof cuerpo.mensaje === 'string' ? cuerpo.mensaje.trim() : '';
    if (!mensaje || mensaje.length > MAX_MENSAJE) return json({ error: 'Mensaje inválido' }, 400);

    // Todo lo que sigue corre con el JWT de la persona: RLS limita cada lectura a su contribuyente.
    const cliente = dep.crearCliente(jwt);
    const { data: sesion, error: errorSesion } = await cliente.auth.getUser(jwt);
    const usuarioId = sesion.user?.id;
    if (errorSesion || !usuarioId) return json({ error: 'No autorizado' }, 401);

    const claveGemini = dep.env('GEMINI_API_KEY');
    if (!claveGemini) {
      dep.log('asistente: falta GEMINI_API_KEY');
      return json({ respuesta: MENSAJE_SERVICIO, acciones: [], error: 'servicio' } satisfies Respuesta);
    }

    try {
      // Límite de uso por persona (contador en la base, con el JWT de la persona).
      const limite = Number(dep.env('ASISTENTE_LIMITE_HORA')) || LIMITE_POR_HORA;
      const cupo = await cliente.rpc('consumir_cupo_asistente', { p_limite: limite });
      if (cupo.error) throw new Error('cupo');
      if (cupo.data === 'sin_sesion') return json({ error: 'No autorizado' }, 401);
      if (cupo.data === 'sin_vinculo') {
        return json({ respuesta: MENSAJE_SIN_VINCULO, acciones: [], error: 'sin_vinculo' } satisfies Respuesta);
      }
      if (cupo.data === 'limite') {
        return json({ respuesta: MENSAJE_LIMITE, acciones: [], error: 'limite' } satisfies Respuesta);
      }

      const vecinos = await leer<{
        id: string;
        municipalidad_id: string;
        nombre: string;
        nombres: string | null;
        apellidos: string | null;
        codigo_contribuyente: string | null;
      }>(cliente.from('vecinos').select(COLUMNAS_VECINO).eq('user_id', usuarioId));
      const pedida = typeof cuerpo.municipalidadId === 'string' ? cuerpo.municipalidadId : null;
      const vecino = vecinos.find((v) => v.municipalidad_id === pedida) ?? vecinos[0];
      if (!vecino) {
        return json({ respuesta: MENSAJE_SIN_VINCULO, acciones: [], error: 'sin_vinculo' } satisfies Respuesta);
      }

      const [municipalidades, predios, deudas, pagos] = await Promise.all([
        leer<{ nombre: string; telefono_ayuda: string | null }>(
          cliente.from('municipalidades').select('nombre, telefono_ayuda').eq('id', vecino.municipalidad_id),
        ),
        leer<{ codigo: string; direccion: string }>(
          cliente.from('predios').select('codigo, direccion').eq('vecino_id', vecino.id),
        ),
        leer<FilaDeuda>(cliente.from('deudas').select(COLUMNAS_DEUDA).eq('vecino_id', vecino.id)),
        leer<FilaPago>(
          cliente
            .from('pagos')
            .select('monto, medio, referencia, creado_en')
            .eq('vecino_id', vecino.id)
            .eq('estado', 'confirmado')
            .order('creado_en', { ascending: false })
            .limit(5),
        ),
      ]);
      const municipalidad = municipalidades[0] ?? { nombre: 'municipalidad', telefono_ayuda: null };

      const datos: DatosContribuyente = {
        nombre: vecino.nombres?.trim() || vecino.nombre,
        codigoContribuyente: vecino.codigo_contribuyente,
        municipalidad: { nombre: municipalidad.nombre, telefonoAyuda: municipalidad.telefono_ayuda },
        predios,
        deudas,
        pagos,
      };
      const hoy = fechaLima(dep.ahora());
      const sistema =
        `${instruccionSistema(municipalidad.nombre)}\n\n` +
        `CONTEXTO (datos de este vecino, solo lectura):\n${contextoComoTexto(datos, hoy)}`;

      const resultado = await llamarGemini({
        fetch: dep.fetchGemini,
        clave: claveGemini,
        modelo: dep.env('GEMINI_MODEL') || MODELO_POR_DEFECTO,
        sistema,
        historial: limpiarHistorial(cuerpo.historial),
        mensaje: ocultarDocumentos(mensaje),
      });
      return json({
        respuesta: resultado.respuesta.slice(0, 1500),
        acciones: resultado.acciones,
      } satisfies Respuesta);
    } catch (error) {
      // El detalle va solo al log del servidor; la persona recibe un mensaje amable y genérico.
      const motivo = error instanceof ErrorGemini ? error.message : (error as Error)?.message ?? 'error';
      dep.log('asistente: fallo', motivo);
      return json({ respuesta: MENSAJE_SERVICIO, acciones: [], error: 'servicio' } satisfies Respuesta);
    }
  };
}
