import { colors, radius, sizes, spacing, type TipoReclamo } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { StyleSheet, View, type DimensionValue } from 'react-native';
import { Texto } from './Texto';

// Dibujo fijo en lugar de la foto del reclamo (pantallas 17 y 18): no se usa la
// cámara. Pistas y veredas muestra un bache; alumbrado, un poste de noche; el
// resto, el ícono de su categoría.
export function FotoSimulada({ tipo }: { tipo: TipoReclamo }) {
  return (
    <View
      accessible
      accessibilityRole="image"
      accessibilityLabel="Foto simulada: dibujo de ejemplo"
      style={estilos.marco}
    >
      {tipo === 'pistas_veredas' ? <Bache /> : tipo === 'alumbrado' ? <Poste /> : null}
      {tipo !== 'pistas_veredas' && tipo !== 'alumbrado' ? (
        <View style={estilos.generico}>
          <MaterialCommunityIcons name={ICONO_TIPO[tipo]} size={56} color={colors.textSecondary} />
        </View>
      ) : null}
      <View style={estilos.etiqueta}>
        <Texto variante="caption" color={colors.textSecondary}>
          Foto simulada
        </Texto>
      </View>
    </View>
  );
}

const ICONO_TIPO: Record<TipoReclamo, keyof typeof MaterialCommunityIcons.glyphMap> = {
  pistas_veredas: 'road-variant',
  alumbrado: 'lightbulb-outline',
  limpieza: 'trash-can-outline',
  vehiculo_mal_estacionado: 'car',
  deposito_vehicular: 'tow-truck',
  cobro_indebido: 'receipt',
  otro: 'image-outline',
};

// Proporciones del dibujo respecto del alto de la foto, medidas en la pantalla 17.
const ALTO = sizes.evidencePhoto;
const BACHE = {
  cielo: ALTO * 0.26,
  sardinel: ALTO * 0.07,
  hoyo: { arriba: ALTO * 0.51, alto: ALTO * 0.37, estirar: 3.1 },
  fondo: { arriba: ALTO * 0.64, alto: ALTO * 0.23, estirar: 3.8 },
  linea: { abajo: ALTO * 0.07, grosor: ALTO * 0.02, guiones: 9 },
};

function Bache() {
  return (
    <View style={[StyleSheet.absoluteFill, { backgroundColor: colors.drawingRoad }]}>
      <View style={{ height: BACHE.cielo, backgroundColor: colors.drawingSky }} />
      <View style={{ height: BACHE.sardinel, backgroundColor: colors.drawingCurb }} />
      <Elipse {...BACHE.hoyo} color={colors.drawingHoleOuter} />
      <Elipse {...BACHE.fondo} color={colors.drawingHoleInner} />
      <View
        style={[
          estilos.guiones,
          { bottom: BACHE.linea.abajo, height: BACHE.linea.grosor },
        ]}
      >
        {Array.from({ length: BACHE.linea.guiones }, (_, indice) => (
          <View key={indice} style={estilos.guion} />
        ))}
      </View>
    </View>
  );
}

// Un círculo estirado a lo ancho: React Native no dibuja elipses.
function Elipse({
  arriba,
  alto,
  estirar,
  color,
}: {
  arriba: number;
  alto: number;
  estirar: number;
  color: string;
}) {
  return (
    <View style={[estilos.centrado, { top: arriba }]}>
      <View
        style={{
          width: alto,
          height: alto,
          borderRadius: alto / 2,
          backgroundColor: color,
          transform: [{ scaleX: estirar }],
        }}
      />
    </View>
  );
}

// Proporciones del poste de la pantalla 18.
const POSTE = {
  suelo: ALTO * 0.2,
  arriba: ALTO * 0.18,
  grosor: ALTO * 0.047,
  izquierda: '47%' as DimensionValue,
  brazo: ALTO * 0.33,
  foco: { ancho: ALTO * 0.14, desde: ALTO * 0.24 },
};

function Poste() {
  return (
    <View style={[StyleSheet.absoluteFill, { backgroundColor: colors.drawingNight }]}>
      <View style={[estilos.suelo, { height: POSTE.suelo }]} />
      <View
        style={{
          position: 'absolute',
          top: POSTE.arriba,
          bottom: POSTE.suelo,
          left: POSTE.izquierda,
          width: POSTE.grosor,
          backgroundColor: colors.drawingPole,
        }}
      />
      <View
        style={{
          position: 'absolute',
          top: POSTE.arriba,
          left: POSTE.izquierda,
          width: POSTE.brazo,
          height: POSTE.grosor,
          backgroundColor: colors.drawingPole,
        }}
      >
        <View
          style={{
            position: 'absolute',
            top: POSTE.grosor,
            left: POSTE.foco.desde,
            width: POSTE.foco.ancho,
            height: POSTE.grosor,
            backgroundColor: colors.drawingLamp,
          }}
        />
      </View>
    </View>
  );
}

const estilos = StyleSheet.create({
  marco: {
    height: sizes.evidencePhoto,
    borderRadius: radius.md,
    overflow: 'hidden',
    backgroundColor: colors.neutral,
  },
  generico: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  etiqueta: {
    position: 'absolute',
    top: spacing.sm,
    left: spacing.sm,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs / 2,
    borderRadius: radius.full,
    backgroundColor: colors.surface,
  },
  centrado: { position: 'absolute', left: 0, right: 0, alignItems: 'center' },
  guiones: {
    position: 'absolute',
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  guion: { width: '7%', backgroundColor: colors.surface },
  suelo: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: colors.drawingNightGround,
  },
});
