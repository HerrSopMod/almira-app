import { colors, sizes } from '@almira/shared';
import { StyleSheet, View } from 'react-native';

// Radio de 22 px: borde gris o anillo primario de 6 px. Solo dibuja: la fila que
// lo contiene lleva accessibilityRole="radio" y el onPress.
export function Radio({ marcado }: { marcado: boolean }) {
  return <View style={[estilos.radio, marcado && estilos.marcado]} />;
}

const estilos = StyleSheet.create({
  radio: {
    width: sizes.radio,
    height: sizes.radio,
    borderRadius: sizes.radio / 2,
    borderWidth: sizes.controlBorder,
    borderColor: colors.border,
  },
  marcado: { borderWidth: sizes.ring, borderColor: colors.primary },
});
