import { colors, htmlMapa, type MarcadorMapa } from '@almira/shared';
import { useMemo, useState } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { WebView } from 'react-native-webview';
import { Texto } from './Texto';

type Props = {
  marcadores: MarcadorMapa[];
  alto: number;
  interactivo?: boolean;
  seleccionadaId?: string | null;
  etiqueta: string;
  onSeleccionar?: (id: string) => void;
};

export const COLORES_MAPA = {
  primario: colors.primary,
  exito: colors.success,
  superficie: colors.surface,
  texto: colors.text,
};

// Mapa de OpenStreetMap con Leaflet dentro de una WebView (docs/design/turquesa/MAPA.md).
// El baseUrl hace que las teselas lleven Referer, que OpenStreetMap exige.
export function MapaLeaflet({
  marcadores,
  alto,
  interactivo = true,
  seleccionadaId,
  etiqueta,
  onSeleccionar,
}: Props) {
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState(false);
  const html = useMemo(
    () => htmlMapa({ marcadores, seleccionadaId, interactivo, colores: COLORES_MAPA }),
    [marcadores, seleccionadaId, interactivo],
  );

  if (error) {
    return (
      <View style={[estilos.base, estilos.aviso, { height: alto }]}>
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
          No se pudo cargar el mapa. Revisa tu conexión.
        </Texto>
      </View>
    );
  }

  return (
    <View style={[estilos.base, { height: alto }]} accessible accessibilityLabel={etiqueta}>
      <WebView
        originWhitelist={['*']}
        source={{ html, baseUrl: 'https://github.com/HerrSopMod/almira-app' }}
        scrollEnabled={false}
        onMessage={(e) => {
          try {
            const m = JSON.parse(e.nativeEvent.data) as { tipo: string; id?: string };
            if (m.tipo === 'listo') setCargando(false);
            if (m.tipo === 'error') setError(true);
            if (m.tipo === 'obra' && m.id) onSeleccionar?.(m.id);
          } catch {
            // Mensaje ajeno al mapa: se ignora.
          }
        }}
        onLoadEnd={() => setCargando(false)}
      />
      {cargando ? (
        <View style={estilos.carga} pointerEvents="none">
          <ActivityIndicator color={colors.primary} />
        </View>
      ) : null}
    </View>
  );
}

const estilos = StyleSheet.create({
  base: { overflow: 'hidden', backgroundColor: colors.subtle },
  aviso: { alignItems: 'center', justifyContent: 'center', padding: 16 },
  carga: { ...StyleSheet.absoluteFill, alignItems: 'center', justifyContent: 'center' },
});
