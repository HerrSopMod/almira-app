-- Coordenadas de las obras tomadas del mapa de Infobras (Contraloría), consulta del 2026-11-23.
-- Generada con supabase/scripts/infobras-coordenadas.js. Infobras entrega latitud y longitud
-- invertidas: el script reconoce cada una por su rango en Lima.
-- Solo llena obras sin coordenadas (no pisa una ubicación ya verificada) y descarta puntos fuera
-- de Lima Metropolitana. 48 de 98 obras quedan sin punto.

update public.obras o
set latitud = v.latitud, longitud = v.longitud
from (values
  ('lince', 552143, -12.084436, -77.032463),
  ('lince', 524809, -12.087558, -77.039473),
  ('lince', 514912, -12.082909, -77.039368),
  ('lince', 140101, -12.08297, -77.03935),
  ('lince', 140100, -12.0857914, -77.0356667),
  ('lince', 167167, -12.08888, -77.04166),
  ('lince', 174106, -12.0855556, -77.0355556),
  ('lince', 160621, -12.082519, -77.031095),
  ('lince', 141346, -12.0833345, -77.0317876),
  ('lince', 156671, -12.089224, -77.0427278),
  ('lince', 156446, -12.0900001, -77.0291428),
  ('lince', 149331, -12.0880483, -77.0397081),
  ('lince', 145347, -12.0861111, -77.0322222),
  ('lince', 150453, -12.0833333, -77.0333333),
  ('lurin', 559956, -12.242458, -76.874047),
  ('lurin', 557113, -12.2329152662402, -76.9058827093115),
  ('lurin', 549961, -12.271222, -76.870228),
  ('lurin', 518366, -12.23643, -76.908874),
  ('lurin', 132624, -12.2774502, -76.8689203),
  ('lurin', 29777, -12.2558891, -76.8893838),
  ('la-victoria', 553748, -12.087725, -77.020029),
  ('la-victoria', 554625, -12.064838, -77.018689),
  ('la-victoria', 172060, -12.0719169, -77.0237362),
  ('la-victoria', 547466, -12.0780742735429, -77.0151285382606),
  ('la-victoria', 539788, -12.06387, -77.019164),
  ('la-victoria', 523671, -12.070048, -77.010789),
  ('la-victoria', 537894, -12.083302, -77.016596),
  ('la-victoria', 537995, -12.065654, -77.019225),
  ('la-victoria', 537904, -12.083367, -77.020367),
  ('la-victoria', 537900, -12.082236, -77.019457),
  ('la-victoria', 537898, -12.084851, -77.015966),
  ('la-victoria', 536200, -12.076186, -77.012763),
  ('la-victoria', 523967, -12.087823, -77.019675),
  ('la-victoria', 523996, -12.079446, -77.019659),
  ('la-victoria', 523964, -12.077162, -77.019536),
  ('la-victoria', 523963, -12.077131, -77.025522),
  ('la-victoria', 523962, -12.062118, -77.009027),
  ('la-victoria', 523965, -12.079722, -77.023726),
  ('la-victoria', 157200, -12.0656359, -77.0191073),
  ('la-victoria', 159075, -12.0772478, -77.0216913),
  ('la-victoria', 176673, -12.0644199, -77.0193669),
  ('la-victoria', 150497, -12.0816941, -77.0110784),
  ('la-victoria', 156657, -12.0644748, -77.0202348),
  ('la-victoria', 154169, -12.0644064, -77.0193432),
  ('la-victoria', 159074, -12.0602355, -77.0168624),
  ('la-victoria', 152826, -12.0599752, -77.0253362),
  ('la-victoria', 114653, -12.065789, -77.024562),
  ('la-victoria', 152825, -12.0710109, -77.0211085),
  ('la-victoria', 148645, -12.0704217, -77.0133134),
  ('la-victoria', 151555, -12.0784068, -77.0195249)
) as v (slug, codigo, latitud, longitud)
join public.municipalidades m on m.slug = v.slug
where o.municipalidad_id = m.id
  and o.codigo_infobras = v.codigo
  and o.latitud is null
  and o.longitud is null
  and v.latitud between -12.6 and -11.5
  and v.longitud between -77.3 and -76.5;
