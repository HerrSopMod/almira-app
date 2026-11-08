import { colors, spacing } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Fragment } from 'react';
import { Pressable, StyleSheet } from 'react-native';
import { IconoCuadro, Separador, Tarjeta } from './Bloques';
import { Texto } from './Texto';

export type OpcionMenu = {
  titulo: string;
  icono: keyof typeof MaterialCommunityIcons.glyphMap;
  onPress: () => void;
};

// Tarjeta con filas de ícono, título y flecha (pantallas 21 y 22).
export function Menu({ opciones }: { opciones: OpcionMenu[] }) {
  return (
    <Tarjeta>
      {opciones.map(({ titulo, icono, onPress }, indice) => (
        <Fragment key={titulo}>
          {indice > 0 ? <Separador /> : null}
          <Pressable accessibilityRole="button" onPress={onPress} style={estilos.fila}>
            <IconoCuadro icono={icono} />
            <Texto variante="labelLg" style={estilos.flexible}>
              {titulo}
            </Texto>
            <MaterialCommunityIcons name="chevron-right" size={24} color={colors.text} />
          </Pressable>
        </Fragment>
      ))}
    </Tarjeta>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  flexible: { flex: 1 },
});
