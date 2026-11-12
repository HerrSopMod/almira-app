// Manejador de `enviar-recordatorios`, con sus dependencias inyectadas (sin Deno, sin Supabase y
// sin Meta) para probarlo. `index.ts` lo conecta con los servicios reales.
//
// Dos formas de llamarlo:
//  - Con `Authorization: Bearer <RECORDATORIOS_SECRETO>`: ejecuta los recordatorios del día. Lo
//    llama pg_cron a las 10:00 de Lima (15:00 UTC) y también sirve para una ejecución manual.
//  - Con el JWT de un vecino y `{"accion":"bienvenida"}`: manda la bienvenida a su propio número
//    ya guardado. No acepta ningún otro dato del cliente (ni número, ni texto).
import { enmascararTelefono, type EnvLike, type FetchLike } from '../_shared/whatsapp.ts';
import {
  MAX_BIENVENIDAS_POR_DIA,
  enviarUno,
  procesarCandidatos,
  type Almacen,
  type Candidato,
} from './logica.ts';

/** Datos del contribuyente de la cuenta, para la bienvenida. Sin DNI ni cuponera. */
export type DatosBienvenida = {
  vecino_id: string;
  municipalidad_id: string;
  municipalidad: string;
  nombre: string;
  numero: string | null;
  whatsapp_activo: boolean;
  optout_at: string | null;
  consentimiento_at: string | null;
};

export interface AlmacenCompleto extends Almacen {
  datosBienvenida(userId: string): Promise<DatosBienvenida | null>;
  bienvenidasDesde(vecinoId: string, desde: Date): Promise<number>;
}

export type Dependencias = {
  almacen: AlmacenCompleto;
  /** Devuelve el id del usuario del JWT, o null si no vale. */
  usuarioDe: (jwt: string) => Promise<string | null>;
  fetchMeta: FetchLike;
  env: EnvLike;
  ahora: () => Date;
  pausa: (ms: number) => Promise<void>;
  log: (...partes: unknown[]) => void;
};

export const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (cuerpo: unknown, status = 200) =>
  new Response(JSON.stringify(cuerpo), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });

/** Comparación sin cortocircuito, para el secreto de la ejecución programada. */
function iguales(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let d = 0;
  for (let i = 0; i < a.length; i++) d |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return d === 0;
}

export function crearManejador(dep: Dependencias) {
  return async (solicitud: Request): Promise<Response> => {
    if (solicitud.method === 'OPTIONS') return new Response(null, { headers: CORS });
    if (solicitud.method !== 'POST') return json({ error: 'Método no permitido' }, 405);

    const autorizacion = solicitud.headers.get('Authorization') ?? '';
    const token = autorizacion.replace(/^Bearer\s+/i, '');
    if (!token) return json({ error: 'No autorizado' }, 401);

    const cuerpo = (await solicitud.json().catch(() => ({}))) as { accion?: unknown };
    const envioDep = { almacen: dep.almacen, fetchMeta: dep.fetchMeta, env: dep.env, pausa: dep.pausa, log: dep.log };

    // --- Ejecución programada o manual ---
    const secreto = dep.env('RECORDATORIOS_SECRETO');
    if (secreto && iguales(token, secreto)) {
      if (cuerpo.accion !== undefined && cuerpo.accion !== 'ejecutar') return json({ error: 'Acción no válida' }, 400);
      const ahora = dep.ahora();
      let candidatos: Candidato[];
      try {
        candidatos = await dep.almacen.candidatos(ahora);
      } catch {
        dep.log('No se pudieron leer los candidatos de recordatorios');
        return json({ error: 'Error al leer recordatorios' }, 500);
      }
      return json(await procesarCandidatos(candidatos, ahora, envioDep));
    }

    // --- Bienvenida: la pide el propio vecino ---
    if (cuerpo.accion !== 'bienvenida') return json({ error: 'No autorizado' }, 401);
    const usuario = await dep.usuarioDe(token);
    if (!usuario) return json({ error: 'No autorizado' }, 401);

    const datos = await dep.almacen.datosBienvenida(usuario);
    if (!datos || !datos.whatsapp_activo || datos.optout_at || !datos.consentimiento_at || !datos.numero) {
      return json({ enviado: false, motivo: 'sin_activar' });
    }
    const ahora = dep.ahora();
    // Para que nadie use la bienvenida de cañón contra números ajenos.
    const desde = new Date(ahora.getTime() - 24 * 60 * 60 * 1000);
    if ((await dep.almacen.bienvenidasDesde(datos.vecino_id, desde)) >= MAX_BIENVENIDAS_POR_DIA) {
      return json({ enviado: false, motivo: 'limite' }, 429);
    }
    const resultado = await enviarUno(
      {
        vecino_id: datos.vecino_id,
        municipalidad_id: datos.municipalidad_id,
        municipalidad: datos.municipalidad,
        nombre: datos.nombre,
        numero: datos.numero,
        tipo: 'bienvenida',
        // Una bienvenida por cada consentimiento: si activa de nuevo, vuelve a recibirla.
        periodo: datos.consentimiento_at,
        tipos: [],
        monto: 0,
        fecha: null,
        referencia: null,
        con_coactivo: false,
        saldo_pendiente: 0,
        whatsapp_activo: datos.whatsapp_activo,
        optout_at: datos.optout_at,
        consentimiento_at: datos.consentimiento_at,
      },
      ahora,
      envioDep,
    );
    dep.log(`Bienvenida a ${enmascararTelefono(datos.numero)}: ${resultado.estado}`);
    return json({ enviado: resultado.estado === 'enviado' || resultado.estado === 'duplicado' });
  };
}
