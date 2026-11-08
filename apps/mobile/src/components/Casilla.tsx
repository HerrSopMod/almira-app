import { colors, radius, sizes } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { StyleSheet, View } from 'react-native';

// Casilla de 22 px. Solo dibuja: la fila que la contiene lleva
// accessibilityRole="checkbox" y el onPress.
export function Casilla({ marcada }: { marcada: boolean }) {
  return (
    <View style={[estilos.casilla, marcada && estilos.marcada]}>
      {marcada ? <MaterialIcons name="check" size={sizes.iconXs} color={colors.onPrimary} /> : null}
    </View>
  );
}

const estilos = StyleSheet.create({
  casilla: {
    width: sizes.checkbox,
    height: sizes.checkbox,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.badge,
    borderWidth: sizes.controlBorder,
    borderColor: colors.border,
  },
  marcada: { backgroundColor: colors.primary, borderColor: colors.primary },
});
