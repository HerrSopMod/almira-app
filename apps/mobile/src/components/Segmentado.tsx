import { colors, radius, sizes, spacing } from '@almira/shared';
import { Pressable, StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

type Props<T extends string> = {
  opciones: { valor: T; titulo: string }[];
  elegida: T;
  onElegir: (valor: T) => void;
};

// Control segmentado (LEEME.md): fondo suave y la opción activa en blanco con borde.
export function Segmentado<T extends string>({ opciones, elegida, onElegir }: Props<T>) {
  return (
    <View accessibilityRole="tablist" style={estilos.raiz}>
      {opciones.map(({ valor, titulo }) => {
        const activa = valor === elegida;
        return (
          <Pressable
            key={valor}
            accessibilityRole="tab"
            accessibilityState={{ selected: activa }}
            onPress={() => onElegir(valor)}
            style={[estilos.opcion, activa && estilos.activa]}
          >
            <Texto
              variante="bodyMdMedium"
              peso={activa ? '600' : '500'}
              color={activa ? colors.primary : colors.textSecondary}
              alineacion="center"
            >
              {titulo}
            </Texto>
          </Pressable>
        );
      })}
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: {
    flexDirection: 'row',
    gap: spacing.xs,
    padding: spacing.xs,
    borderRadius: radius.md,
    backgroundColor: colors.subtle,
  },
  opcion: {
    flex: 1,
    minHeight: sizes.segment,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.sm,
    // Esquinas concéntricas con las del fondo.
    borderRadius: radius.md - spacing.xs,
    borderWidth: sizes.borderWidth,
    borderColor: 'transparent',
  },
  activa: { backgroundColor: colors.surface, borderColor: colors.border },
});
