import { colors, sizes, spacing } from '@almira/shared';
import { Pressable, StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

type Props = {
  activo: boolean;
  onCambiar: (activo: boolean) => void;
  // Con título, se dibuja la fila completa (título, detalle e interruptor) y toda la
  // fila responde al toque. Sin título, pasa accessibilityLabel.
  titulo?: string;
  detalle?: string;
  accessibilityLabel?: string;
};

// Interruptor de 44 × 26 (LEEME.md). Se dibuja aquí porque el Switch del sistema
// no deja fijar su medida.
export function Interruptor({ activo, onCambiar, titulo, detalle, accessibilityLabel }: Props) {
  const control = (
    <View style={[estilos.riel, activo && estilos.rielActivo]}>
      <View style={[estilos.perilla, activo && estilos.perillaActiva]} />
    </View>
  );
  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityLabel={titulo ?? accessibilityLabel}
      accessibilityHint={detalle}
      accessibilityState={{ checked: activo }}
      onPress={() => onCambiar(!activo)}
      style={titulo ? estilos.fila : estilos.solo}
    >
      {titulo ? (
        <View style={estilos.textos}>
          <Texto variante="bodyLgMedium">{titulo}</Texto>
          {detalle ? (
            <Texto variante="bodyMd" color={colors.textSecondary}>
              {detalle}
            </Texto>
          ) : null}
        </View>
      ) : null}
      {control}
    </Pressable>
  );
}

// Separación entre la perilla y el borde del riel.
const HOLGURA = (sizes.switchHeight - sizes.switchKnob) / 2;

const estilos = StyleSheet.create({
  fila: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    minHeight: sizes.buttonTertiary,
  },
  solo: {
    minWidth: sizes.buttonTertiary,
    minHeight: sizes.buttonTertiary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  textos: { flex: 1, gap: spacing.xs },
  riel: {
    width: sizes.switchWidth,
    height: sizes.switchHeight,
    borderRadius: sizes.switchHeight / 2,
    padding: HOLGURA,
    backgroundColor: colors.border,
  },
  rielActivo: { backgroundColor: colors.primary },
  perilla: {
    width: sizes.switchKnob,
    height: sizes.switchKnob,
    borderRadius: sizes.switchKnob / 2,
    backgroundColor: colors.surface,
  },
  perillaActiva: { marginLeft: sizes.switchWidth - sizes.switchKnob - HOLGURA * 2 },
});
