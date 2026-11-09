import {
  colors,
  coloresMapa,
  htmlMapaObras,
  MAPA_NOTA_ERROR,
  radius,
  sizes,
  type CentroMapa,
  type Obra,
  type PuntoMapa,
} from '@almira/shared';
import { useMemo, useRef } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { Nota } from './Bloques';

// Lo mismo para MapaObras.tsx (WebView) y MapaObras.web.tsx (iframe).
export type PropsMapa = {
  obras: Obra[];
  centro: CentroMapa;
  accessibilityLabel: string;
  seleccionadaId?: string | null;
  onSeleccionar?: (id: string) => void;
  // false en el minimapa de Nuevo reclamo: sin gestos ni botones.
  interactivo?: boolean;
  ubicacion?: PuntoMapa | null;
  alto?: number;
  // Dentro de una tarjeta, el mapa no lleva borde ni radio propios.
  enTarjeta?: boolean;
};

const COLORES = coloresMapa(colors);

// El HTML solo se rehace si cambian las obras o el encuadre. La selección se manda
// después por mensaje, para no recargar el mapa.
export function useHtmlMapa({
  obras,
  centro,
  seleccionadaId = null,
  interactivo = true,
  ubicacion = null,
}: PropsMapa) {
  const seleccionRef = useRef(seleccionadaId);
  seleccionRef.current = seleccionadaId;
  return useMemo(
    () =>
      htmlMapaObras({
        obras,
        seleccionadaId: seleccionRef.current,
        interactivo,
        colores: COLORES,
        centroPorDefecto: centro,
        ubicacion,
      }),
    // La selección inicial se lee del ref a propósito.
    [obras, interactivo, centro, ubicacion],
  );
}

export function Cargando() {
  return (
    <View style={[StyleSheet.absoluteFill, estilosMapa.cargando]} pointerEvents="none">
      <ActivityIndicator color={colors.primary} />
    </View>
  );
}

export function NotaErrorMapa() {
  return <Nota conBorde icono="map" texto={MAPA_NOTA_ERROR} />;
}

export const estilosMapa = StyleSheet.create({
  marco: {
    overflow: 'hidden',
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.lg,
    backgroundColor: colors.subtle,
  },
  enTarjeta: { overflow: 'hidden', backgroundColor: colors.subtle },
  cargando: { alignItems: 'center', justifyContent: 'center', backgroundColor: colors.subtle },
});

export const ALTO_MAPA = sizes.mapHeight;
