import {
  colors,
  mensajeAviso,
  MINUTOS_ESPERA_EJEMPLO,
  NIVEL_TIPO_RECORDATORIO,
  obraParaAvisos,
  radius,
  sizes,
  spacing,
  USUARIO_EJEMPLO,
  type Deuda,
  type TipoRecordatorio,
} from '@almira/shared';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { CajaIcono, Nota, PiePrototipo, Rotulo } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Logo } from '@/components/Logo';
import { Pantalla } from '@/components/Pantalla';
import { Segmentado } from '@/components/Segmentado';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

type Canal = 'whatsapp' | 'sms';

const OPCIONES: { valor: Canal; titulo: string }[] = [
  { valor: 'whatsapp', titulo: 'WhatsApp' },
  { valor: 'sms', titulo: 'SMS (sin smartphone)' },
];

const TITULO_EJEMPLO: Record<TipoRecordatorio, string> = {
  preventivo: 'Recordatorio amable',
  mora: 'Aviso de mora',
  previo_coactiva: 'Aviso previo a coactiva',
};

// Pantalla 11 (maqueta 11-como-llegan-los-avisos). Son mensajes de ejemplo armados
// con las deudas del vecino: no se envía nada. El prototipo no trae textos propios
// para SMS, así que las dos vistas muestran los mismos mensajes; cambia el remitente
// y la forma de las burbujas.
export default function ComoLleganLosAvisos() {
  const { municipalidad, deudas, obras } = useDatosMunicipales();
  const [canal, setCanal] = useState<Canal>('whatsapp');
  const sms = canal === 'sms';

  const porVencer = deudas.find((deuda) => deuda.estado === 'vigente');
  const enMora = deudas.find((deuda) => deuda.estado === 'vencida');
  const ejemplos: { tipo: TipoRecordatorio; deuda: Deuda | undefined }[] = [
    { tipo: 'preventivo', deuda: porVencer },
    { tipo: 'mora', deuda: enMora },
    { tipo: 'previo_coactiva', deuda: enMora },
  ];
  const obra = obraParaAvisos(obras);
  const recibida = [estilos.burbuja, estilos.recibida, sms && estilos.burbujaSms];

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo="Cómo llegan los avisos" />}
    >
      <Segmentado opciones={OPCIONES} elegida={canal} onElegir={setCanal} />

      <View style={estilos.remitente}>
        {sms ? <CajaIcono icono="sms" /> : <Logo />}
        <View style={estilos.flexible}>
          <Texto variante="bodyLgMedium">{municipalidad.nombre} · Almira</Texto>
          <Texto variante="bodyMd" color={colors.textSecondary}>
            {sms ? 'Mensaje de texto' : 'Cuenta de avisos'}
          </Texto>
        </View>
      </View>

      {ejemplos.map(({ tipo, deuda }) =>
        deuda ? (
          <View key={tipo} style={estilos.mensaje}>
            <Rotulo texto={`${NIVEL_TIPO_RECORDATORIO[tipo]} · ${TITULO_EJEMPLO[tipo]}`} />
            <View style={recibida}>
              <Texto>
                {mensajeAviso({
                  tipo,
                  deuda,
                  nombre: USUARIO_EJEMPLO.nombre,
                  obra,
                  version: 'ejemplo',
                })}
              </Texto>
            </View>
          </View>
        ) : null,
      )}

      <Pressable
        accessibilityRole="button"
        onPress={() => router.push('/atencion-humana')}
        style={[estilos.burbuja, estilos.enviada, sms && estilos.burbujaSms]}
      >
        <Texto color={colors.onPrimary}>Quiero hablar con una persona</Texto>
      </Pressable>
      <View style={recibida}>
        <Texto>
          Te derivamos a Atención al vecino. Tiempo estimado: {MINUTOS_ESPERA_EJEMPLO} minutos.
        </Texto>
      </View>

      <Nota
        conBorde
        icono="science"
        texto="Las pruebas A/B ajustan el tono del mensaje, nunca el monto ni los plazos."
      />
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  remitente: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  flexible: { flex: 1 },
  mensaje: { gap: spacing.sm },
  burbuja: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.blockDense,
    borderRadius: radius.lg,
  },
  // Los SMS van con esquinas menos redondas, como en los celulares sin WhatsApp.
  burbujaSms: { borderRadius: radius.md },
  recibida: {
    alignSelf: 'flex-start',
    maxWidth: sizes.bubbleWidth,
    borderTopLeftRadius: radius.sm,
    backgroundColor: colors.subtle,
  },
  enviada: {
    alignSelf: 'flex-end',
    maxWidth: sizes.bubbleWidth,
    backgroundColor: colors.primary,
  },
});
