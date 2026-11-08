import { colors, radius, sizes, spacing } from '@almira/shared';
import { Pressable, StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

type Props<T extends string> = {
  opciones: { valor: T; titulo: string }[];
  elegida: T;
  onElegir: (valor: T) => void;
};

// Chips de una sola elección (pantallas 11, 13 y 17): el activo va relleno de
// primario y los demás con borde primario.
export function Chips<T extends string>({ opciones, elegida, onElegir }: Props<T>) {
  return (
    <View accessibilityRole="tablist" style={estilos.chips}>
      {opciones.map(({ valor, titulo }) => {
        const activo = valor === elegida;
        return (
          <Pressable
            key={valor}
            accessibilityRole="tab"
            accessibilityState={{ selected: activo }}
            onPress={() => onElegir(valor)}
            style={[estilos.chip, activo && estilos.chipActivo]}
          >
            <Texto variante="label" color={activo ? colors.onPrimary : colors.primary}>
              {titulo}
            </Texto>
          </Pressable>
        );
      })}
    </View>
  );
}

const estilos = StyleSheet.create({
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  chip: {
    height: sizes.chip,
    justifyContent: 'center',
    paddingHorizontal: spacing.md,
    borderRadius: radius.full,
    borderWidth: sizes.borderWidth,
    borderColor: colors.primary,
    backgroundColor: colors.surface,
  },
  chipActivo: { backgroundColor: colors.primary },
});
