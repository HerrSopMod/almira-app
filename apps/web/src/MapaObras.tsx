import {
  colors,
  coloresMapa,
  encuadreMapa,
  estilosMarcador,
  htmlMarcador,
  MAPA_ATRIBUCION_HTML,
  MAPA_TILES,
  MAPA_ZOOM_MAXIMO,
  obrasConUbicacion,
  type CentroMapa,
  type Obra,
} from '@almira/shared';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useEffect, useMemo, useRef, useState } from 'react';
import { MapContainer, Marker, TileLayer, useMap, ZoomControl } from 'react-leaflet';
import { AvisoInfo } from './componentes';

const ESTILOS_MARCADOR = estilosMarcador(coloresMapa(colors));
// Errores de teselas seguidos, sin ninguna cargada, antes de mostrar la nota.
const ERRORES_MAXIMOS = 4;
// La nota de MAPA.md, con la tabla del panel en lugar de la lista de la app.
const NOTA_ERROR_PANEL =
  'No se pudo cargar el mapa. Revisa tu conexión. La tabla de obras sigue arriba.';

function icono(obra: Obra) {
  return L.divIcon({
    className: 'almira-icono',
    html: htmlMarcador(obra, false),
    iconSize: [0, 0],
    iconAnchor: [0, 0],
  });
}

// Sin el prefijo "Leaflet": solo la atribución de OpenStreetMap, como en la maqueta.
function SinPrefijo() {
  const mapa = useMap();
  useEffect(() => {
    mapa.attributionControl.setPrefix(false);
  }, [mapa]);
  return null;
}

// "Vista del vecino" (web-06): las obras publicadas con ubicación, como en la app.
// Al cambiar «Publicada», el marcador aparece o desaparece al instante.
export function MapaObras({ obras, centro }: { obras: Obra[]; centro: CentroMapa }) {
  const enMapa = obrasConUbicacion(obras);
  // El encuadre se calcula una vez, para que el mapa no salte al publicar o despublicar.
  const encuadre = useMemo(
    () => encuadreMapa(obrasConUbicacion(obras), centro),
    [centro],
  );
  const [error, setError] = useState(false);
  const cargadas = useRef(0);
  const errores = useRef(0);

  if (error) return <AvisoInfo>{NOTA_ERROR_PANEL}</AvisoInfo>;

  return (
    <div className="mapa-vecino">
      <style>{ESTILOS_MARCADOR}</style>
      <MapContainer
        {...(encuadre.tipo === 'centro'
          ? { center: encuadre.centro, zoom: encuadre.zoom }
          : { bounds: encuadre.limites })}
        zoomControl={false}
        scrollWheelZoom={false}
        className="mapa-vecino-lienzo"
      >
        <SinPrefijo />
        <TileLayer
          url={MAPA_TILES}
          attribution={MAPA_ATRIBUCION_HTML}
          maxZoom={MAPA_ZOOM_MAXIMO}
          eventHandlers={{
            tileload: () => {
              cargadas.current += 1;
              errores.current = 0;
            },
            tileerror: () => {
              errores.current += 1;
              if (cargadas.current === 0 && errores.current >= ERRORES_MAXIMOS) setError(true);
            },
          }}
        />
        <ZoomControl position="topright" zoomInTitle="Acercar" zoomOutTitle="Alejar" />
        {enMapa.map((obra) => (
          <Marker
            key={obra.id}
            position={[obra.latitud, obra.longitud]}
            icon={icono(obra)}
            title={obra.nombre}
            alt={obra.nombre}
          />
        ))}
      </MapContainer>
    </div>
  );
}
