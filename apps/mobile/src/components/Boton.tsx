import { colors, radius, sizes } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

type Props = {
  titulo: string;
  onPress: () => void;
  tipo?: 'primario' | 'secundario' | 'terciario' | 'linea';
  izquierda?: ReactNode;
  icono?: keyof typeof MaterialIcons.glyphMap;
  deshabilitado?: boolean;
};

// Ocupa todo el ancho disponible: los márgenes de 20 px los pone Pantalla.
export function Boton({ titulo, onPress, tipo = 'primario', icono, izquierda, deshabilitado }: Props) {
  const colorTexto =
    tipo === 'primario' ? colors.onPrimary : tipo === 'linea' ? colors.text : colors.primary;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: !!deshabilitado }}
      disabled={deshabilitado}
      onPress={onPress}
      style={[
        estilos.base,
        tipo === 'primario' && estilos.primario,
        tipo === 'secundario' && estilos.secundario,
        tipo === 'terciario' && estilos.terciario,
        tipo === 'linea' && estilos.linea,
        deshabilitado && estilos.deshabilitado,
      ]}
    >
      <View style={estilos.contenido}>
        {izquierda}
        {icono ? <MaterialIcons name={icono} size={20} color={colorTexto} /> : null}
        <Texto variante={tipo === 'terciario' ? 'bodyLgMedium' : 'button'} color={colorTexto}>
          {titulo}
        </Texto>
      </View>
    </Pressable>
  );
}

const estilos = StyleSheet.create({
  base: {
    alignSelf: 'stretch',
    height: sizes.button,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primario: { backgroundColor: colors.primary },
  secundario: { backgroundColor: colors.backgroundPink },
  terciario: { height: sizes.buttonTertiary },
  linea: {
    backgroundColor: colors.background,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
  },
  deshabilitado: { opacity: 0.5 },
  contenido: { flexDirection: 'row', alignItems: 'center', gap: 8 },
});
