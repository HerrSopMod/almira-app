-- Coordenadas de las obras para el mapa real de OpenStreetMap.
-- Son columnas nulas: una obra sin coordenadas sale en la lista pero no en el mapa.
-- No cambia permisos: la tabla ya tiene municipalidad_id y RLS.

alter table public.obras
  add column latitud double precision check (latitud between -90 and 90),
  add column longitud double precision check (longitud between -180 and 180);
