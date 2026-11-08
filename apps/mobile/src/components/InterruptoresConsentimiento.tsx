import type { Consentimientos } from '@/sesion';
import { Separador, Tarjeta } from './Bloques';
import { Interruptor } from './Interruptor';

// Permisos de "Tus datos, tus reglas" (pantalla 03), también en Privacidad y mis datos (22).
export function InterruptoresConsentimiento({
  valor,
  onCambiar,
}: {
  valor: Consentimientos;
  onCambiar: (valor: Consentimientos) => void;
}) {
  return (
    <Tarjeta>
      <Interruptor
        icono="support-agent"
        titulo="Asistente"
        detalle="Guarda tus consultas para orientarte mejor."
        activo={valor.asistenteIa}
        onCambiar={(asistenteIa) => onCambiar({ ...valor, asistenteIa })}
      />
      <Separador />
      <Interruptor
        icono="chat"
        titulo="Avisos por WhatsApp"
        detalle="Máximo 1 por día y 3 por semana."
        activo={valor.avisosWhatsapp}
        onCambiar={(avisosWhatsapp) => onCambiar({ ...valor, avisosWhatsapp })}
      />
      <Separador />
      <Interruptor
        icono="sms"
        titulo="Avisos por SMS"
        detalle="Canal alterno si WhatsApp falla."
        activo={valor.avisosSms}
        onCambiar={(avisosSms) => onCambiar({ ...valor, avisosSms })}
      />
    </Tarjeta>
  );
}
