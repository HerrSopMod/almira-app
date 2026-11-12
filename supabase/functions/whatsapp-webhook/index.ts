// Edge Function `whatsapp-webhook`: recibe de Meta los estados de los mensajes y las respuestas de
// las personas (BAJA, STOP, NO). Ver README.md y docs/whatsapp-configuracion.md.
//
// Secretos: WA_VERIFY_TOKEN, WA_APP_SECRET, WA_PHONE_NUMBER_ID, WA_ACCESS_TOKEN.
// Nunca se escriben teléfonos ni mensajes en los logs.
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { crearManejador, type EstadoMensaje } from './manejador.ts';

const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
  auth: { persistSession: false },
});

// Estados desde los que se puede pasar a cada uno: así un "enviado" tardío no pisa un "leído".
const PREVIOS: Record<EstadoMensaje, string[]> = {
  enviado: ['en_cola'],
  entregado: ['en_cola', 'enviado'],
  leido: ['en_cola', 'enviado', 'entregado'],
  fallido: ['en_cola', 'enviado'],
};

Deno.serve(
  crearManejador({
    almacen: {
      async actualizarEstado(waMessageId, estado, errorResumen) {
        const { error } = await admin
          .from('recordatorios_enviados')
          .update({ estado, error_resumen: errorResumen, actualizado_at: new Date().toISOString() })
          .eq('wa_message_id', waMessageId)
          .in('estado', PREVIOS[estado]);
        if (error) throw new Error('escritura');
      },
      async darDeBaja(numeroE164, cuando) {
        const { data, error } = await admin
          .from('preferencias_notificacion')
          .update({
            whatsapp_activo: false,
            optout_at: cuando.toISOString(),
            actualizado_at: cuando.toISOString(),
          })
          .eq('whatsapp_numero', numeroE164)
          .select('id');
        if (error) throw new Error('escritura');
        return data?.length ?? 0;
      },
    },
    fetchMeta: (direccion, init) => fetch(direccion, init),
    env: (nombre) => Deno.env.get(nombre),
    ahora: () => new Date(),
    log: (...partes) => console.error(...partes),
  }),
);
