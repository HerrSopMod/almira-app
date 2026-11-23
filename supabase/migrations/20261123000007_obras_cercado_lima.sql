-- Obras reales de la Municipalidad Metropolitana de Lima en el Cercado de Lima, tomadas de Infobras (Contraloría).
-- Consulta del 23 de noviembre de 2026. Fuente: https://infobras.contraloria.gob.pe
--
-- Qué hace:
--   1. Crea la municipalidad 'cercado-de-lima' solo si no existe ninguna con ese slug o ese nombre.
--   2. Carga 20 obras: 14 publicadas y 6 sin publicar.
--
-- Criterios:
--   - Solo obras con distrito Lima en la ficha de Infobras. La entidad también ejecuta obras en otros
--     distritos (San Juan de Lurigancho, Ate, Villa El Salvador…): no se cargaron.
--   - Quedan fuera las obras que abarcan varios distritos (ciclovías, luminarias, vías nuevas y similares).
--   - Publicadas: obras en ejecución con término previsto de 2026 en adelante y finalizadas desde 2024.
--   - Sin publicar: finalizadas de 2022 y 2023 y obras «en ejecución» con término vencido en 2025 o antes,
--     para que el personal decida.
--   - Quedan fuera las «Sin Ejecución» (la tabla solo admite en ejecución y finalizada), las anteriores
--     a 2022 y los registros «en ejecución» desactualizados.
--   - avance_pct es el avance físico que reporta Infobras (0 si no lo reporta).
--   - monto_asignado es el monto de contrato de Infobras; 0 significa que no hay dato y la app no lo
--     muestra. monto_ejecutado queda en 0: Infobras no lo informa.
--   - Sin coordenadas ni fotos: la obra sale en la lista, pero no en el mapa, hasta verificarlas.
--
-- Requiere las columnas codigo_infobras y nombre_oficial (migración 20261123000001).
-- No crea tablas ni cambia políticas: obras ya tiene municipalidad_id y RLS.

insert into public.municipalidades (slug, nombre, zona)
select 'cercado-de-lima', 'Municipalidad de Lima (Cercado)', 'Lima Centro'
where not exists (
  select 1 from public.municipalidades
  where slug = 'cercado-de-lima' or nombre = 'Municipalidad de Lima (Cercado)'
);

insert into public.obras
  (municipalidad_id, codigo_infobras, nombre, nombre_corto, ubicacion, estado, avance_pct, meta,
   monto_asignado, monto_ejecutado, fotos, publicada, inicio, actualizada_en, hitos, nombre_oficial)
select m.id, v.codigo, v.nombre, v.nombre_corto, v.ubicacion, v.estado, v.avance, v.meta,
       v.monto, 0, 0, v.publicada, v.inicio::date, '2026-11-23', '[]'::jsonb, v.oficial
from public.municipalidades m
cross join (values
  (547490, 'Recuperación del Antiguo Real Hospital de San Andrés', 'Real Hospital de San Andrés', 'Jirón Huallaga 846', 'en_ejecucion', 6.73, 'sep 2028', 0, true, '2025-09-15', 'RECUPERACION DEL SERVICIO DE INTERPRETACIÓN CULTURAL EN EL ANTIGUO REAL HOSPITAL DE SAN ANDRÉS DE CENTRO POBLADO LIMA DISTRITO DE LIMA DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (160046, 'Reparación de la iglesia de Las Trinitarias', 'iglesia de Las Trinitarias', 'Centro Histórico de Lima', 'en_ejecucion', 93.53, 'jun 2028', 0, true, '2023-06-12', 'REPARACION DE LUGARES HISTÓRICOS O CULTURALES; EN EL(LA) IGLESIA DE LAS TRINITARIAS EN LA LOCALIDAD LIMA, DISTRITO DE LIMA, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (547110, 'Reparación de fachadas monumentales del eje Áncash, zona San Francisco', 'fachadas del eje Áncash', 'Centro Histórico de Lima, eje Áncash', 'en_ejecucion', 7.44, 'mar 2027', 0, true, '2025-10-07', 'REPARACION DE OBRAS EXTERIORES; EN EL(LA) LAS FACHADAS DE CARÁCTER MONUMENTAL Y VALOR MONUMENTAL EN LA ZONA DE INTERVENCIÓN 01: SAN FRANCISCO DEL EJE ESTRUCTURANTE ÁNCASH, DEL CENTRO HISTÓRICO DE LIMA DISTRITO DE LIMA, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (547348, 'Mejoramiento de la movilidad urbana en las vías de los ejes Áncash y Junín', 'movilidad de los ejes Áncash y Junín', 'Centro Histórico de Lima, ejes Áncash y Junín', 'en_ejecucion', 3.91, 'ene 2027', 0, true, '2025-10-09', 'MEJORAMIENTO DEL SERVICIO DE MOVILIDAD URBANA EN LAS VIAS LOCALES DEL EJE ESTRUCTURANTE ANCASH Y JUNÍN EN EL CENTRO HISTÓRICO DE LIMA DISTRITO DE LIMA DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (537803, 'Restauración del edificio Giacoletti', 'edificio Giacoletti', 'Centro Histórico de Lima', 'en_ejecucion', 41.32, 'dic 2026', 35280483.48, true, '2025-08-15', 'RECUPERACION RESTAURACION Y PUESTA EN VALOR DEL EDIFICIO GIACOLLETI, EN EL CENTRO HISTORICO DE LIMA DEL DISTRITO DE LIMA - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (553173, 'Creación de la central de seguridad ciudadana de Cercado de Lima', 'central de seguridad ciudadana', 'Cercado de Lima', 'en_ejecucion', 0, 'nov 2026', 15697037.21, true, '2026-07-08', 'CREACION DEL SERVICIO DE SEGURIDAD CIUDADANA LOCAL EN LA CENTRAL DISTRITAL DE OPERACIONES DE SEGURIDAD CIUDADANA EN CERCADO DE LIMA DE CENTRO POBLADO LIMA DISTRITO DE LIMA DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (548670, 'Mejoramiento de espacios públicos en la Plaza Italia', 'Plaza Italia', 'Plaza Italia', 'en_ejecucion', 13.03, 'oct 2026', 0, true, '2025-10-09', 'MEJORAMIENTO DEL SERVICIOS DE ESPACIOS PÚBLICOS URBANOS EN PLAZA ITALIA DISTRITO DE LIMA DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (538277, 'Creación del Boulevard Bicentenario, cuadra 4 de la Av. Paraguay', 'Boulevard Bicentenario', 'Av. Paraguay, cuadra 4', 'en_ejecucion', 49.04, 'ago 2026', 7713833.51, true, '2025-10-29', 'CREACION DEL BOULEVARD BICENTENARIO EN LA CUADRA 4 DE LA AV. PARAGUAY EN EL CENTRO HISTÓRICO DE LIMA DEL DISTRITO DE LIMA - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (554731, 'Mejoramiento de la interpretación cultural del Palacio Legislativo', 'Palacio Legislativo', 'Jr. Andahuaylas s/n', 'finalizada', 98.24, 'jul 2026', 0, true, '2026-02-24', 'MEJORAMIENTO DEL SERVICIO DE INTERPRETACIÓN CULTURAL EN EL PALACIO LEGISLATIVO DEL CONGRESO DE LA REPÚBLICA DISTRITO DE LIMA DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (153811, 'Mejoramiento de la plazuela de San Francisco', 'plazuela de San Francisco', 'Centro Histórico de Lima, eje Áncash', 'en_ejecucion', 22.87, 'jun 2026', 4557239.64, true, '2022-05-16', 'MEJORAMIENTO Y REMODELACION DEL SERVICIO DE RECREACIÓN PASIVA EN LA PLAZUELA DE SAN FRANCISCO DE LA ZONA DE INTERVENCIÓN 01: SAN FRANCISCO DEL EJE ESTRUCTURANTE ÁNCASH, EN EL CENTRO HISTÓRICO DE LIMA DEL DISTRITO DE LIMA - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (160048, 'Reparación de la iglesia de Santiago del Cercado', 'iglesia de Santiago del Cercado', 'Cercado de Lima', 'en_ejecucion', 61.87, 'may 2026', 0, true, '2023-08-18', 'REPARACION DE LUGARES HISTÓRICOS O CULTURALES; EN EL(LA) IGLESIA DE SANTIAGO DEL CERCADO EN LA LOCALIDAD LIMA, DISTRITO DE LIMA, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (160047, 'Reparación de la iglesia Santo Cristo de las Maravillas', 'iglesia Santo Cristo de las Maravillas', 'Centro Histórico de Lima', 'en_ejecucion', 74.1, 'may 2026', 0, true, '2023-08-19', 'REPARACION DE LUGARES HISTÓRICOS O CULTURALES; EN EL(LA) IGLESIA SANTO CRISTO DE LAS MARAVILLAS EN LA LOCALIDAD LIMA, DISTRITO DE LIMA, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (513491, 'Mejoramiento de la iglesia de San Carlos, Panteón Nacional de los Próceres', 'iglesia de San Carlos', 'Av. Nicolás de Piérola 1220', 'en_ejecucion', 88.4, 'abr 2026', 0, true, '2024-02-12', 'MEJORAMIENTO DEL SERVICIO DE INTERPRETACIÓN CULTURAL EN LA IGLESIA DE SAN CARLOS SANTUARIO PANTEÓN NACIONAL DE LOS PRÓCERES DISTRITO DE LIMA DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA LIMA - LIMA - LIMA'),
  (160050, 'Reparación de la iglesia Nuestra Señora del Prado', 'iglesia Nuestra Señora del Prado', 'Av. Tacna 100, esquina con Jr. Conde de Superunda', 'en_ejecucion', 91.63, 'oct 2025', 0, false, '2023-08-11', 'REPARACION DE LUGARES HISTÓRICOS O CULTURALES; EN EL(LA) IGLESIA DE NUESTRA SEÑORA DEL PRADO EN LA LOCALIDAD LIMA, DISTRITO DE LIMA, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (501193, 'Mejoramiento de la plazuela del Teatro', 'plazuela del Teatro', 'Jr. Huancavelica 200', 'en_ejecucion', 100, 'dic 2024', 0, false, '2022-08-29', 'MEJORAMIENTO Y REMODELACIÓN DEL SERVICIO DE RECREACIÓN PASIVA EN LA PLAZUELA DEL TEATRO DE LA ZONA DE INTERVENCIÓN 02: SAN MARCELO, EJE ESTRUCTURANTE CUSCO EMANCIPACIÓN, EN EL CENTRO HISTÓRICO DE LIMA DEL DISTRITO DE LIMA - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (160045, 'Reparación de la iglesia de La Buena Muerte', 'iglesia de La Buena Muerte', 'Centro Histórico de Lima', 'finalizada', 100, 'nov 2024', 0, true, '2023-04-03', 'REPARACION DE LUGARES HISTÓRICOS O CULTURALES; EN EL(LA) IGLESIA DE LA BUENA MUERTE CENTRO HISTÓRICO DE LIMA DISTRITO DE LIMA, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (128243, 'Letreros turísticos y vías de acceso en el Centro Histórico', 'letreros turísticos del Centro Histórico', 'Centro Histórico de Lima', 'finalizada', 100, 'dic 2023', 0, false, '2020-10-03', 'ADQUISICION DE LETREROS TURISTICOS, STANDS O PUESTOS Y VIAS DE ACCESO; EN EL(LA) CENTRO HISTORICO DE LIMA, DISTRITO DE LIMA, PROVINCIA DE LIMA, DPTO. DE LIMA CENTRO HISTORICO DE LIMA DISTRITO DE LIMA, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (141614, 'Reparación de la iglesia de La Recoleta', 'iglesia de La Recoleta', 'Cercado de Lima', 'finalizada', 84.73, 'nov 2022', 0, false, '2020-12-15', 'REPARACION DE LUGARES HISTÓRICOS O CULTURALES; EN EL(LA) IGLESIA DE LA RECOLETA EN LA LOCALIDAD LIMA, DISTRITO DE LIMA, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (158464, 'Reparación de la iglesia y convento de Santo Domingo', 'iglesia de Santo Domingo', 'Jr. Camaná con Jr. Conde de Superunda', 'finalizada', 14.66, 'nov 2022', 5958787.53, false, '2022-02-22', 'REPARACION DE EDIFICACION; EN EL(LA) MONUMENTO HISTORICO DE LA IGLESIA Y CONVENTO DE SANTO DOMINGO EN LA LOCALIDAD LIMA, DISTRITO DE LIMA, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (144884, 'Mejoramiento de la plazuela del Teatro, primera etapa', 'plazuela del Teatro', 'Jr. Huancavelica 200', 'finalizada', 8.46, 'may 2022', 0, false, '2021-09-22', 'MEJORAMIENTO Y REMODELACIÓN DEL SERVICIO DE RECREACIÓN PASIVA EN LA PLAZUELA DEL TEATRO DE LA ZONA DE INTERVENCIÓN 02: SAN MARCELO, EJE ESTRUCTURANTE CUSCO EMANCIPACIÓN, EN EL CENTRO HISTÓRICO DE LIMA DEL DISTRITO DE LIMA - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA')
) as v (codigo, nombre, nombre_corto, ubicacion, estado, avance, meta, monto, publicada, inicio, oficial)
where m.nombre = 'Municipalidad de Lima (Cercado)' or m.slug = 'cercado-de-lima'
on conflict (municipalidad_id, codigo_infobras) do nothing;
