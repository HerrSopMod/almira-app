import type { Obra } from './types';

// Mapa real de OpenStreetMap dibujado con Leaflet (docs/design/turquesa/MAPA.md).
export const MAPA_TILES = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
export const MAPA_ATRIBUCION = '© colaboradores de OpenStreetMap';
export const MAPA_ATRIBUCION_URL = 'https://www.openstreetmap.org/copyright';
// Centro de Lima, solo para cuando no hay ningún punto que mostrar.
export const MAPA_CENTRO_POR_DEFECTO = { latitud: -12.0464, longitud: -77.0428 } as const;
export const MAPA_ZOOM_POR_DEFECTO = 15;

export interface MarcadorMapa {
  id: string;
  latitud: number;
  longitud: number;
  // Texto corto dentro de la píldora, por ejemplo "68". Sin texto se dibuja un punto.
  texto?: string;
  // Más chica la píldora si está concluida.
  concluido?: boolean;
}

export interface ColoresMapa {
  primario: string;
  exito: string;
  superficie: string;
  texto: string;
}

export interface OpcionesMapa {
  marcadores: MarcadorMapa[];
  seleccionadaId?: string | null;
  interactivo: boolean;
  colores: ColoresMapa;
}

const LEAFLET_CSS = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
const LEAFLET_CSS_SRI = 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=';
const LEAFLET_JS = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
const LEAFLET_JS_SRI = 'sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=';

// Solo las obras publicadas y con coordenadas salen en el mapa.
export function obrasConUbicacion(obras: Obra[]): Obra[] {
  return obras.filter((o) => o.publicada && o.latitud != null && o.longitud != null);
}

export function marcadoresDeObras(obras: Obra[]): MarcadorMapa[] {
  return obrasConUbicacion(obras).map((o) => ({
    id: o.id,
    latitud: o.latitud as number,
    longitud: o.longitud as number,
    texto: String(o.avancePct),
    concluido: o.estado === 'finalizada',
  }));
}

// Límites [[sur, oeste], [norte, este]] para fitBounds, o null si no hay puntos.
export function encuadreMapa(
  puntos: { latitud: number; longitud: number }[],
): [[number, number], [number, number]] | null {
  if (puntos.length === 0) return null;
  const lats = puntos.map((p) => p.latitud);
  const lngs = puntos.map((p) => p.longitud);
  return [
    [Math.min(...lats), Math.min(...lngs)],
    [Math.max(...lats), Math.max(...lngs)],
  ];
}

// Evita que los datos cierren la etiqueta <script> del HTML.
const aJson = (valor: unknown) => JSON.stringify(valor).replace(/</g, '\\u003c');

export function htmlMapa({ marcadores, seleccionadaId, interactivo, colores }: OpcionesMapa): string {
  const datos = aJson({
    marcadores,
    seleccionadaId: seleccionadaId ?? null,
    interactivo,
    colores,
    tiles: MAPA_TILES,
    atribucion: `<a href="${MAPA_ATRIBUCION_URL}">${MAPA_ATRIBUCION}</a>`,
    centro: MAPA_CENTRO_POR_DEFECTO,
    zoom: MAPA_ZOOM_POR_DEFECTO,
  });
  return `<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<link rel="stylesheet" href="${LEAFLET_CSS}" integrity="${LEAFLET_CSS_SRI}" crossorigin="">
<style>
html,body,#mapa{height:100%;margin:0;background:#EEF3F3}
.pin{display:flex;align-items:center;justify-content:center;min-width:34px;height:34px;box-sizing:border-box;
border-radius:17px;border:2px solid var(--sup);color:var(--sup);font:600 12px Inter,system-ui,sans-serif;
padding:0 6px;box-shadow:0 1px 4px rgba(0,0,0,.3)}
.sel{transform:scale(1.2)}
</style></head>
<body><div id="mapa"></div>
<script src="${LEAFLET_JS}" integrity="${LEAFLET_JS_SRI}" crossorigin=""></script>
<script>
var D = ${datos};
function enviar(m){
  if (window.ReactNativeWebView) window.ReactNativeWebView.postMessage(JSON.stringify(m));
  else parent.postMessage(m, '*');
}
var mapa = L.map('mapa', {
  zoomControl: D.interactivo, dragging: D.interactivo, scrollWheelZoom: D.interactivo,
  touchZoom: D.interactivo, doubleClickZoom: D.interactivo, boxZoom: D.interactivo,
  keyboard: D.interactivo, attributionControl: true
}).setView([D.centro.latitud, D.centro.longitud], D.zoom);
mapa.attributionControl.setPrefix(false);
var fallos = 0;
var capa = L.tileLayer(D.tiles, { maxZoom: 19, attribution: D.atribucion });
capa.on('tileerror', function(){ if (++fallos >= 4) enviar({ tipo: 'error' }); });
capa.on('load', function(){ enviar({ tipo: 'listo' }); });
capa.addTo(mapa);
document.documentElement.style.setProperty('--sup', D.colores.superficie);
var puntos = [];
D.marcadores.forEach(function(m){
  var fondo = m.concluido ? D.colores.exito : D.colores.primario;
  var html = m.texto
    ? '<div class="pin' + (m.id === D.seleccionadaId ? ' sel' : '') + '" style="background:' + fondo + '">' + m.texto + '</div>'
    : '<div class="pin" style="background:' + fondo + ';min-width:22px;height:22px;border-radius:11px;padding:0"></div>';
  var icono = L.divIcon({ html: html, className: '', iconSize: m.texto ? [34, 34] : [22, 22], iconAnchor: m.texto ? [17, 17] : [11, 11] });
  var marcador = L.marker([m.latitud, m.longitud], { icon: icono, keyboard: false }).addTo(mapa);
  if (D.interactivo) marcador.on('click', function(){ enviar({ tipo: 'obra', id: m.id }); });
  puntos.push([m.latitud, m.longitud]);
});
if (puntos.length === 1) mapa.setView(puntos[0], D.zoom + 1);
else if (puntos.length > 1) mapa.fitBounds(puntos, { padding: [40, 40], maxZoom: 17 });
</script></body></html>`;
}
