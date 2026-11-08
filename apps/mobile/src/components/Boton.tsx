import { colors, radius, sizes } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { Pressable, StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

type Props = {
  titulo: string;
  onPress: () => void;
  tipo?: 'primario' | 'secundario' | 'linea' | 'terciario';
  icono?: keyof typeof MaterialIcons.glyphMap;
  deshabilitado?: boolean;
};

// Ocupa todo el ancho disponible: los márgenes de 20 px los pone Pantalla.
export function Boton({ titulo, onPress, tipo = 'primario', icono, deshabilitado }: Props) {
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
        tipo === 'linea' && estilos.linea,
        tipo === 'terciario' && estilos.terciario,
        deshabilitado && estilos.deshabilitado,
      ]}
    >
      <View style={estilos.contenido}>
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
  // Las pantallas 06 y 08 usan el rosado más claro para el botón secundario.
  secundario: { backgroundColor: colors.backgroundPinkSoft },
  linea: {
    backgroundColor: colors.surface,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
  },
  terciario: { height: sizes.buttonTertiary },
  deshabilitado: { opacity: 0.5 },
  contenido: { flexDirection: 'row', alignItems: 'center', gap: 8 },
});
