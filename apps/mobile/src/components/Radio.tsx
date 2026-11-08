import { colors, sizes } from '@almira/shared';
import { StyleSheet, View } from 'react-native';

// Radio de la guía de estilos (pantallas 07 y 09). Solo dibuja: la fila que lo
// contiene lleva accessibilityRole="radio" y el onPress.
export function Radio({ marcado }: { marcado: boolean }) {
  return (
    <View style={[estilos.radio, marcado && estilos.marcado]}>
      {marcado ? <View style={estilos.punto} /> : null}
    </View>
  );
}

const estilos = StyleSheet.create({
  radio: {
    width: sizes.radio,
    height: sizes.radio,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: sizes.radio / 2,
    borderWidth: sizes.focusBorderWidth,
    borderColor: colors.radioOff,
  },
  marcado: { borderColor: colors.primary },
  punto: {
    width: sizes.radio / 2,
    height: sizes.radio / 2,
    borderRadius: sizes.radio / 4,
    backgroundColor: colors.primary,
  },
});
