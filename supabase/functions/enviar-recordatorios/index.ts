// Edge Function `enviar-recordatorios`: recordatorios por WhatsApp (Cloud API de Meta, plantillas)
// para quien activó el opt-in. La programa pg_cron a las 10:00 de Lima (supabase/cron-recordatorios.sql)
// y también acepta una ejecución manual con RECORDATORIOS_SECRETO. Ver README.md.
//
// Secretos: RECORDATORIOS_SECRETO, WA_PHONE_NUMBER_ID, WA_ACCESS_TOKEN (WA_APP_SECRET y
// WA_VERIFY_TOKEN los usa `whatsapp-webhook`). SUPABASE_* los pone la plataforma.
// Nunca se escriben teléfonos ni mensajes en los logs.
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { crearAlmacen } from './almacen.ts';
import { crearManejador } from './manejador.ts';

const url = Deno.env.get('SUPABASE_URL')!;
const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });

Deno.serve(
  crearManejador({
    almacen: crearAlmacen(admin),
    usuarioDe: async (jwt) => {
      const { data, error } = await admin.auth.getUser(jwt);
      return error || !data.user ? null : data.user.id;
    },
    fetchMeta: (direccion, init) => fetch(direccion, init),
    env: (nombre) => Deno.env.get(nombre),
    ahora: () => new Date(),
    pausa: (ms) => new Promise((resolver) => setTimeout(resolver, ms)),
    log: (...partes) => console.error(...partes),
  }),
);
