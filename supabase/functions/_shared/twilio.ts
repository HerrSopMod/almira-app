// Envío de mensajes compartido por las Edge Functions: SMS por Twilio y WhatsApp por Meta o,
// si Meta no está configurado, por el sandbox de Twilio.
// Secretos Twilio: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN y, para SMS, TWILIO_MESSAGING_SERVICE_SID
// (o TWILIO_FROM); para el sandbox de WhatsApp, TWILIO_WHATSAPP_FROM.
// Secretos Meta (WhatsApp Cloud API): META_WHATSAPP_TOKEN y META_PHONE_NUMBER_ID.
// Nunca se escriben teléfonos ni mensajes en los logs.
export type CanalTwilio = 'sms' | 'whatsapp';

// Número peruano: 9 dígitos que empiezan con 9, o ya en formato +51. Devuelve "+519XXXXXXXX".
export function normalizarTelefono(telefono: string | null | undefined): string | null {
  if (!telefono) return null;
  const digitos = telefono.replace(/\D/g, '');
  if (/^9\d{8}$/.test(digitos)) return `+51${digitos}`;
  if (/^519\d{8}$/.test(digitos)) return `+${digitos}`;
  return null;
}

// WhatsApp por la API de Meta (Cloud API). Texto libre solo dentro de las 24 h posteriores
// al último mensaje del vecino; fuera de esa ventana Meta exige una plantilla aprobada.
// Secretos: META_WHATSAPP_TOKEN y META_PHONE_NUMBER_ID.
async function enviarWhatsappMeta(para: string, texto: string): Promise<boolean> {
  const token = Deno.env.get('META_WHATSAPP_TOKEN');
  const numeroId = Deno.env.get('META_PHONE_NUMBER_ID');
  if (!token || !numeroId) return false;

  const respuesta = await fetch(`https://graph.facebook.com/v25.0/${numeroId}/messages`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      to: para.replace(/\D/g, ''),
      type: 'text',
      text: { body: texto },
    }),
  });
  if (!respuesta.ok) {
    // Solo el código de error de Meta: nunca el mensaje ni el teléfono.
    const detalle = await respuesta.json().catch(() => null);
    console.error(`Meta (whatsapp) respondió ${respuesta.status}, código ${detalle?.error?.code ?? 'desconocido'}`);
  }
  return respuesta.ok;
}

export async function enviarMensaje(
  canal: CanalTwilio,
  para: string,
  texto: string,
): Promise<boolean> {
  // Si Meta está configurado, WhatsApp sale por Meta; si no, por el sandbox de Twilio.
  if (canal === 'whatsapp' && Deno.env.get('META_WHATSAPP_TOKEN')) {
    return enviarWhatsappMeta(para, texto);
  }
  const sid = Deno.env.get('TWILIO_ACCOUNT_SID');
  const token = Deno.env.get('TWILIO_AUTH_TOKEN');
  if (!sid || !token) return false;

  const cuerpo = new URLSearchParams({ Body: texto });
  if (canal === 'whatsapp') {
    const desde = Deno.env.get('TWILIO_WHATSAPP_FROM')?.replace(/^whatsapp:/, '');
    if (!desde) return false;
    cuerpo.set('To', `whatsapp:${para}`);
    cuerpo.set('From', `whatsapp:${desde}`);
  } else {
    const servicio = Deno.env.get('TWILIO_MESSAGING_SERVICE_SID');
    const desde = Deno.env.get('TWILIO_FROM');
    if (!servicio && !desde) return false;
    cuerpo.set('To', para);
    if (servicio) cuerpo.set('MessagingServiceSid', servicio);
    else cuerpo.set('From', desde!);
  }

  const respuesta = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${btoa(`${sid}:${token}`)}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: cuerpo,
  });
  if (!respuesta.ok) {
    // Solo el código de error de Twilio: nunca el mensaje ni el teléfono.
    const detalle = await respuesta.json().catch(() => null);
    console.error(`Twilio (${canal}) respondió ${respuesta.status}, código ${detalle?.code ?? 'desconocido'}`);
  }
  return respuesta.ok;
}
