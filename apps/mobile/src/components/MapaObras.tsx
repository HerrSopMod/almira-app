import { marcadoresDeObras, sizes, type Obra } from '@almira/shared';
import { router } from 'expo-router';
import { useMemo } from 'react';
import { MapaLeaflet } from './MapaLeaflet';

// Mapa de la pantalla 19: obras publicadas con coordenadas, sobre OpenStreetMap.
// La lista de tarjetas bajo el mapa es el camino accesible.
export function MapaObras({ obras }: { obras: Obra[] }) {
  const marcadores = useMemo(() => marcadoresDeObras(obras), [obras]);
  return (
    <MapaLeaflet
      alto={sizes.mapHeight}
      marcadores={marcadores}
      etiqueta="Mapa de obras"
      onSeleccionar={(id) => router.push({ pathname: '/obras/[id]', params: { id } })}
    />
  );
}
