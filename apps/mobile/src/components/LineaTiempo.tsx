import { colors, sizes, spacing, type PasoSeguimiento } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

export type PasoLinea = PasoSeguimiento & { detalle?: string | null };

const ETIQUETA_ESTADO: Record<PasoSeguimiento['estado'], string> = {
  hecho: 'hecho',
  actual: 'en curso',
  pendiente: 'pendiente',
};

// Línea de tiempo (LEEME.md): puntos de 22 px unidos por un trazo de 2 px.
// Hecho: relleno primario con check. Actual: anillo primario. Pendiente: borde gris.
export function LineaTiempo({ pasos }: { pasos: PasoLinea[] }) {
  return (
    <View>
      {pasos.map((paso, indice) => {
        const ultimo = indice === pasos.length - 1;
        return (
          <View
            key={paso.titulo}
            accessible
            accessibilityLabel={`${paso.titulo}${paso.detalle ? `, ${paso.detalle}` : ''}: ${
              ETIQUETA_ESTADO[paso.estado]
            }`}
            style={[estilos.paso, !ultimo && estilos.pasoConLinea]}
          >
            <View style={estilos.columna}>
              <View
                style={[
                  estilos.punto,
                  paso.estado === 'hecho' && estilos.puntoHecho,
                  paso.estado === 'actual' && estilos.puntoActual,
                ]}
              >
                {paso.estado === 'hecho' ? (
                  <MaterialIcons name="check" size={sizes.iconXs} color={colors.onPrimary} />
                ) : null}
              </View>
              {!ultimo ? (
                <View style={[estilos.linea, paso.estado === 'hecho' && estilos.lineaHecha]} />
              ) : null}
            </View>
            <View style={[estilos.textos, !ultimo && estilos.textosConLinea]}>
              <Texto
                variante="bodyLgMedium"
                color={paso.estado === 'pendiente' ? colors.textSecondary : colors.text}
              >
                {paso.titulo}
              </Texto>
              {paso.detalle ? (
                <Texto variante="bodyMd" color={colors.textSecondary}>
                  {paso.detalle}
                </Texto>
              ) : null}
            </View>
          </View>
        );
      })}
    </View>
  );
}

const estilos = StyleSheet.create({
  paso: { flexDirection: 'row', gap: spacing.blockDense },
  pasoConLinea: { minHeight: sizes.timelineStep },
  columna: { width: sizes.timelineDot, alignItems: 'center' },
  punto: {
    width: sizes.timelineDot,
    height: sizes.timelineDot,
    borderRadius: sizes.timelineDot / 2,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: sizes.controlBorder,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  puntoHecho: { backgroundColor: colors.primary, borderColor: colors.primary },
  puntoActual: { borderWidth: sizes.ring, borderColor: colors.primary },
  linea: { flex: 1, width: sizes.timelineLine, backgroundColor: colors.border },
  lineaHecha: { backgroundColor: colors.primary },
  textos: { flex: 1 },
  textosConLinea: { paddingBottom: spacing.blockDense },
});
