import { colors, spacing } from '@almira/shared';
import type { ReactNode } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

type Props = {
  children: ReactNode;
  encabezado?: ReactNode;
  pie?: ReactNode;
  // Dentro de las pestañas, la barra inferior ya cubre el área segura.
  conPestanas?: boolean;
  // El encabezado (por ejemplo, BarraSuperior) pinta el área de la hora y la batería.
  encabezadoHastaArriba?: boolean;
  separacion?: keyof typeof spacing;
};

export function Pantalla({
  children,
  encabezado,
  pie,
  conPestanas,
  encabezadoHastaArriba,
  separacion = 'xl',
}: Props) {
  const { top, bottom } = useSafeAreaInsets();
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
    gap: spacing.md,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
});
