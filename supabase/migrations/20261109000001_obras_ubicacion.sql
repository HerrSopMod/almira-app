-- Coordenadas de las obras para el mapa real de OpenStreetMap.
-- Son columnas nulas: una obra sin coordenadas sale en la lista pero no en el mapa.
-- No crea tablas ni agrega permisos: la tabla ya tiene municipalidad_id y RLS.
-- Pendiente: obras usa grant de tabla completa para authenticated
-- (20261031000002_rls.sql), así que el personal de la municipalidad también puede
-- escribir estas columnas mediante "personal actualiza obras". Pasar a permisos por
-- columna según CLAUDE.md.

alter table public.obras
  add column latitud double precision check (latitud between -90 and 90),
  add column longitud double precision check (longitud between -180 and 180);
