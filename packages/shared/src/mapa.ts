// Mapa real de obras con OpenStreetMap y Leaflet (docs/design/turquesa/MAPA.md).
// La app lo dibuja con este HTML dentro de un WebView o un iframe; el panel web usa
// React Leaflet con las mismas teselas, atribución y marcador.
import { sizes } from './tokens';
import type { CentroMapa, Obra, PuntoMapa } from './types';

export const MAPA_TILES = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
export const MAPA_ATRIBUCION = '© colaboradores de OpenStreetMap';
export const MAPA_ATRIBUCION_URL = 'https://www.openstreetmap.org/copyright';
// La atribución siempre se ve: lo exige OpenStreetMap.
export const MAPA_ATRIBUCION_HTML = `<a href="${MAPA_ATRIBUCION_URL}" target="_blank" rel="noopener noreferrer">${MAPA_ATRIBUCION}</a>`;
export const MAPA_ZOOM_MAXIMO = 19;
export const MAPA_NOTA_ERROR =
  'No se pudo cargar el mapa. Revisa tu conexión. La lista de obras sigue abajo.';

// Para una municipalidad sin centro en los datos: el centro de Lima, sin acercar.
export const CENTRO_MAPA_LIMA: CentroMapa = { latitud: -12.0464, longitud: -77.0428, zoom: 12 };

const LEAFLET_CSS = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
const LEAFLET_CSS_SRI = 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=';
const LEAFLET_JS = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
const LEAFLET_JS_SRI = 'sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=';

// Margen alrededor de los puntos, en grados (unos 300 m en Lima con un solo punto).
const MARGEN_UN_PUNTO = 0.003;
const MARGEN_MINIMO = 0.002;
const MARGEN_PROPORCION = 0.15;
// Errores de teselas seguidos, sin ninguna cargada, antes de rendirse.
const ERRORES_TESELA_MAXIMOS = 4;
const ESPERA_MAXIMA_MS = 15000;

// Colores del mapa: entran desde los tokens (colors de @almira/shared).
export interface ColoresMapa {
  primary: string;
  primaryPressed: string;
  success: string;
  onPrimary: string;
  surface: string;
  subtle: string;
  text: string;
  textSecondary: string;
  border: string;
  markerShadow: string;
}

export function coloresMapa(colores: ColoresMapa): ColoresMapa {
  const {
    primary,
    primaryPressed,
    success,
    onPrimary,
    surface,
    subtle,
    text,
    textSecondary,
    border,
    markerShadow,
  } = colores;
  return {
    primary,
    primaryPressed,
    success,
    onPrimary,
    surface,
    subtle,
    text,
    textSecondary,
    border,
    markerShadow,
  };
}

export type ObraEnMapa = Obra & { latitud: number; longitud: number };

// Solo las obras publicadas que tienen coordenadas salen en el mapa.
export function obrasConUbicacion(obras: Obra[]): ObraEnMapa[] {
  return obras.filter(
    (obra): obra is ObraEnMapa =>
      obra.publicada && Number.isFinite(obra.latitud) && Number.isFinite(obra.longitud),
  );
}

export type LimitesMapa = [[number, number], [number, number]];
export type EncuadreMapa =
  | { tipo: 'centro'; centro: [number, number]; zoom: number }
  | { tipo: 'limites'; limites: LimitesMapa };

// Encuadre para fitBounds: sin puntos, el centro del distrito; con puntos, los límites
// que los contienen con margen.
export function encuadreMapa(puntos: PuntoMapa[], centroPorDefecto: CentroMapa): EncuadreMapa {
  if (puntos.length === 0) {
    return {
      tipo: 'centro',
      centro: [centroPorDefecto.latitud, centroPorDefecto.longitud],
      zoom: centroPorDefecto.zoom,
    };
  }
  const latitudes = puntos.map((p) => p.latitud);
  const longitudes = puntos.map((p) => p.longitud);
  const sur = Math.min(...latitudes);
  const norte = Math.max(...latitudes);
  const oeste = Math.min(...longitudes);
  const este = Math.max(...longitudes);
  const margen = (min: number, max: number) =>
    puntos.length === 1
      ? MARGEN_UN_PUNTO
      : Math.max((max - min) * MARGEN_PROPORCION, MARGEN_MINIMO);
  const mLat = margen(sur, norte);
  const mLng = margen(oeste, este);
  return {
    tipo: 'limites',
    limites: [
      [sur - mLat, oeste - mLng],
      [norte + mLat, este + mLng],
    ],
  };
}

// Mensajes entre el HTML del mapa y la pantalla que lo contiene.
export type MensajeDelMapa =
  | { tipo: 'obra'; id: string }
  | { tipo: 'listo' }
  | { tipo: 'error' };
export type MensajeAlMapa = { tipo: 'seleccionar'; id: string | null };

export function leerMensajeDelMapa(dato: unknown): MensajeDelMapa | null {
  let valor = dato;
  if (typeof valor === 'string') {
    try {
      valor = JSON.parse(valor);
    } catch {
      return null;
    }
  }
  if (typeof valor !== 'object' || valor === null) return null;
  const { tipo, id } = valor as { tipo?: unknown; id?: unknown };
  if (tipo === 'obra' && typeof id === 'string') return { tipo, id };
  if (tipo === 'listo' || tipo === 'error') return { tipo };
  return null;
}

// Píldora del marcador (LEEME.md → Marcador del mapa). Las clases las define
// estilosMarcador(); el panel web la usa dentro de L.divIcon.
export function htmlMarcador(obra: Pick<Obra, 'avancePct' | 'estado'>, seleccionada: boolean) {
  const clases = [
    'almira-marcador',
    obra.estado === 'finalizada' ? 'almira-concluida' : '',
    seleccionada ? 'almira-seleccionada' : '',
  ]
    .filter(Boolean)
    .join(' ');
  return `<div class="${clases}"><span>${Math.round(obra.avancePct)}</span><i></i></div>`;
}

// Marcador de la ubicación del reclamo (pantalla 16): círculo con un punto.
export function htmlMarcadorUbicacion() {
  return '<div class="almira-ubicacion"><span></span><i></i></div>';
}

const ALTO_MARCADOR = sizes.mapMarker;
const BORDE_MARCADOR = sizes.mapMarkerBorder;
const ALTO_SELECCIONADO = ALTO_MARCADOR + 6;
const PALITO = 6;

export function estilosMarcador(c: ColoresMapa) {
  return `
.almira-icono { background: none; border: 0; }
.almira-marcador { position: absolute; left: 0; bottom: 0; transform: translateX(-50%);
  display: flex; flex-direction: column; align-items: center; cursor: pointer; }
.almira-marcador span { display: block; min-width: ${ALTO_MARCADOR + 8}px; height: ${ALTO_MARCADOR}px;
  box-sizing: border-box; padding: 0 8px; border: ${BORDE_MARCADOR}px solid ${c.onPrimary};
  border-radius: ${ALTO_MARCADOR}px; background: ${c.primary}; color: ${c.onPrimary};
  font: 700 13px/${ALTO_MARCADOR - 2 * BORDE_MARCADOR}px Inter, system-ui, sans-serif; text-align: center;
  font-variant-numeric: tabular-nums; box-shadow: 0 2px 6px ${c.markerShadow}; white-space: nowrap; }
.almira-marcador i { display: block; width: 2px; height: ${PALITO}px; background: ${c.primary}; }
.almira-concluida span { background: ${c.success}; }
.almira-concluida i { background: ${c.success}; }
.almira-seleccionada span { height: ${ALTO_SELECCIONADO}px; min-width: ${ALTO_SELECCIONADO + 10}px;
  background: ${c.primaryPressed}; line-height: ${ALTO_SELECCIONADO - 2 * BORDE_MARCADOR}px; font-size: 15px; }
.almira-seleccionada i { background: ${c.primaryPressed}; }
.almira-ubicacion { position: absolute; left: 0; bottom: 0; transform: translateX(-50%);
  display: flex; flex-direction: column; align-items: center; }
.almira-ubicacion span { display: flex; align-items: center; justify-content: center;
  width: ${ALTO_SELECCIONADO}px; height: ${ALTO_SELECCIONADO}px; box-sizing: border-box;
  border: ${BORDE_MARCADOR}px solid ${c.onPrimary}; border-radius: 50%; background: ${c.primary};
  box-shadow: 0 2px 6px ${c.markerShadow}; }
.almira-ubicacion span::after { content: ''; width: 10px; height: 10px; border-radius: 50%;
  background: ${c.onPrimary}; }
.almira-ubicacion i { display: block; width: 2px; height: ${PALITO}px; background: ${c.primary}; }
`;
}

export interface OpcionesHtmlMapa {
  obras: Obra[];
  seleccionadaId?: string | null;
  // false en el minimapa: sin gestos ni botones.
  interactivo: boolean;
  colores: ColoresMapa;
  centroPorDefecto: CentroMapa;
  // Ubicación del reclamo (pantalla 16), con su propio marcador.
  ubicacion?: PuntoMapa | null;
}

// U+2028 y U+2029 cortan líneas en JavaScript antiguo.
const SEPARADORES_DE_LINEA = new RegExp(`[${String.fromCharCode(0x2028, 0x2029)}]`, 'g');

// JSON seguro dentro de <script>: nada puede cerrar la etiqueta.
function jsonEnScript(valor: unknown) {
  return JSON.stringify(valor)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026')
    .replace(SEPARADORES_DE_LINEA, (c) => `\\u${c.charCodeAt(0).toString(16)}`);
}

// HTML completo del mapa. Avisa con postMessage({ tipo: 'obra', id }) al tocar un
// marcador, { tipo: 'listo' } al cargar la primera tesela y { tipo: 'error' } si las
// teselas fallan. Escucha { tipo: 'seleccionar', id } (iframe) o
// window.almiraMapa.seleccionar(id) (WebView) para centrar y resaltar una obra.
export function htmlMapaObras({
  obras,
  seleccionadaId = null,
  interactivo,
  colores: c,
  centroPorDefecto,
  ubicacion = null,
}: OpcionesHtmlMapa): string {
  const enMapa = obrasConUbicacion(obras);
  const puntos: PuntoMapa[] = ubicacion ? [ubicacion] : enMapa;
  const datos = {
    obras: enMapa.map((o) => ({
      id: o.id,
      nombre: o.nombre,
      avancePct: o.avancePct,
      estado: o.estado,
      latitud: o.latitud,
      longitud: o.longitud,
    })),
    seleccionadaId,
    interactivo,
    ubicacion,
    encuadre: encuadreMapa(puntos, centroPorDefecto),
    tiles: MAPA_TILES,
    atribucion: MAPA_ATRIBUCION_HTML,
    zoomMaximo: MAPA_ZOOM_MAXIMO,
    erroresMaximos: ERRORES_TESELA_MAXIMOS,
    esperaMaxima: ESPERA_MAXIMA_MS,
  };

  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<link rel="stylesheet" href="${LEAFLET_CSS}" integrity="${LEAFLET_CSS_SRI}" crossorigin="">
<style>
html, body, #mapa { height: 100%; margin: 0; padding: 0; }
body { background: ${c.subtle}; font-family: Inter, system-ui, sans-serif; color: ${c.text}; }
.leaflet-container { background: ${c.subtle}; font-family: Inter, system-ui, sans-serif; }
.leaflet-control-attribution { font-size: 11px; color: ${c.text}; background: ${c.surface}; opacity: 0.92; }
.leaflet-control-attribution a { color: ${c.text}; }
.leaflet-bar { border: 1px solid ${c.border} !important; border-radius: 10px; overflow: hidden; box-shadow: none !important; }
.leaflet-bar a { width: 40px; height: 40px; line-height: 40px; color: ${c.text}; background: ${c.surface};
  border-bottom-color: ${c.border}; font-size: 20px; }
.almira-recentrar { display: flex; align-items: center; justify-content: center; width: 40px; height: 40px;
  padding: 0; border: 0; background: ${c.surface}; cursor: pointer; }
.almira-recentrar svg { width: 24px; height: 24px; fill: ${c.primary}; }
${estilosMarcador(c)}
</style>
</head>
<body>
<div id="mapa" role="presentation"></div>
<script>
(function () {
  var avisado = false;
  function avisar(mensaje) {
    if (window.ReactNativeWebView) {
      window.ReactNativeWebView.postMessage(JSON.stringify(mensaje));
    } else if (window.parent && window.parent !== window) {
      window.parent.postMessage(mensaje, '*');
    }
  }
  window.almiraAvisar = avisar;
  window.almiraError = function () {
    if (avisado) return;
    avisado = true;
    avisar({ tipo: 'error' });
  };
  if (navigator.onLine === false) window.almiraError();
})();
</script>
<script src="${LEAFLET_JS}" integrity="${LEAFLET_JS_SRI}" crossorigin="" onerror="almiraError()"></script>
<script>
(function () {
  var D = ${jsonEnScript(datos)};
  if (typeof L === 'undefined') { window.almiraError(); return; }
  var avisar = window.almiraAvisar;
  var mapa = L.map('mapa', {
    zoomControl: false,
    attributionControl: false,
    dragging: D.interactivo,
    touchZoom: D.interactivo,
    scrollWheelZoom: D.interactivo,
    doubleClickZoom: D.interactivo,
    boxZoom: D.interactivo,
    keyboard: D.interactivo,
    tap: D.interactivo
  });
  L.control.attribution({ prefix: false, position: 'bottomright' }).addTo(mapa);

  function encuadrar() {
    if (D.encuadre.tipo === 'centro') {
      mapa.setView(D.encuadre.centro, D.encuadre.zoom);
    } else {
      mapa.fitBounds(D.encuadre.limites, { maxZoom: 17 });
    }
  }
  encuadrar();

  var cargadas = 0;
  var errores = 0;
  var capa = L.tileLayer(D.tiles, { maxZoom: D.zoomMaximo, attribution: D.atribucion });
  capa.on('tileload', function () {
    cargadas += 1;
    errores = 0;
    if (cargadas === 1) avisar({ tipo: 'listo' });
  });
  capa.on('tileerror', function () {
    errores += 1;
    if (cargadas === 0 && errores >= D.erroresMaximos) window.almiraError();
  });
  capa.addTo(mapa);
  setTimeout(function () { if (cargadas === 0) window.almiraError(); }, D.esperaMaxima);
  window.addEventListener('offline', function () { if (cargadas === 0) window.almiraError(); });

  function marcadorHtml(obra, seleccionada) {
    var clases = 'almira-marcador' + (obra.estado === 'finalizada' ? ' almira-concluida' : '') +
      (seleccionada ? ' almira-seleccionada' : '');
    return '<div class="' + clases + '"><span>' + Math.round(obra.avancePct) + '</span><i></i></div>';
  }
  function icono(obra, seleccionada) {
    return L.divIcon({ className: 'almira-icono', html: marcadorHtml(obra, seleccionada),
      iconSize: [0, 0], iconAnchor: [0, 0] });
  }

  var marcadores = {};
  var seleccionada = D.seleccionadaId;
  D.obras.forEach(function (obra) {
    var marcador = L.marker([obra.latitud, obra.longitud], {
      icon: icono(obra, obra.id === seleccionada),
      title: obra.nombre,
      alt: obra.nombre,
      keyboard: D.interactivo,
      interactive: D.interactivo,
      zIndexOffset: obra.id === seleccionada ? 1000 : 0
    }).addTo(mapa);
    marcador.on('click', function () {
      seleccionar(obra.id, false);
      avisar({ tipo: 'obra', id: obra.id });
    });
    marcadores[obra.id] = { marcador: marcador, obra: obra };
  });

  if (D.ubicacion) {
    L.marker([D.ubicacion.latitud, D.ubicacion.longitud], {
      icon: L.divIcon({ className: 'almira-icono',
        html: '<div class="almira-ubicacion"><span></span><i></i></div>',
        iconSize: [0, 0], iconAnchor: [0, 0] }),
      interactive: false, keyboard: false
    }).addTo(mapa);
  }

  function seleccionar(id, centrar) {
    var anterior = marcadores[seleccionada];
    if (anterior) {
      anterior.marcador.setIcon(icono(anterior.obra, false));
      anterior.marcador.setZIndexOffset(0);
    }
    seleccionada = id;
    var actual = marcadores[id];
    if (!actual) return;
    actual.marcador.setIcon(icono(actual.obra, true));
    actual.marcador.setZIndexOffset(1000);
    if (centrar) mapa.panTo(actual.marcador.getLatLng());
  }
  if (seleccionada && marcadores[seleccionada]) {
    mapa.setView(marcadores[seleccionada].marcador.getLatLng(), Math.max(mapa.getZoom(), 16));
  }

  window.almiraMapa = { seleccionar: function (id) { seleccionar(id, true); } };
  window.addEventListener('message', function (evento) {
    if (window.parent === window || evento.source !== window.parent) return;
    var m = evento.data;
    if (m && m.tipo === 'seleccionar' && (typeof m.id === 'string' || m.id === null)) seleccionar(m.id, true);
  });

  if (D.interactivo) {
    L.control.zoom({ position: 'topright', zoomInTitle: 'Acercar', zoomOutTitle: 'Alejar' }).addTo(mapa);
    var Recentrar = L.Control.extend({
      options: { position: 'bottomright' },
      onAdd: function () {
        var caja = L.DomUtil.create('div', 'leaflet-bar');
        var boton = L.DomUtil.create('button', 'almira-recentrar', caja);
        boton.type = 'button';
        boton.title = 'Volver a centrar el mapa';
        boton.setAttribute('aria-label', 'Volver a centrar el mapa');
        boton.innerHTML = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8Zm8.94 3A8.99 8.99 0 0 0 13 3.06V1h-2v2.06A8.99 8.99 0 0 0 3.06 11H1v2h2.06A8.99 8.99 0 0 0 11 20.94V23h2v-2.06A8.99 8.99 0 0 0 20.94 13H23v-2h-2.06ZM12 19a7 7 0 1 1 0-14 7 7 0 0 1 0 14Z"/></svg>';
        L.DomEvent.disableClickPropagation(caja);
        L.DomEvent.on(boton, 'click', encuadrar);
        return caja;
      }
    });
    new Recentrar().addTo(mapa);
  }
})();
</script>
</body>
</html>`;
}
