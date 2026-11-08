import {
  colors,
  ETIQUETA_ESTADO_OBRA,
  formatearFechaCorta,
  formatearSoles,
  haceDias,
  HOY_EJEMPLO,
  radius,
  sizes,
  spacing,
} from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import {
  ChipPlazo,
  Destacado,
  FilaDato,
  PiePrototipo,
  Progreso,
  Separador,
  Tarjeta,
  Vacio,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { FotoSimulada } from '@/components/FotoSimulada';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 20 del prototipo. No hay fotos publicadas: se muestra una imagen ilustrativa.
export default function DetalleObra() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { obras } = useDatosMunicipales();
  const obra = obras.find((fila) => fila.id === id);
  const encabezado = <BarraSuperior titulo="Detalle de la obra" />;

  if (!obra) {
    return (
      <Pantalla conPestanas encabezadoHastaArriba encabezado={encabezado}>
        <Vacio texto="No encontramos esta obra en tu municipalidad." />
      </Pantalla>
    );
  }

  const concluida = obra.estado === 'finalizada';
  const tributos = obra.porcentajeTributos;
  const hitos = [
    ...(obra.inicio ? [`Inicio: ${formatearFechaCorta(obra.inicio)}`] : []),
    ...obra.hitos,
  ];

  return (
    <Pantalla conPestanas encabezadoHastaArriba separacion="block" encabezado={encabezado}>
      <FotoSimulada tipo="obra" etiqueta="Imagen ilustrativa" alto={sizes.workPhoto} />

      <Tarjeta>
        <View style={estilos.filaArriba}>
          <View style={estilos.flexible}>
            <Texto variante="headlineSm">{obra.nombre}</Texto>
            <Texto color={colors.textSecondary}>{obra.ubicacion}</Texto>
          </View>
          <ChipPlazo texto={ETIQUETA_ESTADO_OBRA[obra.estado]} tono={concluida ? 'pagado' : 'rosado'} />
        </View>
        <View style={estilos.grupo}>
          <View style={estilos.fila}>
            <Texto color={colors.textSecondary} style={estilos.flexible}>
              Avance físico
            </Texto>
            <Texto variante="labelLg" tabular>
              {obra.avancePct} %
            </Texto>
          </View>
          <Progreso porcentaje={obra.avancePct} tono={concluida ? 'pagado' : 'primario'} />
          <Texto variante="bodyMd" color={colors.textSecondary}>
            {concluida ? 'Entregada' : 'Entrega prevista'}: {obra.meta} · Actualizada{' '}
            {haceDias(obra.actualizadaEn, HOY_EJEMPLO)}
          </Texto>
        </View>
      </Tarjeta>

      <Tarjeta>
        {tributos !== null ? (
          <>
            <Texto variante="labelLg">De dónde sale el dinero</Texto>
            <View style={estilos.grupo}>
              <View style={estilos.barra}>
                <View style={{ flex: tributos, backgroundColor: colors.primary }} />
                <View style={{ flex: 100 - tributos, backgroundColor: colors.chartSecondary }} />
              </View>
              <View style={estilos.leyenda}>
                <Leyenda color={colors.primary} texto={`Tributos del distrito ${tributos} %`} />
                <Leyenda color={colors.chartSecondary} texto={`Transferencias ${100 - tributos} %`} />
              </View>
            </View>
            <Separador />
          </>
        ) : null}
        <View style={estilos.grupo}>
          <FilaDato etiqueta="Presupuesto" valor={<Valor monto={obra.montoAsignado} />} />
          <FilaDato etiqueta="Gastado a la fecha" valor={<Valor monto={obra.montoEjecutado} />} />
        </View>
      </Tarjeta>

      {hitos.length > 0 ? (
        <Tarjeta>
          <Texto variante="labelLg">Hitos</Texto>
          <View style={estilos.grupo}>
            {hitos.map((hito) => (
              <View key={hito} style={estilos.fila}>
                <MaterialCommunityIcons name="check" size={20} color={colors.textSecondary} />
                <Texto color={colors.textSecondary} style={estilos.flexible}>
                  {hito}
                </Texto>
              </View>
            ))}
          </View>
        </Tarjeta>
      ) : null}

      <Destacado
        tono="informacion"
        texto="La obra la ejecuta la municipalidad. Almira publica el avance que ella registra."
      />
      <Boton
        tipo="secundario"
        titulo="¿Ves un problema? Repórtalo"
        onPress={() => router.push('/reclamo/nuevo')}
      />
      <PiePrototipo />
    </Pantalla>
  );
}

function Leyenda({ color, texto }: { color: string; texto: string }) {
  return (
    <View style={estilos.fila}>
      <View style={[estilos.cuadro, { backgroundColor: color }]} />
      <Texto variante="bodyMd" color={colors.textSecondary}>
        {texto}
      </Texto>
    </View>
  );
}

function Valor({ monto }: { monto: number }) {
  return (
    <Texto variante="labelLg" alineacion="right" tabular>
      {formatearSoles(monto)}
    </Texto>
  );
}

const estilos = StyleSheet.create({
  filaArriba: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.sm },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  flexible: { flex: 1 },
  grupo: { gap: spacing.sm },
  barra: {
    flexDirection: 'row',
    gap: spacing.xs / 2,
    height: sizes.fundingBar,
    borderRadius: radius.sm,
    overflow: 'hidden',
  },
  leyenda: { flexDirection: 'row', flexWrap: 'wrap', columnGap: spacing.md, rowGap: spacing.xs },
  cuadro: { width: sizes.legendDot, height: sizes.legendDot, borderRadius: radius.sm / 2 },
});
