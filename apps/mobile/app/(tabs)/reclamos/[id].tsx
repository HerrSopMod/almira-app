import {
  colors,
  formatearFechaCorta,
  HOY_EJEMPLO,
  pasosSeguimiento,
  plazoReclamo,
  sizes,
  spacing,
  type PasoSeguimiento,
} from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { ChipPlazo, PiePrototipo, Progreso, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { FotoSimulada } from '@/components/FotoSimulada';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 18 del prototipo. El estado del reclamo lo cambia la municipalidad.
export default function Seguimiento() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { reclamos } = useDatosMunicipales();
  const reclamo = reclamos.find((fila) => fila.id === id);
  const encabezado = <BarraSuperior titulo="Seguimiento" />;

  if (!reclamo) {
    return (
      <Pantalla conPestanas encabezadoHastaArriba encabezado={encabezado}>
        <Vacio texto="No encontramos este reclamo en tu municipalidad." />
      </Pantalla>
    );
  }

  const resuelto = reclamo.estado === 'resuelto';
  const plazo = plazoReclamo(reclamo, HOY_EJEMPLO);
  const lugarYFecha = [reclamo.direccion, formatearFechaCorta(reclamo.creadoEn)]
    .filter(Boolean)
    .join(' · ');

  return (
    <Pantalla conPestanas encabezadoHastaArriba separacion="block" encabezado={encabezado}>
      <View style={estilos.fila}>
        <Texto variante="labelLg" style={estilos.flexible}>
          {reclamo.codigo}
        </Texto>
        {resuelto ? (
          <ChipPlazo texto="Resuelto" tono="pagado" />
        ) : plazo ? (
          <ChipPlazo texto={plazo.etiqueta} />
        ) : null}
      </View>

      <FotoSimulada tipo={reclamo.tipo} />

      <Tarjeta>
        <View style={estilos.textos}>
          <Texto variante="headlineSm">{reclamo.titulo}</Texto>
          <Texto variante="bodyMd" color={colors.textSecondary}>
            {lugarYFecha}
          </Texto>
          {reclamo.descripcion ? (
            <Texto color={colors.textSecondary} style={estilos.descripcion}>
              {reclamo.descripcion}
            </Texto>
          ) : null}
        </View>
      </Tarjeta>

      {plazo?.total && plazo.quedan !== null ? (
        <Tarjeta>
          <View style={estilos.fila}>
            <Texto variante="labelLg" style={estilos.flexible}>
              Plazo de {reclamo.area ?? 'la municipalidad'}
            </Texto>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              {plazo.quedan} de {plazo.total} días
            </Texto>
          </View>
          <Progreso porcentaje={((plazo.total - plazo.quedan) / plazo.total) * 100} />
        </Tarjeta>
      ) : null}

      <Tarjeta>
        <Texto variante="labelLg">Seguimiento</Texto>
        <View>
          {pasosSeguimiento(reclamo.estado).map((paso, indice, pasos) => (
            <Paso
              key={paso.titulo}
              paso={paso}
              ultimo={indice === pasos.length - 1}
              detalle={
                paso.titulo === 'Derivado al área' && reclamo.area ? `Área: ${reclamo.area}` : null
              }
            />
          ))}
        </View>
      </Tarjeta>

      <Boton
        tipo="secundario"
        titulo="Hablar con una persona"
        onPress={() => router.push('/atencion-humana')}
      />
      <PiePrototipo />
    </Pantalla>
  );
}

const ETIQUETA_PASO: Record<PasoSeguimiento['estado'], string> = {
  hecho: 'hecho',
  actual: 'en curso',
  pendiente: 'pendiente',
};

function Paso({
  paso,
  ultimo,
  detalle,
}: {
  paso: PasoSeguimiento;
  ultimo: boolean;
  detalle: string | null;
}) {
  return (
    <View
      accessible
      accessibilityLabel={`${paso.titulo}${detalle ? `, ${detalle}` : ''}: ${ETIQUETA_PASO[paso.estado]}`}
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
            <MaterialCommunityIcons name="check" size={14} color={colors.onPrimary} />
          ) : null}
        </View>
        {!ultimo ? (
          <View style={[estilos.linea, paso.estado === 'hecho' && estilos.lineaHecha]} />
        ) : null}
      </View>
      <View style={estilos.flexible}>
        <Texto
          variante="labelLg"
          color={paso.estado === 'pendiente' ? colors.textSecondary : colors.text}
        >
          {paso.titulo}
        </Texto>
        {detalle ? (
          <Texto variante="bodyMd" color={colors.textSecondary}>
            {detalle}
          </Texto>
        ) : null}
      </View>
    </View>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  flexible: { flex: 1 },
  textos: { gap: spacing.xs },
  descripcion: { marginTop: spacing.xs },
  paso: { flexDirection: 'row', gap: spacing.md },
  pasoConLinea: { minHeight: sizes.timelineStep },
  columna: { width: sizes.timelineDot, alignItems: 'center' },
  punto: {
    width: sizes.timelineDot,
    height: sizes.timelineDot,
    borderRadius: sizes.timelineDot / 2,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.neutral,
  },
  puntoHecho: { backgroundColor: colors.paid },
  puntoActual: { backgroundColor: colors.primary },
  linea: { flex: 1, width: sizes.timelineLine, backgroundColor: colors.neutral },
  lineaHecha: { backgroundColor: colors.paid },
});
