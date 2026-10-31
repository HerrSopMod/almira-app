// Edge Function de ejemplo: procesa los recordatorios programados que ya vencieron.
// Solo la llama un cron con el secreto RECORDATORIOS_SECRETO; usa service_role
// porque ninguna política permite escribir recordatorios desde el cliente.
import { createClient } from 'jsr:@supabase/supabase-js@2';

type Recordatorio = {
  id: string;
  municipalidad_id: string;
  canal: 'whatsapp' | 'sms' | 'app';
};

const LIMITE_POR_EJECUCION = 100;

// Ejemplo: aún no hay proveedor de WhatsApp, SMS ni notificaciones conectado.
// Antes de producción, reemplazar por el envío real y devolver su resultado.
async function enviarPorCanal(recordatorio: Recordatorio): Promise<boolean> {
  console.log(`Envío simulado ${recordatorio.id} por ${recordatorio.canal}`);
  return true;
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
    .select('id, municipalidad_id, canal')
    .eq('estado', 'programado')
    .lte('programado_para', new Date().toISOString())
    .order('programado_para')
    .limit(LIMITE_POR_EJECUCION);

  if (error) {
    console.error('No se pudieron leer los recordatorios', error.message);
    return responder({ error: 'Error al leer recordatorios' }, 500);
  }

  let enviados = 0;
  let fallidos = 0;

  for (const recordatorio of (data ?? []) as Recordatorio[]) {
    const exito = await enviarPorCanal(recordatorio).catch(() => false);
    // El filtro por estado evita pisar otra ejecución simultánea.
    const { error: errorEstado } = await supabase
      .from('recordatorios')
      .update({ estado: exito ? 'enviado' : 'fallido' })
      .eq('id', recordatorio.id)
      .eq('estado', 'programado');

    if (errorEstado || !exito) fallidos += 1;
    else enviados += 1;
  }

  return responder({ procesados: enviados + fallidos, enviados, fallidos });
});
