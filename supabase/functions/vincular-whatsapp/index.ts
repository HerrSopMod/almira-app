// Edge Function: vincula el WhatsApp del vecino después de que confirmó su celular por SMS.
// La llama la app con la sesión del vecino (JWT). Toma el celular ya confirmado de su cuenta
// de Supabase Auth, lo guarda en sus filas de `vecinos` con canal preferido WhatsApp y le
// manda un mensaje de confirmación. Usa service_role porque ninguna política deja al cliente
// escribir `vecinos.telefono`. Nunca se escriben teléfonos en los logs.
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { enviarMensaje, normalizarTelefono } from '../_shared/twilio.ts';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function responder(cuerpo: unknown, status = 200) {
  return new Response(JSON.stringify(cuerpo), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (solicitud) => {
  if (solicitud.method === 'OPTIONS') return new Response(null, { headers: CORS });
  if (solicitud.method !== 'POST') return responder({ error: 'Método no permitido' }, 405);

  const autorizacion = solicitud.headers.get('Authorization');
  if (!autorizacion) return responder({ error: 'No autorizado' }, 401);

  const url = Deno.env.get('SUPABASE_URL')!;
  const comoVecino = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: autorizacion } },
    auth: { persistSession: false },
  });
  const { data: sesion, error: errorSesion } = await comoVecino.auth.getUser();
  const usuario = sesion?.user;
  if (errorSesion || !usuario) return responder({ error: 'No autorizado' }, 401);

  // Solo se vincula un celular que el vecino ya confirmó con el código SMS.
  const telefono = usuario.phone_confirmed_at ? normalizarTelefono(usuario.phone) : null;
  if (!telefono) return responder({ error: 'Celular sin confirmar' }, 400);

  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false },
  });
  const { data: filas, error } = await admin
    .from('vecinos')
    .update({ telefono: telefono.slice(3), canal_preferido: 'whatsapp' })
    .eq('user_id', usuario.id)
    .select('id');
  if (error) {
    console.error('No se pudo guardar el celular', error.message);
    return responder({ error: 'Error al vincular' }, 500);
  }
  if (!filas || filas.length === 0) return responder({ error: 'Sin vecino vinculado' }, 404);

  const enviado = await enviarMensaje(
    'whatsapp',
    telefono,
    'Almira: ya vinculamos este WhatsApp. Por aquí te avisaremos de tus tributos y reclamos.',
  ).catch(() => false);

  return responder({ vinculado: true, enviado });
});
