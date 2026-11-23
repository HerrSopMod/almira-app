-- Coordenadas aproximadas de obras que Infobras no ubica en su mapa.
-- Salen de OpenStreetMap (https://www.openstreetmap.org/copyright), buscando el nombre del lugar:
-- solo se cargaron obras cuyo lugar es un parque, plaza, edificio o polideportivo identificable.
-- Quedan sin punto las obras de calles largas, zonas y asentamientos sin dirección clara.
-- Solo llena obras sin coordenadas y descarta puntos fuera de Lima Metropolitana.
--
--   548670: Plaza Italia
--   554731: Palacio Legislativo, Jr. Andahuaylas
--   537803: edificio Giacoletti, Av. Nicolás de Piérola
--   158464: convento de Santo Domingo
--   144884: plazuela del Teatro (mismo punto que 501193)
--   508517: parque Ernesto García Calderón
--   506958: parque 12 de Octubre
--   536198: parque Ramiro Prialé
--   536199: parque Antonio de la Guerra
--   562413: parque Uchumayo
--   562416: parque Francisco Changanaquí
--   562417: parque Corazón de Jesús
--   518410: polideportivo Ichiro Arakaki
--   536730: parque Villa Alejandro

update public.obras o
set latitud = v.latitud, longitud = v.longitud
from (values
  ('cercado-de-lima', 548670, -12.05072, -77.0228),
  ('cercado-de-lima', 554731, -12.04797, -77.025306),
  ('cercado-de-lima', 537803, -12.05123, -77.035575),
  ('cercado-de-lima', 158464, -12.04371, -77.03206),
  ('cercado-de-lima', 144884, -12.04705, -77.034268),
  ('la-victoria', 508517, -12.0818, -77.011176),
  ('la-victoria', 506958, -12.06583, -77.006151),
  ('la-victoria', 536198, -12.07675, -77.013309),
  ('la-victoria', 536199, -12.08039, -77.020198),
  ('la-victoria', 562413, -12.07054, -77.010908),
  ('la-victoria', 562416, -12.08608, -77.019912),
  ('la-victoria', 562417, -12.08275, -77.010466),
  ('lurin', 518410, -12.27159, -76.870574),
  ('lurin', 536730, -12.23607, -76.910053)
) as v (slug, codigo, latitud, longitud)
join public.municipalidades m on m.slug = v.slug
where o.municipalidad_id = m.id
  and o.codigo_infobras = v.codigo
  and o.latitud is null
  and o.longitud is null
  and v.latitud between -12.6 and -11.5
  and v.longitud between -77.3 and -76.5;
