-- Datos ficticios para desarrollo local. Coinciden con packages/shared/src/datos-ejemplo.ts.

insert into public.municipalidades (id, slug, nombre, zona, telefono_ayuda, aviso_destacado) values
  ('00000000-0000-4000-8000-000000000001', 'lince', 'Municipalidad de Lince', 'Lima Centro', null, null),
  ('00000000-0000-4000-8000-000000000002', 'villa-verde', 'Municipalidad de Villa Verde', 'Lima Sur', null, null),
  ('00000000-0000-4000-8000-000000000003', 'miraflores-este', 'Municipalidad de Miraflores del Este', 'Lima Este', null, null),
  ('00000000-0000-4000-8000-000000000004', 'san-isidro-nuevo', 'Municipalidad de San Isidro Nuevo', 'Lima Norte', null, null);

insert into public.obras
  (municipalidad_id, nombre, nombre_corto, ubicacion, estado, avance_pct, meta, monto_asignado, monto_ejecutado,
   fotos, publicada, inicio, actualizada_en, porcentaje_tributos, hitos)
values
  ('00000000-0000-4000-8000-000000000001', 'Mantenimiento de pistas', 'mantenimiento de pistas de la Av. Ignacio Merino',
   'Av. Ignacio Merino, cdras. 17-19', 'finalizada', 100, 'oct 2026', 680000, 680000,
   0, true, null, '2026-10-29', null, '[]'),
  ('00000000-0000-4000-8000-000000000001', 'Renovación del parque Castilla', 'parque Castilla',
   'Parque Castilla, Zona 3', 'en_ejecucion', 68, 'feb 2027', 920000, 610000,
   0, true, '2026-06-03', '2026-10-26', 62,
   '["Riego y áreas verdes: 80 %", "Juegos y luminarias: en curso"]'),
  ('00000000-0000-4000-8000-000000000001', 'Veredas accesibles', 'proyecto de veredas accesibles de la Av. Risso',
   'Av. Risso, cdras. 3-7', 'en_ejecucion', 34, 'mar 2027', 410000, 139400,
   0, true, null, '2026-10-14', null, '[]'),
  ('00000000-0000-4000-8000-000000000001', 'Luminarias LED', 'cambio a luminarias LED del Jr. Pumacahua',
   'Jr. Pumacahua y alrededores', 'en_ejecucion', 0, 'jun 2027', 265000, 0,
   0, false, null, '2026-10-30', null, '[]'),
  ('00000000-0000-4000-8000-000000000002', 'Mejoramiento del Parque Central', 'Parque Central',
   'Av. Los Sauces cdra. 3', 'en_ejecucion', 40, 'dic 2026', 300000, 120000,
   2, true, null, '2026-10-20', null, '[]');
