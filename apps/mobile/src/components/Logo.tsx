import { colors, radius, sizes } from '@almira/shared';
import { StyleSheet, Text, View } from 'react-native';
import { familiaInter } from './Texto';

// Logo de Almira (LEEME.md → Marca): cuadrado primario con una "a" blanca en Inter 700.
// Es una imagen de marca, así que no crece con "Texto más grande".
export function Logo({ grande }: { grande?: boolean }) {
  const lado = grande ? sizes.logoLg : sizes.logo;
  return (
    <View
      accessible
      accessibilityRole="image"
      accessibilityLabel="Almira"
      style={[
        estilos.logo,
        { width: lado, height: lado, borderRadius: grande ? radius.logoLg : radius.logo },
      ]}
    >
      <Text style={[estilos.letra, { fontSize: lado * 0.6, lineHeight: lado }]}>a</Text>
    </View>
  );
}

const estilos = StyleSheet.create({
  logo: { alignItems: 'center', justifyContent: 'center', backgroundColor: colors.primary },
  letra: { color: colors.onPrimary, fontFamily: familiaInter('700') },
});
