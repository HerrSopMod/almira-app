// Envío de mensajes con Twilio, compartido por las Edge Functions.
// Secretos: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN y, para SMS, TWILIO_MESSAGING_SERVICE_SID
// (o TWILIO_FROM). Para WhatsApp: TWILIO_WHATSAPP_FROM (en el sandbox, el número del sandbox).
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

export async function enviarMensaje(
  canal: CanalTwilio,
  para: string,
  texto: string,
): Promise<boolean> {
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
  if (!respuesta.ok) console.error(`Twilio (${canal}) respondió ${respuesta.status}`);
  return respuesta.ok;
}
