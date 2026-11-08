import { colors, radius, sizes, spacing, type Obra } from '@almira/shared';
import { router } from 'expo-router';
import { Pressable, StyleSheet, View, type DimensionValue } from 'react-native';
import { Texto } from './Texto';

// Puestos fijos de los marcadores en el dibujo (fracciones del ancho y del alto),
// medidos en la pantalla 19. Las obras no tienen coordenadas: se ubican en orden.
const PUESTOS = [
  { x: 0.3, y: 0.32 },
  { x: 0.62, y: 0.55 },
  { x: 0.24, y: 0.76 },
  { x: 0.82, y: 0.2 },
  { x: 0.5, y: 0.86 },
];

const TERCIO = 100 / 3;
const CELDAS = [0, 1, 2].flatMap((fila) => [0, 1, 2].map((columna) => ({ fila, columna })));
// La manzana verde es un parque, como en el prototipo.
const PARQUE = { fila: 1, columna: 2 };
const porcentaje = (valor: number) => `${valor}%` as DimensionValue;

// Mapa de la pantalla 19: es un dibujo fijo, no un mapa real.
export function MapaObras({ obras }: { obras: Obra[] }) {
  return (
    <View style={estilos.mapa}>
      {CELDAS.map(({ fila, columna }) => (
        <View
          key={`${fila}-${columna}`}
          style={[
            estilos.celda,
            { top: porcentaje(fila * TERCIO), left: porcentaje(columna * TERCIO) },
          ]}
        >
          <View
            style={[
              estilos.manzana,
              fila === PARQUE.fila && columna === PARQUE.columna && estilos.parque,
            ]}
          />
        </View>
      ))}
      {[1, 2].map((corte) => (
        <View key={`v${corte}`} style={[estilos.calleVertical, { left: porcentaje(corte * TERCIO) }]} />
      ))}
      {[1, 2].map((corte) => (
        <View key={`h${corte}`} style={[estilos.calleHorizontal, { top: porcentaje(corte * TERCIO) }]} />
      ))}
      <View style={estilos.avenida} />

      {obras.slice(0, PUESTOS.length).map((obra, indice) => {
        const puesto = PUESTOS[indice]!;
        const concluida = obra.estado === 'finalizada';
        return (
          <Pressable
            key={obra.id}
            accessibilityRole="button"
            accessibilityLabel={`${obra.nombre}: ${obra.avancePct} % de avance`}
            onPress={() => router.push({ pathname: '/obras/[id]', params: { id: obra.id } })}
            hitSlop={8}
            style={[
              estilos.marcador,
              {
                left: porcentaje(puesto.x * 100),
                top: puesto.y * sizes.mapHeight - sizes.mapMarker / 2,
                backgroundColor: concluida ? colors.paid : colors.primary,
              },
            ]}
          >
            <Texto variante="labelSm" color={colors.onPrimary}>
              {obra.avancePct}
            </Texto>
          </Pressable>
        );
      })}

      <View style={estilos.etiqueta}>
        <Texto variante="caption" color={colors.textSecondary}>
          Mapa ilustrativo
        </Texto>
      </View>
    </View>
  );
}

const estilos = StyleSheet.create({
  mapa: { height: sizes.mapHeight, overflow: 'hidden', backgroundColor: colors.neutral },
  celda: {
    position: 'absolute',
    width: porcentaje(TERCIO),
    height: porcentaje(TERCIO),
    padding: spacing.block,
  },
  manzana: { flex: 1, borderRadius: radius.md, backgroundColor: colors.drawingBlock },
  parque: { backgroundColor: colors.drawingPark },
  calleVertical: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    width: sizes.mapStreet,
    marginLeft: -sizes.mapStreet / 2,
    backgroundColor: colors.surface,
  },
  calleHorizontal: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: sizes.mapStreet,
    marginTop: -sizes.mapStreet / 2,
    backgroundColor: colors.surface,
  },
  // Avenida en diagonal, de abajo a la izquierda hacia arriba a la derecha.
  avenida: {
    position: 'absolute',
    left: '-10%',
    width: '120%',
    top: sizes.mapHeight / 2,
    height: sizes.mapAvenue,
    backgroundColor: colors.drawingAvenue,
    transform: [{ rotate: '-29deg' }],
  },
  marcador: {
    position: 'absolute',
    width: sizes.mapMarker,
    height: sizes.mapMarker,
    marginLeft: -sizes.mapMarker / 2,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: sizes.mapMarker / 2,
    borderWidth: sizes.mapMarkerBorder,
    borderColor: colors.surface,
  },
  etiqueta: {
    position: 'absolute',
    top: spacing.sm,
    left: spacing.sm,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs / 2,
    borderRadius: radius.full,
    backgroundColor: colors.surface,
  },
});
