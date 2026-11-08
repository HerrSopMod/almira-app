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
import { Insignia } from './Bloques';
import { Texto } from './Texto';

// Color de cada paso (LEEME.md → Color): 1 turquesa, 2 ámbar y 3 rojo.
const COLORES_PASO: Record<TipoRecordatorio, { fondo: string; texto: string }> = {
  preventivo: { fondo: colors.highlight, texto: colors.primaryPressed },
  mora: { fondo: colors.warningSoft, texto: colors.warningText },
  previo_coactiva: { fondo: colors.dangerSoft, texto: colors.dangerText },
};

type PropsPaso = {
  tipo: TipoRecordatorio;
  conDetalle?: boolean;
  estasAqui?: boolean;
};

// Un paso de la escalera de avisos. En el detalle del aviso (pantalla 10) va solo.
// El paso actual lleva borde primario de 1.5 px y el rótulo "Estás aquí".
export function PasoAviso({ tipo, conDetalle, estasAqui }: PropsPaso) {
  const { fondo, texto } = COLORES_PASO[tipo];
  const nivel = NIVEL_TIPO_RECORDATORIO[tipo];
  return (
    <View
      accessible
      accessibilityLabel={`Paso ${nivel}: ${ETIQUETA_TIPO_RECORDATORIO[tipo]}${
        conDetalle ? `. ${DETALLE_TIPO_RECORDATORIO[tipo]}` : ''
      }${estasAqui ? '. Estás aquí' : ''}`}
      style={[estilos.paso, estasAqui && estilos.pasoActual]}
    >
      <View style={[estilos.numero, { backgroundColor: fondo }]}>
        <Texto variante="bodyMd" peso="700" color={texto}>
          {nivel}
        </Texto>
      </View>
      <View style={estilos.textos}>
        <Texto variante="bodyLgMedium">{ETIQUETA_TIPO_RECORDATORIO[tipo]}</Texto>
        {conDetalle ? (
          <Texto variante="bodyMd" color={colors.textSecondary}>
            {DETALLE_TIPO_RECORDATORIO[tipo]}
          </Texto>
        ) : null}
      </View>
      {estasAqui ? <Insignia texto="Estás aquí" tono="info" /> : null}
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
    gap: spacing.blockDense,
    paddingHorizontal: spacing.blockDense,
    paddingVertical: spacing.blockDense,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  pasoActual: { borderWidth: sizes.focusBorderWidth, borderColor: colors.primary },
  numero: {
    width: sizes.ladderNumber,
    height: sizes.ladderNumber,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.navItem,
  },
  textos: { flex: 1 },
});
