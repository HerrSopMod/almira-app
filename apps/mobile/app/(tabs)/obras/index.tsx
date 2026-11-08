import {
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
import { ChipPlazo, PiePrototipo, Progreso, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { MapaObras } from '@/components/MapaObras';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 19 del prototipo. El mapa es un dibujo fijo; los datos son las obras
// que la municipalidad publicó.
export default function MapaDeObras() {
  const { municipalidad, obras } = useDatosMunicipales();

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      separacion="block"
      encabezado={<BarraSuperior titulo="Mapa de obras" />}
    >
      <View style={estilos.cabecera}>
        <MapaObras obras={obras} />
        <View style={estilos.hoja}>
          <View style={estilos.fila}>
            <Texto
              variante="headlineMd"
              fuente="poppins"
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
            <Leyenda color={colors.paid} texto="Concluida" />
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
            <Texto variante="labelLg">{obra.nombre}</Texto>
            <Texto color={colors.textSecondary}>{obra.ubicacion}</Texto>
          </View>
          <ChipPlazo texto={ETIQUETA_ESTADO_OBRA[obra.estado]} tono={concluida ? 'pagado' : 'rosado'} />
        </View>
        <Progreso porcentaje={obra.avancePct} tono={concluida ? 'pagado' : 'primario'} />
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
    gap: spacing.block,
    marginTop: -radius.xl,
    paddingTop: spacing.lg,
    paddingHorizontal: spacing.margin,
    borderTopLeftRadius: radius.xl,
    borderTopRightRadius: radius.xl,
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
