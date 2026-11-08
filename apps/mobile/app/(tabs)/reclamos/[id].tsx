import {
  colors,
  formatearFechaCorta,
  HOY_EJEMPLO,
  pasosSeguimiento,
  plazoReclamo,
  spacing,
} from '@almira/shared';
import { router, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { ChipPlazo, PiePrototipo, Avance, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { FotoSimulada } from '@/components/FotoSimulada';
import { LineaTiempo } from '@/components/LineaTiempo';
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
    <Pantalla conPestanas encabezadoHastaArriba separacion="blockDense" encabezado={encabezado}>
      <View style={estilos.fila}>
        <Texto variante="bodyLgMedium" style={estilos.flexible}>
          {reclamo.codigo}
        </Texto>
        {resuelto ? (
          <ChipPlazo texto="Resuelto" tono="resuelto" />
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
            <Texto variante="bodyLgMedium" style={estilos.flexible}>
              Plazo de {reclamo.area ?? 'la municipalidad'}
            </Texto>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              {plazo.quedan} de {plazo.total} días
            </Texto>
          </View>
          <Avance porcentaje={((plazo.total - plazo.quedan) / plazo.total) * 100} />
        </Tarjeta>
      ) : null}

      <Tarjeta>
        <Texto variante="bodyLgMedium">Seguimiento</Texto>
        <LineaTiempo
          pasos={pasosSeguimiento(reclamo.estado).map((paso) => ({
            ...paso,
            detalle:
              paso.titulo === 'Derivado al área' && reclamo.area ? `Área: ${reclamo.area}` : null,
          }))}
        />
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

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  flexible: { flex: 1 },
  textos: { gap: spacing.xs },
  descripcion: { marginTop: spacing.xs },
});
