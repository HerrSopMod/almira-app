import {
  colors,
  DETALLE_TIPO_RECORDATORIO,
  ETIQUETA_TIPO_RECORDATORIO,
  NIVEL_TIPO_RECORDATORIO,
  radius,
  sizes,
  spacing,
  TIPOS_RECORDATORIO,
  type TipoRecordatorio,
} from '@almira/shared';
import { StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

// Los tonos vino de la guía de estilos solo se usan aquí.
const COLORES_PASO: Record<TipoRecordatorio, { fondo: string; texto: string }> = {
  preventivo: { fondo: colors.notice1, texto: colors.notice3 },
  mora: { fondo: colors.notice2, texto: colors.onPrimary },
  previo_coactiva: { fondo: colors.notice3, texto: colors.onPrimary },
};

type PropsPaso = {
  tipo: TipoRecordatorio;
  conDetalle?: boolean;
  estasAqui?: boolean;
};

// Un paso de la escalera de avisos. En el detalle del aviso (pantalla 10) va solo y sin subtítulo.
export function PasoAviso({ tipo, conDetalle, estasAqui }: PropsPaso) {
  const { fondo, texto } = COLORES_PASO[tipo];
  const nivel = NIVEL_TIPO_RECORDATORIO[tipo];
  return (
    <View
      accessible
      accessibilityLabel={`Paso ${nivel}: ${ETIQUETA_TIPO_RECORDATORIO[tipo]}${
        conDetalle ? `. ${DETALLE_TIPO_RECORDATORIO[tipo]}` : ''
      }${estasAqui ? '. Estás aquí' : ''}`}
      style={[estilos.paso, { backgroundColor: fondo }]}
    >
      <Texto variante="headlineLg" fuente="poppins" color={texto} style={estilos.numero}>
        {nivel}
      </Texto>
      <View style={estilos.textos}>
        <Texto variante="labelLg" color={texto}>
          {ETIQUETA_TIPO_RECORDATORIO[tipo]}
        </Texto>
        {conDetalle ? (
          <Texto variante="bodyMd" color={texto}>
            {DETALLE_TIPO_RECORDATORIO[tipo]}
          </Texto>
        ) : null}
      </View>
      {estasAqui ? (
        <View style={estilos.insignia}>
          <Texto variante="label" color={colors.header}>
            Estás aquí
          </Texto>
        </View>
      ) : null}
    </View>
  );
}

// Escalera completa de la pantalla 09: de mayor presión (arriba) a menor.
export function EscaleraAvisos({ actual }: { actual: TipoRecordatorio | null }) {
  return (
    <View style={estilos.escalera}>
      {[...TIPOS_RECORDATORIO].reverse().map((tipo) => (
        <PasoAviso key={tipo} tipo={tipo} conDetalle estasAqui={tipo === actual} />
      ))}
    </View>
  );
}

const estilos = StyleSheet.create({
  escalera: { gap: spacing.ladder },
  paso: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    minHeight: sizes.noticeStep,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.md,
  },
  numero: { width: sizes.ladderNumber },
  textos: { flex: 1 },
  insignia: {
    height: sizes.badge,
    paddingHorizontal: spacing.blockDense,
    justifyContent: 'center',
    borderRadius: radius.full,
    backgroundColor: colors.backgroundPink,
  },
});
