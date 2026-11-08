import {
  colors,
  ETIQUETA_ESTADO_RECLAMO,
  ETIQUETA_TIPO_RECLAMO,
  HOY_EJEMPLO,
  plazoReclamo,
  spacing,
  type Reclamo,
} from '@almira/shared';
import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import {
  ChipPlazo,
  Destacado,
  PiePrototipo,
  Avance,
  Tarjeta,
  Vacio,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 15 del prototipo. Los reclamos nuevos se guardan en memoria y salen primero.
export default function Reclamos() {
  const { vecino, reclamos } = useDatosMunicipales();

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      separacion="blockDense"
      encabezado={<BarraSuperior variante="raiz" titulo="Reclamos" />}
    >
      <Boton
        icono="photo-camera"
        titulo="Nuevo reclamo con foto"
        deshabilitado={!vecino}
        onPress={() => router.push('/reclamo/nuevo')}
      />
      {reclamos.length === 0 ? (
        <Vacio texto="No tienes reclamos en esta municipalidad." />
      ) : (
        reclamos.map((reclamo) => <FilaReclamo key={reclamo.id} reclamo={reclamo} />)
      )}
      <Destacado
        texto="Cada reclamo tiene un área responsable y un plazo. Si se vence, la municipalidad recibe una alerta."
      />
      <PiePrototipo />
    </Pantalla>
  );
}

function FilaReclamo({ reclamo }: { reclamo: Reclamo }) {
  const resuelto = reclamo.estado === 'resuelto';
  const plazo = plazoReclamo(reclamo, HOY_EJEMPLO);
  // La barra muestra cuánto del plazo ya corrió.
  const avance = resuelto
    ? 100
    : plazo?.total
      ? ((plazo.total - (plazo.quedan ?? 0)) / plazo.total) * 100
      : null;

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${reclamo.codigo}, ${reclamo.titulo}. ${ETIQUETA_ESTADO_RECLAMO[reclamo.estado]}`}
      onPress={() => router.push({ pathname: '/reclamos/[id]', params: { id: reclamo.id } })}
    >
      <Tarjeta>
        <View style={estilos.contenido}>
          <View style={estilos.fila}>
            <Texto variante="bodyMd" color={colors.textSecondary} style={estilos.flexible}>
              {reclamo.codigo}
            </Texto>
            {resuelto ? (
              <ChipPlazo texto="Resuelto" tono="resuelto" />
            ) : plazo ? (
              <ChipPlazo texto={plazo.etiqueta} />
            ) : null}
          </View>
          <View>
            <Texto variante="headlineSm">{reclamo.titulo}</Texto>
            <Texto color={colors.textSecondary}>
              {ETIQUETA_TIPO_RECLAMO[reclamo.tipo]}
              {reclamo.area ? ` · ${reclamo.area}` : ''}
            </Texto>
          </View>
          {avance !== null ? (
            <Avance porcentaje={avance} tono={resuelto ? 'concluida' : 'acento'} />
          ) : null}
          <Texto color={colors.textSecondary}>{ETIQUETA_ESTADO_RECLAMO[reclamo.estado]}</Texto>
        </View>
      </Tarjeta>
    </Pressable>
  );
}

const estilos = StyleSheet.create({
  contenido: { gap: spacing.blockDense },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  flexible: { flex: 1 },
});
