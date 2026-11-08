import { colors, radius, sizes, spacing } from '@almira/shared';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Casilla } from './Casilla';
import { Radio } from './Radio';
import { Texto } from './Texto';

type Props = {
  titulo: string;
  detalle?: string;
  seleccionada: boolean;
  onPress: () => void;
  multiple?: boolean;
  extra?: ReactNode;
};

// Fila elegible con radio (o casilla si se pueden marcar varias). La elegida lleva
// borde primario de 1.5 px.
export function Opcion({ titulo, detalle, seleccionada, onPress, multiple, extra }: Props) {
  return (
    <Pressable
      accessibilityRole={multiple ? 'checkbox' : 'radio'}
      accessibilityState={{ checked: seleccionada }}
      onPress={onPress}
      style={[estilos.opcion, seleccionada && estilos.seleccionada]}
    >
      {multiple ? <Casilla marcada={seleccionada} /> : <Radio marcado={seleccionada} />}
      <View style={estilos.textos}>
        <Texto variante="bodyLgMedium">{titulo}</Texto>
        {detalle ? (
          <Texto variante="bodyMd" color={colors.textSecondary}>
            {detalle}
          </Texto>
        ) : null}
      </View>
      {extra}
    </Pressable>
  );
}

const estilos = StyleSheet.create({
  opcion: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.blockDense,
    minHeight: sizes.button,
    padding: spacing.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  seleccionada: { borderWidth: sizes.focusBorderWidth, borderColor: colors.primary },
  textos: { flex: 1 },
});
