import { colors, sizes, spacing } from '@almira/shared';
import type { ReactNode } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

type Props = {
  children: ReactNode;
  encabezado?: ReactNode;
  pie?: ReactNode;
  // Dentro de las pestañas, la barra inferior ya cubre el área segura.
  conPestanas?: boolean;
  // El encabezado (por ejemplo, BarraSuperior) cubre el área de la hora y la batería.
  encabezadoHastaArriba?: boolean;
  // 16 px entre bloques; 12 px (blockDense) en listas densas.
  separacion?: keyof typeof spacing;
};

// Fondo blanco y márgenes laterales de 20 px.
export function Pantalla({
  children,
  encabezado,
  pie,
  conPestanas,
  encabezadoHastaArriba,
  separacion = 'block',
}: Props) {
  const { top, bottom } = useSafeAreaInsets();
  // La barra inferior de expo-router no flota: el contenido termina sobre ella, así
  // que basta con los 20 px finales.
  const margenInferior = conPestanas ? 0 : bottom;
  return (
    <View style={[estilos.raiz, { paddingTop: encabezadoHastaArriba ? 0 : top }]}>
      {encabezado}
      <ScrollView
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={[
          estilos.contenido,
          { gap: spacing[separacion], paddingBottom: spacing.lg + (pie ? 0 : margenInferior) },
        ]}
      >
        {children}
      </ScrollView>
      {pie ? (
        <View style={[estilos.pie, { paddingBottom: spacing.md + margenInferior }]}>{pie}</View>
      ) : null}
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: { flex: 1, backgroundColor: colors.background },
  contenido: {
    paddingHorizontal: spacing.margin,
    paddingTop: spacing.md,
  },
  pie: {
    paddingHorizontal: spacing.margin,
    paddingTop: spacing.md,
    gap: spacing.sm,
    borderTopWidth: sizes.borderWidth,
    borderTopColor: colors.border,
    backgroundColor: colors.background,
  },
});
