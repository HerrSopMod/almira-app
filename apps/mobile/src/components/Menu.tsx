import { colors, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { Fragment } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Separador, Tarjeta, type NombreIcono } from './Bloques';
import { Texto } from './Texto';

export type OpcionMenu = {
  titulo: string;
  icono: NombreIcono;
  onPress: () => void;
  // Texto de apoyo bajo el título, como el nombre de la municipalidad.
  detalle?: string;
};

// Una tarjeta con filas de ícono, título y flecha (pantallas 21 y 22).
export function Menu({ opciones }: { opciones: OpcionMenu[] }) {
  return (
    <Tarjeta>
      {opciones.map(({ titulo, icono, onPress, detalle }, indice) => (
        <Fragment key={titulo}>
          {indice > 0 ? <Separador /> : null}
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={detalle ? `${titulo}. ${detalle}` : titulo}
            onPress={onPress}
            style={estilos.fila}
          >
            <MaterialIcons name={icono} size={sizes.icon} color={colors.primary} />
            <View style={estilos.flexible}>
              <Texto variante="bodyLgMedium">{titulo}</Texto>
              {detalle ? (
                <Texto variante="bodyMd" color={colors.textSecondary}>
                  {detalle}
                </Texto>
              ) : null}
            </View>
            <MaterialIcons name="chevron-right" size={sizes.icon} color={colors.textSecondary} />
          </Pressable>
        </Fragment>
      ))}
    </Tarjeta>
  );
}

const estilos = StyleSheet.create({
  fila: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    minHeight: sizes.buttonTertiary,
  },
  flexible: { flex: 1 },
});
