import { leerMensajeDelMapa, type MensajeAlMapa } from '@almira/shared';
import { useEffect, useRef, useState } from 'react';
import { View } from 'react-native';
import {
  ALTO_MAPA,
  Cargando,
  estilosMapa,
  NotaErrorMapa,
  useHtmlMapa,
  type PropsMapa,
} from './mapaComun';

// Mapa real de obras en Expo web: react-native-webview no funciona en el navegador,
// así que el mismo HTML va en un iframe con srcDoc (MAPA.md).
export function MapaObras(props: PropsMapa) {
  const { seleccionadaId = null, onSeleccionar, alto = ALTO_MAPA, enTarjeta, accessibilityLabel } = props;
  const html = useHtmlMapa(props);
  const iframe = useRef<HTMLIFrameElement>(null);
  const [estado, setEstado] = useState<'cargando' | 'listo' | 'error'>('cargando');
  const alSeleccionar = useRef(onSeleccionar);
  alSeleccionar.current = onSeleccionar;

  useEffect(() => setEstado('cargando'), [html]);

  // Solo se aceptan mensajes de este iframe y con un tipo conocido.
  useEffect(() => {
    const escuchar = (evento: MessageEvent) => {
      if (!iframe.current || evento.source !== iframe.current.contentWindow) return;
      const mensaje = leerMensajeDelMapa(evento.data);
      if (!mensaje) return;
      if (mensaje.tipo === 'obra') alSeleccionar.current?.(mensaje.id);
      else if (mensaje.tipo === 'listo') setEstado('listo');
      else setEstado('error');
    };
    window.addEventListener('message', escuchar);
    return () => window.removeEventListener('message', escuchar);
  }, []);

  useEffect(() => {
    if (estado !== 'listo') return;
    const mensaje: MensajeAlMapa = { tipo: 'seleccionar', id: seleccionadaId };
    // Un iframe con srcDoc tiene el mismo origen que la página.
    iframe.current?.contentWindow?.postMessage(mensaje, window.location.origin);
  }, [seleccionadaId, estado]);

  if (estado === 'error') return <NotaErrorMapa />;

  return (
    <View style={[enTarjeta ? estilosMapa.enTarjeta : estilosMapa.marco, { height: alto }]}>
      <iframe
        ref={iframe}
        srcDoc={html}
        title={accessibilityLabel}
        aria-label={accessibilityLabel}
        style={{ width: '100%', height: '100%', border: 0, display: 'block' }}
      />
      {estado === 'cargando' ? <Cargando /> : null}
    </View>
  );
}
