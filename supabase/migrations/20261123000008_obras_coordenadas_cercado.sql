-- Coordenadas de obras del Cercado de Lima, tomadas del mapa de Infobras (Contraloría).
-- Consulta del 23 de noviembre de 2026. Infobras entrega latitud y longitud invertidas; aquí ya van en su orden.
-- Solo llena obras sin coordenadas y descarta puntos fuera de Lima Metropolitana.
-- Sin punto en Infobras (sin ubicación en el mapa): 547110, 547348, 537803, 548670, 554731 y 160047.
-- Quedan fuera por revisar: 158464 (trae dos puntos), 144884 (su punto no coincide con 501193, la misma plazuela)
-- y 160050 (el punto queda lejos de la Av. Tacna que indica su dirección).

update public.obras o
set latitud = v.latitud, longitud = v.longitud
from (values
  (547490, -12.050937, -77.023845),
  (160046, -12.0474708, -77.0227996),
  (553173, -12.044152, -77.050794),
  (538277, -12.058876, -77.040571),
  (153811, -12.0454349, -77.0276831),
  (160048, -12.0499391, -77.0119929),
  (513491, -12.053866, -77.032411),
  (160045, -12.0473475, -77.0223892),
  (501193, -12.04705, -77.034268),
  (128243, -12.0473259, -77.0290175),
  (141614, -12.0534291, -77.0379514)
) as v (codigo, latitud, longitud)
join public.municipalidades m on m.slug = 'cercado-de-lima'
where o.municipalidad_id = m.id
  and o.codigo_infobras = v.codigo
  and o.latitud is null
  and o.longitud is null
  and v.latitud between -12.6 and -11.5
  and v.longitud between -77.3 and -76.5;
