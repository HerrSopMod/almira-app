import { colors, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { Fragment } from 'react';
import { Pressable, StyleSheet } from 'react-native';
import { CajaIcono, Separador, Tarjeta, type NombreIcono } from './Bloques';
import { Texto } from './Texto';

export type OpcionMenu = {
  titulo: string;
  icono: NombreIcono;
  onPress: () => void;
};

// Una tarjeta con filas de ícono, título y flecha (pantallas 21 y 22).
export function Menu({ opciones }: { opciones: OpcionMenu[] }) {
  return (
    <Tarjeta>
      {opciones.map(({ titulo, icono, onPress }, indice) => (
        <Fragment key={titulo}>
          {indice > 0 ? <Separador /> : null}
          <Pressable accessibilityRole="button" onPress={onPress} style={estilos.fila}>
            <CajaIcono icono={icono} />
            <Texto variante="bodyLgMedium" style={estilos.flexible}>
              {titulo}
            </Texto>
            <MaterialIcons name="chevron-right" size={sizes.icon} color={colors.textSecondary} />
          </Pressable>
        </Fragment>
      ))}
    </Tarjeta>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  flexible: { flex: 1 },
});
