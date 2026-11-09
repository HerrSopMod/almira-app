import {
  centroMapaDe,
  colors,
  ETIQUETA_ESTADO_OBRA,
  formatearSoles,
  nombreDistrito,
  radius,
  sizes,
  spacing,
  type Obra,
} from '@almira/shared';
import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChipPlazo, PiePrototipo, Avance, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { MapaObras } from '@/components/MapaObras';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 19 del prototipo: mapa real de OpenStreetMap con las obras publicadas.
export default function MapaDeObras() {
  const { municipalidad, obras } = useDatosMunicipales();

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      separacion="blockDense"
      encabezado={<BarraSuperior variante="raiz" titulo="Obras" />}
    >
      <View style={estilos.cabecera}>
        <MapaObras
          obras={obras}
          centro={centroMapaDe(municipalidad.id)}
          accessibilityLabel={`Mapa de obras de ${nombreDistrito(municipalidad)}`}
        />
        <View style={estilos.hoja}>
          <View style={estilos.fila}>
            <Texto
              variante="headlineMd"
             
              accessibilityRole="header"
              style={estilos.flexible}
            >
              Obras de {nombreDistrito(municipalidad)}
            </Texto>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              % de avance
            </Texto>
          </View>
          <View style={estilos.leyenda}>
            <Leyenda color={colors.primary} texto="En ejecución" />
            <Leyenda color={colors.success} texto="Concluida" />
          </View>
        </View>
      </View>

      {obras.length === 0 ? (
        <Vacio texto="Esta municipalidad aún no tiene obras publicadas." />
      ) : (
        obras.map((obra) => <FilaObra key={obra.id} obra={obra} />)
      )}
      <PiePrototipo />
    </Pantalla>
  );
}

function Leyenda({ color, texto }: { color: string; texto: string }) {
  return (
    <View style={estilos.fila}>
      <View style={[estilos.punto, { backgroundColor: color }]} />
      <Texto color={colors.textSecondary}>{texto}</Texto>
    </View>
  );
}

function FilaObra({ obra }: { obra: Obra }) {
  const concluida = obra.estado === 'finalizada';
  return (
    <Pressable
      accessibilityRole="button"
      onPress={() => router.push({ pathname: '/obras/[id]', params: { id: obra.id } })}
    >
      <Tarjeta>
        <View style={estilos.filaArriba}>
          <View style={estilos.flexible}>
            <Texto variante="bodyLgMedium">{obra.nombre}</Texto>
            <Texto color={colors.textSecondary}>{obra.ubicacion}</Texto>
          </View>
          <ChipPlazo texto={ETIQUETA_ESTADO_OBRA[obra.estado]} tono={concluida ? 'resuelto' : 'plazo'} />
        </View>
        <Avance porcentaje={obra.avancePct} tono={concluida ? 'concluida' : 'acento'} />
        <View style={estilos.fila}>
          <Texto color={colors.textSecondary} style={estilos.flexible}>
            {obra.avancePct} % de avance
          </Texto>
          <Texto color={colors.textSecondary} alineacion="right" tabular>
            {formatearSoles(obra.montoAsignado)}
          </Texto>
        </View>
      </Tarjeta>
    </Pressable>
  );
}

const estilos = StyleSheet.create({
  // El mapa va de borde a borde, pegado a la barra superior.
  cabecera: { marginHorizontal: -spacing.margin, marginTop: -spacing.md },
  hoja: {
    gap: spacing.blockDense,
    marginTop: -radius.lg,
    paddingTop: spacing.lg,
    paddingHorizontal: spacing.margin,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
    backgroundColor: colors.background,
  },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  filaArriba: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.sm },
  leyenda: { flexDirection: 'row', gap: spacing.lg },
  flexible: { flex: 1 },
  punto: {
    width: sizes.legendDot,
    height: sizes.legendDot,
    borderRadius: sizes.legendDot / 2,
  },
});
