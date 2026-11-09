import { leerMensajeDelMapa } from '@almira/shared';
import { useEffect, useRef, useState } from 'react';
import { Linking, View } from 'react-native';
import { WebView } from 'react-native-webview';
import type {
  ShouldStartLoadRequest,
  WebViewMessageEvent,
  WebViewOpenWindowEvent,
} from 'react-native-webview/lib/WebViewTypes';
import {
  ALTO_MAPA,
  Cargando,
  estilosMapa,
  NotaErrorMapa,
  useHtmlMapa,
  type PropsMapa,
} from './mapaComun';

// OpenStreetMap exige un Referer en las teselas: el baseUrl hace que el WebView lo envíe.
const BASE_URL = 'https://github.com/HerrSopMod/almira-app';

// Mapa real de obras en el teléfono: Leaflet dentro de un WebView (MAPA.md).
export function MapaObras(props: PropsMapa) {
  const { seleccionadaId = null, onSeleccionar, alto = ALTO_MAPA, enTarjeta, accessibilityLabel } = props;
  const html = useHtmlMapa(props);
  // Los tipos de react-native-webview 14 usan P = undefined, que con TypeScript 6
  // deja las props en never; con P = object quedan las props reales.
  const webview = useRef<WebView<object>>(null);
  const [estado, setEstado] = useState<'cargando' | 'listo' | 'error'>('cargando');

  useEffect(() => setEstado('cargando'), [html]);

  // Selección desde la lista: centra y resalta el marcador sin recargar el mapa.
  useEffect(() => {
    if (estado !== 'listo') return;
    webview.current?.injectJavaScript(
      `window.almiraMapa && window.almiraMapa.seleccionar(${JSON.stringify(seleccionadaId)}); true;`,
    );
  }, [seleccionadaId, estado]);

  const alRecibir = (evento: WebViewMessageEvent) => {
    const mensaje = leerMensajeDelMapa(evento.nativeEvent.data);
    if (!mensaje) return;
    if (mensaje.tipo === 'obra') onSeleccionar?.(mensaje.id);
    else if (mensaje.tipo === 'listo') setEstado('listo');
    else setEstado('error');
  };

  // Los enlaces (la atribución) se abren en el navegador, no dentro del mapa.
  const abrirFuera = (url: string) => {
    if (/^https?:\/\//.test(url)) void Linking.openURL(url);
  };

  if (estado === 'error') return <NotaErrorMapa />;

  return (
    <View
      accessible
      accessibilityLabel={accessibilityLabel}
      style={[enTarjeta ? estilosMapa.enTarjeta : estilosMapa.marco, { height: alto }]}
    >
      <WebView<object>
        ref={webview}
        source={{ html, baseUrl: BASE_URL }}
        originWhitelist={['*']}
        onMessage={alRecibir}
        onError={() => setEstado('error')}
        onShouldStartLoadWithRequest={(pedido: ShouldStartLoadRequest) => {
          // La carga inicial del HTML llega con el baseUrl; todo lo demás sale del mapa.
          if (pedido.url === BASE_URL || pedido.url.startsWith('about:')) return true;
          abrirFuera(pedido.url);
          return false;
        }}
        setSupportMultipleWindows={false}
        onOpenWindow={(evento: WebViewOpenWindowEvent) => abrirFuera(evento.nativeEvent.targetUrl)}
        scrollEnabled={false}
        bounces={false}
        nestedScrollEnabled
        style={{ backgroundColor: 'transparent' }}
      />
      {estado === 'cargando' ? <Cargando /> : null}
    </View>
  );
}
