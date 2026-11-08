import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { Pressable, StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

type PropsChip = {
  titulo: string;
  activo: boolean;
  onPress: () => void;
  conCheck?: boolean;
  // "tab" cuando el chip filtra una vista; "button" para una acción suelta.
  rol?: 'tab' | 'button';
};

// Chip de 36 px (LEEME.md → Chip): el activo va relleno de primario, con check opcional.
export function Chip({ titulo, activo, onPress, conCheck, rol = 'button' }: PropsChip) {
  const color = activo ? colors.onPrimary : colors.text;
  return (
    <Pressable
      accessibilityRole={rol}
      accessibilityState={{ selected: activo }}
      onPress={onPress}
      style={[estilos.chip, activo && estilos.chipActivo]}
    >
      {activo && conCheck ? (
        <MaterialIcons name="check" size={sizes.iconXs} color={color} />
      ) : null}
      <Texto variante="bodyMdMedium" color={color}>
        {titulo}
      </Texto>
    </Pressable>
  );
}

type Props<T extends string> = {
  opciones: { valor: T; titulo: string }[];
  elegida: T;
  onElegir: (valor: T) => void;
};

// Grupo de chips de una sola elección.
export function Chips<T extends string>({ opciones, elegida, onElegir }: Props<T>) {
  return (
    <View accessibilityRole="tablist" style={estilos.chips}>
      {opciones.map(({ valor, titulo }) => (
        <Chip
          key={valor}
          rol="tab"
          titulo={titulo}
          activo={valor === elegida}
          onPress={() => onElegir(valor)}
          conCheck
        />
      ))}
    </View>
  );
}

const estilos = StyleSheet.create({
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    minHeight: sizes.chip,
    paddingHorizontal: spacing.blockDense,
    borderRadius: radius.full,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  chipActivo: { backgroundColor: colors.primary, borderColor: colors.primary },
});
