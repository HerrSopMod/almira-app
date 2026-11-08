import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { Pressable, StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

type Props = {
  titulo: string;
  onPress: () => void;
  // "contorno": borde y texto primarios, como "Hablar con una persona" (pantalla 12).
  tipo?: 'primario' | 'secundario' | 'linea' | 'contorno' | 'terciario';
  icono?: keyof typeof MaterialIcons.glyphMap;
  deshabilitado?: boolean;
  // Botón bajo de 36 px (pantalla 12).
  compacto?: boolean;
};

// Ocupa todo el ancho disponible: los márgenes de 20 px los pone Pantalla.
export function Boton({
  titulo,
  onPress,
  tipo = 'primario',
  icono,
  deshabilitado,
  compacto,
}: Props) {
  const colorTexto = deshabilitado
    ? colors.textSecondary
    : tipo === 'primario'
      ? colors.onPrimary
      : tipo === 'linea'
        ? colors.text
        : colors.primary;
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
        tipo === 'contorno' && estilos.contorno,
        tipo === 'terciario' && estilos.terciario,
        compacto && estilos.compacto,
        deshabilitado && estilos.deshabilitado,
      ]}
    >
      <View style={estilos.contenido}>
        {icono ? <MaterialIcons name={icono} size={20} color={colorTexto} /> : null}
        <Texto
          variante={compacto ? 'label' : tipo === 'terciario' ? 'bodyLgMedium' : 'button'}
          color={colorTexto}
          numberOfLines={compacto ? 1 : undefined}
          adjustsFontSizeToFit={compacto}
        >
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
  contorno: {
    backgroundColor: colors.surface,
    borderWidth: sizes.focusBorderWidth,
    borderColor: colors.primary,
  },
  terciario: { height: sizes.buttonTertiary },
  compacto: { height: sizes.buttonCompact, paddingHorizontal: spacing.sm },
  // Gris de apoyo con texto secundario, como "Enviar reclamo" sin foto (pantalla 16).
  deshabilitado: { backgroundColor: colors.neutral, borderWidth: 0 },
  contenido: { flexDirection: 'row', alignItems: 'center', gap: 8 },
});
