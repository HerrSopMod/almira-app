// Edge Function: envía por SMS y WhatsApp (Twilio) los recordatorios programados que ya vencieron.
// Solo la llama un cron con el secreto RECORDATORIOS_SECRETO; usa service_role
// porque ninguna política permite escribir recordatorios desde el cliente.
//
// Secretos necesarios (supabase secrets set ...):
//   RECORDATORIOS_SECRETO, TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN,
//   TWILIO_MESSAGING_SERVICE_SID (o TWILIO_FROM) para SMS y TWILIO_WHATSAPP_FROM para WhatsApp.
//
// Procesa los canales "sms" y "whatsapp". El canal "app" no tiene proveedor conectado: esos
// recordatorios se quedan "programado" en vez de marcarse como enviados sin salir nada.
// Nunca se escriben teléfonos ni mensajes en los logs.
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { enviarMensaje, normalizarTelefono } from '../_shared/twilio.ts';

type Fila = {
  id: string;
  tipo: 'preventivo' | 'mora' | 'previo_coactiva';
  canal: 'sms' | 'whatsapp';
  vecinos: { telefono: string | null } | null;
  deudas: { concepto: string; total: number; vencimiento: string } | null;
  municipalidades: { nombre: string } | null;
};

const LIMITE_POR_EJECUCION = 100;

const soles = (monto: number) => `S/ ${monto.toFixed(2)}`;

function mensaje(fila: Fila): string {
  const municipalidad = fila.municipalidades?.nombre ?? 'Almira';
  const deuda = fila.deudas;
  if (!deuda) return `Almira: tienes un aviso de tu ${municipalidad}. Revisa la app.`;
  const detalle = `${deuda.concepto} por ${soles(deuda.total)}`;
  if (fila.tipo === 'preventivo') {
    return `Almira: tu ${detalle} vence el ${deuda.vencimiento}. Págalo desde la app. ${municipalidad}.`;
  }
  return `Almira: tu ${detalle} está vencido desde el ${deuda.vencimiento}. Págalo desde la app para evitar más intereses. ${municipalidad}.`;
}

function responder(cuerpo: unknown, status = 200) {
  return new Response(JSON.stringify(cuerpo), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (solicitud) => {
  if (solicitud.method !== 'POST') return responder({ error: 'Método no permitido' }, 405);

  const secreto = Deno.env.get('RECORDATORIOS_SECRETO');
  const autorizado = secreto && solicitud.headers.get('Authorization') === `Bearer ${secreto}`;
  if (!autorizado) return responder({ error: 'No autorizado' }, 401);

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  );

  const { data, error } = await supabase
    .from('recordatorios')
    .select(
      'id, tipo, canal, vecinos(telefono), deudas(concepto, total, vencimiento), municipalidades(nombre)',
    )
    .eq('estado', 'programado')
    .in('canal', ['sms', 'whatsapp'])
    .lte('programado_para', new Date().toISOString())
    .order('programado_para')
    .limit(LIMITE_POR_EJECUCION);

  if (error) {
    console.error('No se pudieron leer los recordatorios', error.message);
    return responder({ error: 'Error al leer recordatorios' }, 500);
  }

  let enviados = 0;
  let fallidos = 0;

  for (const fila of (data ?? []) as unknown as Fila[]) {
    const telefono = normalizarTelefono(fila.vecinos?.telefono ?? null);
    const exito = telefono ? await enviarMensaje(fila.canal, telefono, mensaje(fila)).catch(() => false) : false;
    // El filtro por estado evita pisar otra ejecución simultánea.
    const { error: errorEstado } = await supabase
      .from('recordatorios')
      .update({ estado: exito ? 'enviado' : 'fallido' })
      .eq('id', fila.id)
      .eq('estado', 'programado');

    if (errorEstado || !exito) fallidos += 1;
    else enviados += 1;
  }

  return responder({ procesados: enviados + fallidos, enviados, fallidos });
});
