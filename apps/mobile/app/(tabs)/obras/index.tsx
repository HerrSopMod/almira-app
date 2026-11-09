import {
  centroMapaDe,
  colors,
  formatearSoles,
  nombreDistrito,
  sizes,
  spacing,
  type Obra,
} from '@almira/shared';
import { router, useLocalSearchParams } from 'expo-router';
import { useEffect, useMemo, useRef, useState, type ComponentRef } from 'react';
import { Pressable, StyleSheet, View, type ScrollView } from 'react-native';
import {
  Avance,
  ChipEstadoObra,
  PiePrototipo,
  Tarjeta,
  TituloPantalla,
  Vacio,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Chips } from '@/components/Chips';
import { MapaObras } from '@/components/MapaObras';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

type Filtro = 'todas' | 'en_ejecucion' | 'finalizada';

const FILTROS: { valor: Filtro; titulo: string }[] = [
  { valor: 'todas', titulo: 'Todas' },
  { valor: 'en_ejecucion', titulo: 'En ejecución' },
  { valor: 'finalizada', titulo: 'Concluidas' },
];

// Pantalla 19 (maqueta 19-mapa-de-obras): mapa real de OpenStreetMap con las obras
// publicadas. Tocar un marcador resalta su tarjeta y baja la lista hasta ella. Con
// ?obra=<id> (desde el detalle) la obra llega seleccionada y centrada.
export default function MapaDeObras() {
  const { obra: obraParam } = useLocalSearchParams<{ obra?: string }>();
  const { municipalidad, obras } = useDatosMunicipales();
  const [filtro, setFiltro] = useState<Filtro>('todas');
  const [seleccionada, setSeleccionada] = useState<string | null>(obraParam ?? null);
  const scroll = useRef<ComponentRef<typeof ScrollView>>(null);
  const posiciones = useRef<Record<string, number>>({});
  const distrito = nombreDistrito(municipalidad);

  const visibles = useMemo(
    () => (filtro === 'todas' ? obras : obras.filter((obra) => obra.estado === filtro)),
    [obras, filtro],
  );

  // Al volver desde el detalle con otra obra, se selecciona esa.
  useEffect(() => {
    if (obraParam) {
      setFiltro('todas');
      setSeleccionada(obraParam);
    }
  }, [obraParam]);

  const bajarHasta = (id: string) => {
    const y = posiciones.current[id];
    if (y !== undefined) scroll.current?.scrollTo({ y: Math.max(y - spacing.md, 0), animated: true });
  };

  const alTocarMarcador = (id: string) => {
    setSeleccionada(id);
    bajarHasta(id);
  };

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      separacion="blockDense"
      scrollRef={scroll}
      encabezado={<BarraSuperior variante="raiz" titulo="Obras" />}
    >
      <TituloPantalla titulo={`Obras de ${distrito}`} texto="Toca un punto del mapa para ver la obra." />
      <Chips opciones={FILTROS} elegida={filtro} onElegir={setFiltro} />

      <MapaObras
        obras={visibles}
        centro={centroMapaDe(municipalidad.id)}
        seleccionadaId={seleccionada}
        onSeleccionar={alTocarMarcador}
        accessibilityLabel={`Mapa de obras de ${distrito}`}
      />
      <View style={estilos.leyenda}>
        <Leyenda color={colors.primary} texto="En ejecución" />
        <Leyenda color={colors.success} texto="Concluida" />
        <Texto color={colors.textSecondary} alineacion="right" style={estilos.flexible}>
          % de avance
        </Texto>
      </View>

      {visibles.length === 0 ? (
        <Vacio
          texto={
            obras.length === 0
              ? 'Esta municipalidad aún no tiene obras publicadas.'
              : 'No hay obras con este filtro.'
          }
        />
      ) : (
        visibles.map((obra) => (
          <View
            key={obra.id}
            onLayout={(evento) => {
              posiciones.current[obra.id] = evento.nativeEvent.layout.y;
            }}
          >
            <FilaObra obra={obra} seleccionada={obra.id === seleccionada} />
          </View>
        ))
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

function FilaObra({ obra, seleccionada }: { obra: Obra; seleccionada: boolean }) {
  const concluida = obra.estado === 'finalizada';
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected: seleccionada }}
      onPress={() => router.push({ pathname: '/obras/[id]', params: { id: obra.id } })}
    >
      <Tarjeta style={seleccionada && estilos.seleccionada}>
        <View style={estilos.filaArriba}>
          <View style={estilos.flexible}>
            <Texto variante="headlineSm">{obra.nombre}</Texto>
            <Texto color={colors.textSecondary}>{obra.ubicacion}</Texto>
          </View>
          <ChipEstadoObra estado={obra.estado} />
        </View>
        <Avance porcentaje={obra.avancePct} tono={concluida ? 'concluida' : 'acento'} />
        <View style={estilos.fila}>
          <Texto variante="bodyLg" color={colors.textSecondary} style={estilos.flexible}>
            {obra.avancePct} % de avance
          </Texto>
          <Texto variante="bodyLgMedium" alineacion="right" tabular>
            {formatearSoles(obra.montoAsignado, { sinDecimales: true })}
          </Texto>
        </View>
      </Tarjeta>
    </Pressable>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  filaArriba: { flexDirection: 'row', alignItems: 'flex-start', gap: spacing.sm },
  leyenda: { flexDirection: 'row', alignItems: 'center', gap: spacing.lg },
  flexible: { flex: 1 },
  punto: {
    width: sizes.legendDot,
    height: sizes.legendDot,
    borderRadius: sizes.legendDot / 2,
  },
  seleccionada: { borderWidth: sizes.focusBorderWidth, borderColor: colors.primary },
});
