import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

type Props = {
  titulo: string;
  detalle?: string;
  seleccionada: boolean;
  onPress: () => void;
  multiple?: boolean;
  extra?: ReactNode;
};

export function Opcion({ titulo, detalle, seleccionada, onPress, multiple, extra }: Props) {
  const icono = multiple
    ? seleccionada
      ? 'check-box'
      : 'check-box-outline-blank'
    : seleccionada
      ? 'radio-button-checked'
      : 'radio-button-unchecked';
  return (
    <Pressable
      accessibilityRole={multiple ? 'checkbox' : 'radio'}
      accessibilityState={{ checked: seleccionada }}
      onPress={onPress}
      style={[estilos.opcion, seleccionada && estilos.seleccionada]}
    >
      <MaterialIcons
        name={icono}
        size={24}
        color={seleccionada ? colors.primary : colors.textSecondary}
      />
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
    gap: spacing.md,
    minHeight: sizes.button,
    padding: spacing.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  seleccionada: { borderWidth: sizes.focusBorderWidth, borderColor: colors.primary },
  textos: { flex: 1 },
});
