# Mapa real de obras

Reemplaza el dibujo actual (`MapaObras.tsx`, tokens `drawing*`) por un mapa real de
**OpenStreetMap** dibujado con **Leaflet**. No hace falta API key. Funciona en el teléfono
(Expo), en Expo web y en el panel web.

## Dónde aparece

| Lugar | Qué muestra |
| --- | --- |
| App 19 · Obras | Las obras publicadas, cada una con un marcador con su % de avance. Al tocar un marcador se selecciona su tarjeta |
| App 20 · Detalle de la obra | "Ver en el mapa" abre la pantalla 19 con esa obra seleccionada y centrada |
| App 16 · Nuevo reclamo | Minimapa fijo (sin gestos) con un marcador: el punto del GPS si el vecino tocó "Usar mi ubicación"; si no, el punto de ejemplo del predio |
| Web-06 · Obras publicadas | "Vista del vecino": las obras con «Publicada» activo, como las ve el vecino |

## Datos

1. **Migración nueva** `supabase/migrations/20261109000001_obras_ubicacion.sql`:
   ```sql
   alter table public.obras
     add column latitud double precision check (latitud between -90 and 90),
     add column longitud double precision check (longitud between -180 and 180);
   ```
   - Son columnas nulas. Una obra sin coordenadas sale en la lista, pero no en el mapa.
   - No se abren permisos de escritura nuevos. La tabla ya tiene `municipalidad_id` y RLS.
2. **Tipo `Obra`** (`packages/shared/src/types.ts`): agrega `latitud: number | null` y
   `longitud: number | null`, igual que en `Reclamo`.
3. **Datos de ejemplo** (`datos-ejemplo.ts`) y `supabase/seed.sql`: llena las
   coordenadas. Las de abajo se verificaron en OpenStreetMap (Nominatim y Overpass) el
   8 nov 2026. Las cuadras salen de los números de casa cargados en OSM, así que el punto
   es el medio del tramo, no una dirección exacta. En OSM la vía se llama "Jirón Risso",
   no avenida.

   | Obra | Latitud | Longitud |
   | --- | --- | --- |
   | Mantenimiento de pistas · Av. Ignacio Merino, cdras. 17-19 | -12.0826 | -77.0329 |
   | Renovación del parque Castilla · Parque Mariscal Castilla, Zona 3 | -12.0886 | -77.0414 |
   | Veredas accesibles · Av. Risso, cdras. 3-7 | -12.0852 | -77.0309 |
   | Luminarias LED · Jr. Brigadier Mateo Pumacahua y alrededores (no publicada) | -12.0852 | -77.0431 |
   | Predio de ejemplo · Jr. Bernardo Alcedo 480 | -12.0844 | -77.0315 |

   Si no hay obras con coordenadas, el mapa se centra en el distrito. Agrega
   `latitud`/`longitud` del centro a la municipalidad de ejemplo en los datos compartidos
   (Lince ≈ -12.0850, -77.0360, zoom 15). No escribas esas cifras en la interfaz.

## Código compartido · `packages/shared/src/mapa.ts`

- `MAPA_TILES = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'` y
  `MAPA_ATRIBUCION = '© colaboradores de OpenStreetMap'`, con enlace a
  `https://www.openstreetmap.org/copyright`. **La atribución siempre se ve**: lo exige
  OpenStreetMap.
- `obrasConUbicacion(obras)`: filtra las obras publicadas que tienen coordenadas.
- `encuadreMapa(puntos, centroPorDefecto)`: devuelve los límites para `fitBounds`, con
  margen.
- `htmlMapaObras({ obras, seleccionadaId, interactivo, colores })`: arma un HTML completo
  que carga Leaflet 1.9.4 desde unpkg, con SRI:
  - CSS `https://unpkg.com/leaflet@1.9.4/dist/leaflet.css`
    `integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY="`
  - JS `https://unpkg.com/leaflet@1.9.4/dist/leaflet.js`
    `integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo="`
  - Los colores entran como parámetro desde los tokens; no escribas hex en el HTML.
  - Los marcadores son `L.divIcon` con la píldora de % (ver LEEME.md → Marcador del mapa).
  - Al tocar un marcador, el HTML avisa con `postMessage({ tipo: 'obra', id })`. El HTML
    escucha `{ tipo: 'seleccionar', id }` para centrar y resaltar una obra.
  - Si las teselas fallan (`tileerror` repetido o sin conexión), avisa con
    `{ tipo: 'error' }`.
- Pruebas en `shared.test.ts`: filtro de obras, encuadre con 0, 1 y varios puntos, y que
  el HTML incluya la atribución y no incluya obras no publicadas.

## App móvil

- Instala desde `apps/mobile`: `pnpm exec expo install react-native-webview`.
- `src/components/MapaObras.tsx` (nativo): `WebView` con
  `source={{ html, baseUrl: 'https://github.com/HerrSopMod/almira-app' }}`. El `baseUrl`
  hace que las teselas lleven un *Referer*, que OpenStreetMap exige. Usa `onMessage` para
  la selección e `injectJavaScript` para seleccionar desde la lista.
- `src/components/MapaObras.web.tsx` (Expo web): `<iframe srcDoc={html}>` con
  `window.addEventListener('message', …)`, porque `react-native-webview` no funciona en
  web.
- Alto de 300 px, radio de 16 px y borde de 1 px. Mientras carga, muestra un fondo
  `subtle` con un indicador. Si llega `{ tipo: 'error' }`, cambia el mapa por una nota:
  "No se pudo cargar el mapa. Revisa tu conexión. La lista de obras sigue abajo."
- **Accesibilidad:** la lista de tarjetas bajo el mapa es el camino accesible. El mapa
  lleva `accessibilityLabel="Mapa de obras de {municipalidad}"`.
- Borra los tokens `drawingBlock`, `drawingPark`, `drawingAvenue`, `mapStreet` y
  `mapAvenue` si ya nadie los usa.

## Panel web

- Instala en `apps/web`: `leaflet@1.9.4`, `react-leaflet@5` y, como dependencia de
  desarrollo, `@types/leaflet`. React Leaflet 5 pide React 19 y Leaflet 1.9, que ya
  coinciden.
- `src/MapaObras.tsx` con `MapContainer`, `TileLayer` (`MAPA_TILES` y
  `MAPA_ATRIBUCION`) y `Marker` con el mismo `divIcon`. Importa
  `leaflet/dist/leaflet.css`.
- En web-06, la tarjeta "Vista del vecino" (380 × 300) muestra las obras publicadas. Si
  cambias el interruptor "Publicada", el marcador aparece o desaparece al instante.

## Límites honestos

- Las teselas públicas de OpenStreetMap son para uso ligero. Sirven para un prototipo
  académico, pero no para una app con mucho tráfico; ahí haría falta un proveedor con
  clave.
- Las coordenadas de ejemplo marcan el medio de cada tramo, no una dirección exacta.
- El GPS del reclamo (`expo-location`) solo se usa para el marcador del minimapa: el punto
  todavía no se guarda en el reclamo.
