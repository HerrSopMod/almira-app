// Manejador de `whatsapp-webhook`, con sus dependencias inyectadas para probarlo con Meta
// simulada. `index.ts` lo conecta con Supabase y con la API real.
//
//  - GET: verificación del webhook (hub.verify_token contra WA_VERIFY_TOKEN).
//  - POST: valida X-Hub-Signature-256 con WA_APP_SECRET y rechaza lo que no coincida. Actualiza el
//    estado de cada mensaje (enviado, entregado, leído, fallido) y atiende las respuestas de la
//    persona: BAJA, STOP o NO la dan de baja; cualquier otra cosa recibe una respuesta breve.
import {
  aE164,
  enmascararTelefono,
  enviarTexto,
  firmaValida,
  type EnvLike,
  type FetchLike,
} from '../_shared/whatsapp.ts';

export type EstadoMensaje = 'enviado' | 'entregado' | 'leido' | 'fallido';

export interface AlmacenWebhook {
  /** Actualiza el estado del mensaje con ese id de WhatsApp; nunca retrocede (leído -> enviado). */
  actualizarEstado(waMessageId: string, estado: EstadoMensaje, errorResumen: string | null): Promise<void>;
  /** Marca la baja de todas las preferencias con ese número y apaga el WhatsApp. Devuelve cuántas. */
  darDeBaja(numeroE164: string, cuando: Date): Promise<number>;
}

export type Dependencias = {
  almacen: AlmacenWebhook;
  fetchMeta: FetchLike;
  env: EnvLike;
  ahora: () => Date;
  log: (...partes: unknown[]) => void;
};

export const MENSAJE_BAJA = 'Listo, ya no recibirás recordatorios. Puedes volver a activarlos desde la app.';
export const MENSAJE_GENERAL = 'Hola, soy Almira 👋 Para consultar tus tributos y pagos, usa el asistente de la app.';

const ESTADOS: Record<string, EstadoMensaje> = {
  sent: 'enviado',
  delivered: 'entregado',
  read: 'leido',
  failed: 'fallido',
};

/** "Baja.", "STOP", " no " -> verdadero. Sin distinguir mayúsculas, tildes ni signos. */
export function esBaja(texto: unknown): boolean {
  if (typeof texto !== 'string') return false;
  const limpio = texto
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z]/g, '');
  return limpio === 'baja' || limpio === 'stop' || limpio === 'no';
}

type Valor = {
  statuses?: { id?: string; status?: string; errors?: { code?: number }[] }[];
  messages?: { from?: string; type?: string; text?: { body?: string }; button?: { text?: string } }[];
};

export function crearManejador(dep: Dependencias) {
  return async (solicitud: Request): Promise<Response> => {
    // --- Verificación inicial del webhook ---
    if (solicitud.method === 'GET') {
      const q = new URL(solicitud.url).searchParams;
      const token = dep.env('WA_VERIFY_TOKEN');
      if (token && q.get('hub.mode') === 'subscribe' && q.get('hub.verify_token') === token) {
        return new Response(q.get('hub.challenge') ?? '', { status: 200 });
      }
      return new Response('Prohibido', { status: 403 });
    }
    if (solicitud.method !== 'POST') return new Response('Método no permitido', { status: 405 });

    // --- La firma se calcula sobre el cuerpo tal como llegó ---
    const crudo = await solicitud.text();
    if (!(await firmaValida(crudo, solicitud.headers.get('X-Hub-Signature-256'), dep.env('WA_APP_SECRET')))) {
      return new Response('Firma inválida', { status: 401 });
    }

    let cuerpo: { entry?: { changes?: { value?: Valor }[] }[] };
    try {
      cuerpo = JSON.parse(crudo);
    } catch {
      return new Response('Cuerpo inválido', { status: 400 });
    }

    try {
      for (const entrada of cuerpo.entry ?? []) {
        for (const cambio of entrada.changes ?? []) {
          const valor = cambio.value ?? {};

          for (const estado of valor.statuses ?? []) {
            const nuevo = estado.status ? ESTADOS[estado.status] : undefined;
            if (!estado.id || !nuevo) continue;
            const codigo = estado.errors?.[0]?.code;
            await dep.almacen.actualizarEstado(estado.id, nuevo, nuevo === 'fallido' ? `meta_${codigo ?? 'desconocido'}` : null);
          }

          for (const mensaje of valor.messages ?? []) {
            if (!mensaje.from) continue;
            const numero = aE164(mensaje.from);
            const texto = mensaje.text?.body ?? mensaje.button?.text;
            if (esBaja(texto)) {
              const filas = await dep.almacen.darDeBaja(numero, dep.ahora());
              dep.log(`Baja de ${enmascararTelefono(numero)} (${filas} preferencias)`);
              await enviarTexto(dep.fetchMeta, dep.env, numero, MENSAJE_BAJA).catch(() => null);
            } else {
              await enviarTexto(dep.fetchMeta, dep.env, numero, MENSAJE_GENERAL).catch(() => null);
            }
          }
        }
      }
    } catch {
      // Meta reintenta cuando se responde con error.
      dep.log('No se pudo procesar el webhook de WhatsApp');
      return new Response('Error', { status: 500 });
    }
    return new Response('ok', { status: 200 });
  };
}
