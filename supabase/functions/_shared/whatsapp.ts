// WhatsApp Cloud API (Meta): envío de plantillas y texto, firma del webhook y enmascarado de
// teléfonos. Módulo sin dependencias de Deno para poder probarlo con Meta simulada.
//
// Secretos (supabase secrets set ...): WA_PHONE_NUMBER_ID, WA_ACCESS_TOKEN, WA_APP_SECRET,
// WA_VERIFY_TOKEN. Opcional: WA_IDIOMA (por defecto es_PE). Si WA_PHONE_NUMBER_ID o
// WA_ACCESS_TOKEN no están, se usan META_PHONE_NUMBER_ID y META_WHATSAPP_TOKEN, que ya usa
// `vincular-whatsapp`.
// Nunca se escriben teléfonos ni mensajes en los logs: se enmascaran con `enmascararTelefono`.

export const VERSION_GRAPH = 'v25.0';

export type FetchLike = (
  url: string,
  init: { method: string; headers: Record<string, string>; body: string },
) => Promise<{ ok: boolean; status: number; json(): Promise<unknown> }>;

export type EnvLike = (nombre: string) => string | undefined;

/** "+51987654321" -> "+51 9** *** 321". Cualquier otro valor se oculta casi por completo. */
export function enmascararTelefono(telefono: string | null | undefined): string {
  const digitos = (telefono ?? '').replace(/\D/g, '');
  if (/^519\d{8}$/.test(digitos)) return `+51 9** *** ${digitos.slice(-3)}`;
  if (digitos.length >= 6) return `***${digitos.slice(-3)}`;
  return '***';
}

/** Número de Meta (sin "+") a E.164. */
export const aE164 = (waId: string): string => `+${waId.replace(/\D/g, '')}`;

const sinPlus = (e164: string): string => e164.replace(/\D/g, '');

// --- Firma del webhook ---

function hexABytes(hex: string): Uint8Array | null {
  if (!/^[0-9a-f]+$/i.test(hex) || hex.length % 2 !== 0) return null;
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) bytes[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  return bytes;
}

/** HMAC-SHA256 del cuerpo, en hexadecimal. */
export async function firmarCuerpo(cuerpo: string, secreto: string): Promise<string> {
  const codificador = new TextEncoder();
  const clave = await crypto.subtle.importKey(
    'raw',
    codificador.encode(secreto),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const firma = new Uint8Array(await crypto.subtle.sign('HMAC', clave, codificador.encode(cuerpo)));
  return Array.from(firma, (b) => b.toString(16).padStart(2, '0')).join('');
}

/** Valida `X-Hub-Signature-256: sha256=<hex>` sobre el cuerpo tal como llegó. */
export async function firmaValida(
  cuerpo: string,
  encabezado: string | null,
  secreto: string | undefined,
): Promise<boolean> {
  if (!secreto || !encabezado?.startsWith('sha256=')) return false;
  const recibida = hexABytes(encabezado.slice('sha256='.length));
  const esperada = hexABytes(await firmarCuerpo(cuerpo, secreto));
  if (!recibida || !esperada || recibida.length !== esperada.length) return false;
  // Comparación sin cortocircuito.
  let diferencia = 0;
  for (let i = 0; i < esperada.length; i++) diferencia |= recibida[i]! ^ esperada[i]!;
  return diferencia === 0;
}

// --- Envío ---

export type ResultadoEnvio =
  | { ok: true; id: string | null }
  /** `transitorio`: conviene reintentar (caída, límite de velocidad). */
  | { ok: false; codigo: string; transitorio: boolean };

type Credenciales = { numeroId: string; token: string };

function credenciales(env: EnvLike): Credenciales | null {
  const numeroId = env('WA_PHONE_NUMBER_ID') ?? env('META_PHONE_NUMBER_ID');
  const token = env('WA_ACCESS_TOKEN') ?? env('META_WHATSAPP_TOKEN');
  return numeroId && token ? { numeroId, token } : null;
}

// Códigos de Meta que se reintentan: límites de velocidad y fallos temporales.
const CODIGOS_TRANSITORIOS = new Set([1, 2, 4, 17, 80007, 130429, 131016, 131056]);
// 132001: la plantilla no existe en ese idioma.
const CODIGO_PLANTILLA_SIN_IDIOMA = 132001;

async function publicar(
  fetchMeta: FetchLike,
  cred: Credenciales,
  cuerpo: Record<string, unknown>,
): Promise<ResultadoEnvio & { codigoMeta?: number }> {
  let respuesta;
  try {
    respuesta = await fetchMeta(`https://graph.facebook.com/${VERSION_GRAPH}/${cred.numeroId}/messages`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${cred.token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ messaging_product: 'whatsapp', ...cuerpo }),
    });
  } catch {
    return { ok: false, codigo: 'red', transitorio: true };
  }
  const datos = (await respuesta.json().catch(() => null)) as {
    messages?: { id?: string }[];
    error?: { code?: number };
  } | null;
  if (respuesta.ok) return { ok: true, id: datos?.messages?.[0]?.id ?? null };
  const codigoMeta = datos?.error?.code;
  return {
    ok: false,
    codigo: codigoMeta ? `meta_${codigoMeta}` : `http_${respuesta.status}`,
    codigoMeta,
    transitorio:
      respuesta.status >= 500 || respuesta.status === 429 || (codigoMeta ? CODIGOS_TRANSITORIOS.has(codigoMeta) : false),
  };
}

/** Meta no acepta saltos de línea, tabulaciones ni más de 4 espacios seguidos en una variable. */
export const limpiarVariable = (valor: string): string =>
  valor.replace(/[\r\n\t]+/g, ' ').replace(/ {2,}/g, ' ').trim().slice(0, 200) || '-';

/**
 * Envía un mensaje de plantilla. Si la cuenta no tiene la plantilla en `es_PE`, reintenta una vez
 * en `es`.
 */
export async function enviarPlantilla(
  fetchMeta: FetchLike,
  env: EnvLike,
  para: string,
  plantilla: string,
  variables: string[],
): Promise<ResultadoEnvio> {
  const cred = credenciales(env);
  if (!cred) return { ok: false, codigo: 'sin_configurar', transitorio: false };
  const idiomaBase = env('WA_IDIOMA') ?? 'es_PE';
  const idiomas = idiomaBase === 'es' ? ['es'] : [idiomaBase, 'es'];

  let ultimo: ResultadoEnvio = { ok: false, codigo: 'sin_enviar', transitorio: false };
  for (const idioma of idiomas) {
    const r = await publicar(fetchMeta, cred, {
      to: sinPlus(para),
      type: 'template',
      template: {
        name: plantilla,
        language: { code: idioma },
        components: [
          { type: 'body', parameters: variables.map((v) => ({ type: 'text', text: limpiarVariable(v) })) },
        ],
      },
    });
    if (r.ok) return { ok: true, id: r.id };
    ultimo = { ok: false, codigo: r.codigo, transitorio: r.transitorio };
    if (r.codigoMeta !== CODIGO_PLANTILLA_SIN_IDIOMA) break;
  }
  return ultimo;
}

/** Texto libre: solo vale dentro de las 24 h posteriores a un mensaje de la persona. */
export async function enviarTexto(
  fetchMeta: FetchLike,
  env: EnvLike,
  para: string,
  texto: string,
): Promise<ResultadoEnvio> {
  const cred = credenciales(env);
  if (!cred) return { ok: false, codigo: 'sin_configurar', transitorio: false };
  const r = await publicar(fetchMeta, cred, { to: sinPlus(para), type: 'text', text: { body: texto } });
  return r.ok ? { ok: true, id: r.id } : { ok: false, codigo: r.codigo, transitorio: r.transitorio };
}
