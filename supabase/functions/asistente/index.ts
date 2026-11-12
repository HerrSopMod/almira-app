// Edge Function `asistente`: responde preguntas del vecino sobre sus tributos con Gemini.
// Lee los datos con el JWT de la persona (RLS), calcula los totales en código y le pasa al modelo
// un contexto sin DNI ni número de cuponera. Ver README.md.
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { crearManejador, type ClienteLike } from './manejador.ts';

Deno.serve(
  crearManejador({
    crearCliente: (jwt) =>
      createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
        global: { headers: { Authorization: `Bearer ${jwt}` } },
        auth: { persistSession: false },
      }) as unknown as ClienteLike,
    fetchGemini: (url, init) => fetch(url, init),
    env: (nombre) => Deno.env.get(nombre),
    ahora: () => new Date(),
    log: (...partes) => console.error(...partes),
  }),
);
