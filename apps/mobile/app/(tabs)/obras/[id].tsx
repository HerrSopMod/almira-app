import {
  colors,
  ETIQUETA_ESTADO_OBRA,
  formatearFechaCorta,
  formatearSoles,
  haceDias,
  HOY_EJEMPLO,
  obrasConUbicacion,
  radius,
  sizes,
  spacing,
  type Obra,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router, useLocalSearchParams } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import {
  Avance,
  ChipPlazo,
  FilaDato,
  Nota,
  PiePrototipo,
  Rotulo,
  Separador,
  Tarjeta,
  Vacio,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { FotoSimulada } from '@/components/FotoSimulada';
import { LineaTiempo, type PasoLinea } from '@/components/LineaTiempo';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 20 (maqueta 20-detalle-de-la-obra). No hay fotos publicadas: se muestra una
// imagen ilustrativa. El ícono de mapa y "Ver en el mapa" vuelven a la 19 con esta obra
// seleccionada.
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
  const hitos = pasosHitos(obra);

  const enMapa = obrasConUbicacion([obra]).length > 0;
  const verEnMapa = () => router.navigate({ pathname: '/obras', params: { obra: obra.id } });
  const encabezadoObra = (
    <BarraSuperior
      titulo="Detalle de la obra"
      accion={
        enMapa ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Ver en el mapa"
            onPress={verEnMapa}
            style={estilos.botonIcono}
          >
            <MaterialIcons name="map" size={sizes.icon} color={colors.text} />
          </Pressable>
        ) : undefined
      }
    />
  );

  return (
    <Pantalla conPestanas encabezadoHastaArriba encabezado={encabezadoObra}>
      <FotoSimulada tipo="obra" etiqueta="Imagen ilustrativa" alto={sizes.workPhoto} />

      <View style={estilos.grupo}>
        <View style={estilos.filaArriba}>
          <Texto variante="headlineLg" accessibilityRole="header" style={estilos.flexible}>
            {obra.nombre}
          </Texto>
          <ChipPlazo texto={ETIQUETA_ESTADO_OBRA[obra.estado]} tono={concluida ? 'resuelto' : 'plazo'} />
        </View>
        <View style={estilos.ubicacion}>
          <MaterialIcons name="place" size={sizes.iconSm} color={colors.textSecondary} />
          <Texto color={colors.textSecondary}>
            {obra.ubicacion}
            {enMapa ? (
              <>
                {' · '}
                <Texto
                  variante="bodyMdMedium"
                  color={colors.primary}
                  accessibilityRole="link"
                  onPress={verEnMapa}
                >
                  Ver en el mapa
                </Texto>
              </>
            ) : null}
          </Texto>
        </View>
      </View>

      <View style={estilos.grupo}>
        <View style={estilos.fila}>
          <Texto variante="bodyLg" style={estilos.flexible}>
            Avance físico
          </Texto>
          <Texto variante="headlineMd" tabular>
            {obra.avancePct} %
          </Texto>
        </View>
        <Avance porcentaje={obra.avancePct} tono={concluida ? 'concluida' : 'acento'} />
        <Texto variante="caption" color={colors.textSecondary}>
          {concluida ? 'Entregada' : 'Entrega prevista'}: {obra.meta} · Actualizada{' '}
          {haceDias(obra.actualizadaEn, HOY_EJEMPLO)}
        </Texto>
      </View>

      <Tarjeta grande>
        <Texto variante="headlineSm">De dónde sale el dinero</Texto>
        {tributos !== null ? (
          <View style={estilos.grupo}>
            <View style={estilos.barra}>
              <View style={{ flex: tributos, backgroundColor: colors.chart1 }} />
              <View style={{ flex: 100 - tributos, backgroundColor: colors.chart2 }} />
            </View>
            <View style={estilos.leyenda}>
              <Leyenda color={colors.chart1} texto={`Tributos del distrito ${tributos} %`} />
              <Leyenda color={colors.chart2} texto={`Transferencias ${100 - tributos} %`} />
            </View>
          </View>
        ) : null}
        <FilaDato etiqueta="Presupuesto" valor={<Valor monto={obra.montoAsignado} />} />
        <Separador />
        <FilaDato etiqueta="Gastado a la fecha" valor={<Valor monto={obra.montoEjecutado} />} />
      </Tarjeta>

      {hitos.length > 0 ? (
        <View style={estilos.grupo}>
          <Rotulo texto="Hitos" />
          <LineaTiempo pasos={hitos} />
        </View>
      ) : null}

      <Nota texto="La obra la ejecuta la municipalidad. Almira publica el avance que ella registra." />
      <Boton
        tipo="secundario"
        icono="photo-camera"
        titulo="¿Ves un problema? Repórtalo"
        onPress={() => router.push('/reclamo/nuevo')}
      />
      <PiePrototipo />
    </Pantalla>
  );
}

// Hitos de la línea de tiempo: el inicio (hecho), el primer hito en curso y los demás
// pendientes. "Riego y áreas verdes: 80 %" se parte en título y detalle.
function pasosHitos(obra: Obra): PasoLinea[] {
  const concluida = obra.estado === 'finalizada';
  const inicio: PasoLinea[] = obra.inicio
    ? [{ titulo: 'Inicio', detalle: formatearFechaCorta(obra.inicio), estado: 'hecho' }]
    : [];
  const resto = obra.hitos.map((hito, indice): PasoLinea => {
    const [titulo = hito, ...detalle] = hito.split(': ');
    const texto = detalle.join(': ');
    return {
      titulo,
      detalle: texto ? texto.charAt(0).toUpperCase() + texto.slice(1) : null,
      estado: concluida ? 'hecho' : indice === 0 ? 'actual' : 'pendiente',
    };
  });
  return [...inicio, ...resto];
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
    <Texto variante="bodyLgMedium" alineacion="right" tabular>
      {formatearSoles(monto)}
    </Texto>
  );
}

const estilos = StyleSheet.create({
  ubicacion: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
  botonIcono: {
    width: sizes.buttonTertiary,
    height: sizes.buttonTertiary,
    alignItems: 'center',
    justifyContent: 'center',
  },
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
