import { colors, radius, sizes, spacing } from '@almira/shared';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { CajaIcono, type NombreIcono } from './Bloques';
import { Casilla } from './Casilla';
import { Radio } from './Radio';
import { Texto } from './Texto';

type Props = {
  titulo: string;
  detalle?: string;
  seleccionada: boolean;
  onPress: () => void;
  multiple?: boolean;
  extra?: ReactNode;
  // Con ícono, la caja de ícono va a la izquierda y el radio o la casilla a la derecha.
  icono?: NombreIcono;
};

// Fila elegible con radio (o casilla si se pueden marcar varias). La elegida lleva
// borde primario de 1.5 px.
export function Opcion({ titulo, detalle, seleccionada, onPress, multiple, extra, icono }: Props) {
  const control = multiple ? <Casilla marcada={seleccionada} /> : <Radio marcado={seleccionada} />;
  return (
    <Pressable
      accessibilityRole={multiple ? 'checkbox' : 'radio'}
      accessibilityState={{ checked: seleccionada }}
      onPress={onPress}
      style={[estilos.opcion, seleccionada && estilos.seleccionada]}
    >
      {icono ? <CajaIcono icono={icono} /> : control}
      <View style={estilos.textos}>
        <Texto variante="bodyLgMedium">{titulo}</Texto>
        {detalle ? (
          <Texto variante="bodyMd" color={colors.textSecondary}>
            {detalle}
          </Texto>
        ) : null}
      </View>
      {extra}
      {icono ? control : null}
    </Pressable>
  );
}

const estilos = StyleSheet.create({
  opcion: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.blockDense,
    minHeight: sizes.button,
    padding: spacing.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  seleccionada: { borderWidth: sizes.focusBorderWidth, borderColor: colors.primary },
  textos: { flex: 1 },
});
