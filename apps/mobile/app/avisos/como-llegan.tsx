import {
  colors,
  mensajeAviso,
  MINUTOS_ESPERA_EJEMPLO,
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
import { Destacado } from '@/components/Bloques';
import { Chips } from '@/components/Chips';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

type Canal = 'whatsapp' | 'sms';

const CHIPS: { valor: Canal; titulo: string }[] = [
  { valor: 'whatsapp', titulo: 'WhatsApp' },
  { valor: 'sms', titulo: 'SMS (sin smartphone)' },
];

const TITULO_EJEMPLO: Record<TipoRecordatorio, string> = {
  preventivo: '1. Recordatorio amable',
  mora: '2. Aviso de mora',
  previo_coactiva: '3. Aviso previo a coactiva',
};

// Pantalla 11 del prototipo. Son mensajes de ejemplo armados con las deudas del
// vecino: no se envía nada. El prototipo no trae textos propios para SMS, así que
// ambos chips muestran los mismos mensajes.
export default function ComoLleganLosAvisos() {
  const { municipalidad, deudas, obras } = useDatosMunicipales();
  const [canal, setCanal] = useState<Canal>('whatsapp');

  const porVencer = deudas.find((deuda) => deuda.estado === 'vigente');
  const enMora = deudas.find((deuda) => deuda.estado === 'vencida');
  const ejemplos: { tipo: TipoRecordatorio; deuda: Deuda | undefined }[] = [
    { tipo: 'preventivo', deuda: porVencer },
    { tipo: 'mora', deuda: enMora },
    { tipo: 'previo_coactiva', deuda: enMora },
  ];
  const obra = obraParaAvisos(obras);

  return (
    <Pantalla
      encabezadoHastaArriba
      separacion="blockDense"
      encabezado={<BarraSuperior titulo="Cómo llegan los avisos" />}
    >
      <Chips opciones={CHIPS} elegida={canal} onElegir={setCanal} />

      <View>
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
          {municipalidad.nombre} · Almira
        </Texto>
        <Texto variante="caption" color={colors.textSecondary} alineacion="center">
          Mensajes de ejemplo. En este prototipo no se envía ningún mensaje.
        </Texto>
      </View>

      {ejemplos.map(({ tipo, deuda }) =>
        deuda ? (
          <View key={tipo} style={[estilos.burbuja, estilos.recibida]}>
            <Texto variante="bodyMdMedium">{TITULO_EJEMPLO[tipo]}</Texto>
            <Texto variante="bodyMd">
              {mensajeAviso({
                tipo,
                deuda,
                nombre: USUARIO_EJEMPLO.nombre,
                obra,
                version: 'ejemplo',
              })}
            </Texto>
          </View>
        ) : null,
      )}

      <Pressable
        accessibilityRole="button"
        onPress={() => router.push('/atencion-humana')}
        style={[estilos.burbuja, estilos.enviada]}
      >
        <Texto variante="bodyMd">Quiero hablar con una persona</Texto>
      </Pressable>
      <View style={[estilos.burbuja, estilos.recibida]}>
        <Texto variante="bodyMd">
          Te derivamos a Atención al vecino. Tiempo estimado: {MINUTOS_ESPERA_EJEMPLO} minutos.
        </Texto>
      </View>

      <Destacado
        texto="Las pruebas A/B ajustan el tono del mensaje, nunca el monto ni los plazos."
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  burbuja: {
    gap: spacing.xs,
    padding: spacing.blockDense,
    borderRadius: radius.md,
  },
  recibida: {
    alignSelf: 'flex-start',
    width: sizes.bubbleWidth,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  enviada: {
    alignSelf: 'flex-end',
    maxWidth: sizes.bubbleWidth,
    backgroundColor: colors.backgroundPink,
  },
});
