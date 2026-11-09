import { colors, htmlMapa, type MarcadorMapa } from '@almira/shared';
import { useEffect, useMemo, useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';
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

// En Expo web, react-native-webview no funciona: se usa un iframe con el mismo HTML.
export function MapaLeaflet({
  marcadores,
  alto,
  interactivo = true,
  seleccionadaId,
  etiqueta,
  onSeleccionar,
}: Props) {
  const [error, setError] = useState(false);
  const marco = useRef<HTMLIFrameElement | null>(null);
  const html = useMemo(
    () => htmlMapa({ marcadores, seleccionadaId, interactivo, colores: COLORES_MAPA }),
    [marcadores, seleccionadaId, interactivo],
  );

  useEffect(() => {
    const alRecibir = (e: MessageEvent) => {
      if (e.source !== marco.current?.contentWindow) return;
      const m = e.data as { tipo?: string; id?: string };
      if (m?.tipo === 'error') setError(true);
      if (m?.tipo === 'obra' && m.id) onSeleccionar?.(m.id);
    };
    window.addEventListener('message', alRecibir);
    return () => window.removeEventListener('message', alRecibir);
  }, [onSeleccionar]);

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
    <View style={[estilos.base, { height: alto }]}>
      <iframe
        ref={marco}
        title={etiqueta}
        srcDoc={html}
        style={{ border: 0, width: '100%', height: '100%' }}
      />
    </View>
  );
}

const estilos = StyleSheet.create({
  base: { overflow: 'hidden', backgroundColor: colors.subtle },
  aviso: { alignItems: 'center', justifyContent: 'center', padding: 16 },
});
