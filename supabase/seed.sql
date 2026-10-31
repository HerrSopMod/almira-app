-- Datos ficticios para desarrollo local. Coinciden con packages/shared/src/datos-ejemplo.ts.

insert into public.municipalidades (id, slug, nombre, zona, telefono_ayuda, aviso_destacado) values
  ('00000000-0000-4000-8000-000000000001', 'santa-aurora', 'Municipalidad de Santa Aurora', 'Lima Centro',
   '01-311-8000 anexo 4', 'Pronto pago: 10% de descuento en arbitrios al cancelar antes del 15 de marzo.'),
  ('00000000-0000-4000-8000-000000000002', 'villa-verde', 'Municipalidad de Villa Verde', 'Lima Sur', null, null),
  ('00000000-0000-4000-8000-000000000003', 'miraflores-este', 'Municipalidad de Miraflores del Este', 'Lima Este', null, null),
  ('00000000-0000-4000-8000-000000000004', 'san-isidro-nuevo', 'Municipalidad de San Isidro Nuevo', 'Lima Norte', null, null);

insert into public.obras
  (municipalidad_id, nombre, ubicacion, avance_pct, meta, monto_asignado, monto_ejecutado, fotos)
values
  ('00000000-0000-4000-8000-000000000001', 'Renovación integral de pistas y veredas - Sector 3',
   'Av. Las Palmeras cdras. 1 al 12', 75, 'Octubre 2025', 1250000, 937500, 8),
  ('00000000-0000-4000-8000-000000000001', 'Construcción de nueva Central de Serenazgo y Cámaras',
   'Jr. Salaverry con Jr. Arica', 30, 'Diciembre 2025', 850000, 255000, 4),
  ('00000000-0000-4000-8000-000000000002', 'Mejoramiento del Parque Central',
   'Av. Los Sauces cdra. 3', 40, 'Noviembre 2025', 300000, 120000, 2);
