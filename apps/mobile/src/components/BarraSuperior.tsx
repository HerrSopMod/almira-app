import { colors, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Pressable, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Texto } from './Texto';

type Props = {
  titulo: string;
  conVolver?: boolean;
};

// Barra vino de las pantallas del prototipo: título centrado en Poppins y botón de volver.
// Úsala con <Pantalla encabezadoHastaArriba> para que también pinte el área de la hora.
export function BarraSuperior({ titulo, conVolver = true }: Props) {
  const { top } = useSafeAreaInsets();
  return (
    <View style={[estilos.raiz, { paddingTop: top }]}>
      <StatusBar style="light" />
      <View style={estilos.fila}>
        <Texto
          variante="headlineSm"
          fuente="poppins"
          color={colors.onPrimary}
          alineacion="center"
          accessibilityRole="header"
          numberOfLines={1}
          style={estilos.titulo}
        >
          {titulo}
        </Texto>
        {conVolver ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Volver"
            hitSlop={8}
            onPress={() => router.back()}
            style={estilos.volver}
          >
            <MaterialIcons name="chevron-left" size={32} color={colors.onPrimary} />
          </Pressable>
        ) : null}
      </View>
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: { backgroundColor: colors.header },
  fila: { height: sizes.headerBar, justifyContent: 'center' },
  titulo: { marginHorizontal: sizes.headerBar },
  volver: {
    position: 'absolute',
    left: spacing.sm,
    width: sizes.buttonTertiary,
    height: sizes.buttonTertiary,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
