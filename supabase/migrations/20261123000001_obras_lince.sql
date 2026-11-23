-- Obras reales de la Municipalidad Distrital de Lince, tomadas de Infobras (Contraloría).
-- Consulta del 22 de noviembre de 2026. Fuente: https://infobras.contraloria.gob.pe
--
-- Qué hace:
--   1. Agrega dos columnas a obras: codigo_infobras (para no duplicar al volver a cargar)
--      y nombre_oficial (el nombre registrado en Infobras, sin cambios de redacción).
--   2. Deja sin publicar las obras de ejemplo que Lince tenía antes (no las borra).
--   3. Carga 15 obras finalizadas de Lince, publicadas.
--
-- Criterios:
--   - Se cargan las obras finalizadas cuya fecha de término en Infobras es de 2022 en adelante.
--     Infobras no registra ninguna obra de Lince en ejecución.
--   - Quedan fuera las 4 obras «Sin Ejecución» (la tabla solo admite en ejecución y finalizada)
--     y las anteriores a 2022.
--   - avance_pct es el avance físico que reporta Infobras (la app no lo muestra en finalizadas).
--   - monto_asignado es el monto de contrato de Infobras; 0 significa que no hay dato y la app
--     no lo muestra. monto_ejecutado queda en 0: Infobras no lo informa.
--   - Sin coordenadas: la obra sale en la lista, pero no en el mapa, hasta verificarlas.
--   - Sin fotos: Infobras es de la entidad ejecutora; solo se publican fotos con su permiso.
--
-- Requiere que la municipalidad con slug 'lince' ya exista (en una base nueva, el seed la crea
-- después de las migraciones: allí el insert no carga nada).
-- No crea tablas ni cambia políticas: obras ya tiene municipalidad_id y RLS.
-- Pendiente (igual que 20261109000001): obras usa grant de tabla completa para
-- authenticated, así que las columnas nuevas también quedan escribibles por el personal.

alter table public.obras
  add column codigo_infobras integer,
  add column nombre_oficial text;

create unique index obras_codigo_infobras_unico
  on public.obras (municipalidad_id, codigo_infobras);

update public.obras
set publicada = false
where codigo_infobras is null
  and municipalidad_id = (select id from public.municipalidades where slug = 'lince');

insert into public.obras
  (municipalidad_id, codigo_infobras, nombre, nombre_corto, ubicacion, estado, avance_pct, meta,
   monto_asignado, monto_ejecutado, fotos, publicada, inicio, actualizada_en, hitos, nombre_oficial)
select m.id, v.codigo, v.nombre, v.nombre_corto, v.ubicacion, v.estado, v.avance, v.meta,
       v.monto, 0, 0, true, v.inicio::date, '2026-11-22', '[]'::jsonb, v.oficial
from public.municipalidades m
cross join (values
  (552143, 'Reparación de vías vecinales en la Av. Ignacio Merino', 'arreglo de la Av. Ignacio Merino', 'Av. Ignacio Merino, cuadras 20 a 23', 'finalizada', 97.81, 'may 2026', 470429.53, '2026-05-07', 'REPARACION DE VIAS VECINALES; EN EL(LA) AVENIDA IGNACIO MERINO DISTRITO DE LINCE, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (512478, 'Mejoramiento del parque Mariscal Ramón Castilla', 'parque Mariscal Ramón Castilla', 'Parque Mariscal Ramón Castilla', 'finalizada', 100, 'jun 2025', 3474640.75, '2025-03-21', 'MEJORAMIENTO DEL SERVICIOS DE ESPACIOS PÚBLICOS URBANOS EN PARQUE MARISCAL RAMON CASTILLA DISTRITO DE LINCE DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (524809, 'Mejoramiento de la losa deportiva Luisa Fuentes Quijandría', 'losa deportiva Luisa Fuentes Quijandría', 'Parque Mariscal Ramón Castilla Norte', 'finalizada', 100, 'feb 2025', 1363044.69, '2024-12-11', 'MEJORAMIENTO DEL SERVICIO DE PRÁCTICA DEPORTIVA Y/O RECREATIVA EN LOSA DEPORTIVA LUISA FUENTES QUIJANDRÍA DISTRITO DE LINCE DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (514912, 'Saldo de obra del Centro Integral de Atención al Adulto Mayor', 'centro integral de atención al adulto mayor', 'Jr. León Velarde 408', 'finalizada', 100, 'jun 2024', 526547.95, '2024-04-23', 'SALDO DE OBRA MEJORAMIENTO Y AMPLIACION DE LOS SERVICIOS DEL CENTRO INTEGRAL DE ATENCIÓN AL ADULTO MAYOR LINCE DEL DISTRITO DE LINCE - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (140101, 'Mejoramiento y ampliación del Centro Integral de Atención al Adulto Mayor', 'centro integral de atención al adulto mayor', 'Jr. León Velarde 408', 'finalizada', 83.51, 'ago 2023', 4530292.95, '2022-01-11', 'MEJORAMIENTO Y AMPLIACION DE LOS SERVICIOS DEL CENTRO INTEGRAL DE ATENCIÓN AL ADULTO MAYOR LINCE DEL DISTRITO DE LINCE - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (140100, 'Centro de operaciones de emergencia distrital y almacén de ayuda humanitaria', 'centro de operaciones de emergencia distrital', 'Parque Pedro Ruiz Gallo', 'finalizada', 98.49, 'feb 2023', 1924828.98, '2022-08-05', 'MEJORAMIENTO DEL SERVICIO DEL CENTRO DE OPERACIONES DE EMERGENCIA DISTRITAL (COED), Y DEL ALMACÉN DE BIENES DE AYUDA HUMANITARIA DE LINCE DEL DISTRITO DE LINCE - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (167167, 'Sistema de riego de las áreas verdes del parque Ramón Castilla', 'sistema de riego del parque Ramón Castilla', 'Parque Ramón Castilla', 'finalizada', 100, 'nov 2022', 241742.07, '2022-11-09', 'CONSTRUCCIÓN DE LINEA DE CONDUCCIÓN, CAPTACIÓN DE AGUA, VÁLVULA DE CONTROL Y FILTROS DE ANILLAS PARA TRATAMIENTO; EN EL(LA) SISTEMA DE RIEGO DE LAS AREAS VERDES EN EL DISTRITO DE LINCE, EN LA LOCALIDAD DE LINCE, DISTRITO DE LINCE, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (174106, 'Saldo de obra de la cancha del parque Ramón Castilla', 'cancha del parque Ramón Castilla', 'Jr. Joaquín Bernal, cuadras 6 a 10', 'finalizada', 14.99, 'nov 2022', 1133328.47, '2022-09-10', 'SALDO DE OBRA REPARACIÓN DE ARMADO DE ALUMBRADO PÚBLICO; CONSTRUCCIÓN DE INFRAESTRUCTURA DEPORTIVA; EN LA MUNICIPALIDAD DISTRITAL DE LINCE - CANCHA DEL PARQUE CASTILLA EN LA LOCALIDAD DE LINCE, DISTRITO DE LINCE, PROVINCIA DE LIMA, DEPARTAMENTO DE LIMA'),
  (160621, 'Reparación de áreas verdes y juegos infantiles inclusivos en seis parques', 'mejoramiento de áreas verdes y juegos infantiles', 'Parques Pedro Ruiz, Clemente Revilla, Santos Dumont, Alfredo Novoa, San Juan Bosco y Ramón Castilla', 'finalizada', 100, 'sep 2022', 687808.45, '2022-07-13', 'REPARACION DE AREA VERDE; ADQUISICION DE BANCA Y JUEGOS INFANTILES E INCLUSIVOS; EN EL(LA) PARQUES PEDRO RUIZ - CLEMENTE REVILLA - SANTOS DUMONT - ALFREDO NOVOA - SAN JUAN BOSCO - RAMON CASTILLA EN LA LOCALIDAD LINCE, DISTRITO DE LINCE, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (141346, 'Mejoramiento del servicio de seguridad ciudadana', 'mejoramiento de la seguridad ciudadana', 'Distrito de Lince', 'finalizada', 100, 'sep 2022', 486278.4, '2021-06-22', 'MEJORAMIENTO DEL SERVICIO DE SEGURIDAD CIUDADANA EN LOS DIVERSOS SECTORES DEL DISTRITO LINCE - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (156671, 'Reparación del pavimento y gimnasio del parque Ramón Castilla', 'gimnasio del parque Ramón Castilla', 'Parque Ramón Castilla', 'finalizada', 100, 'jul 2022', 655864.71, '2022-04-12', 'REPARACIÓN DE PAVIMENTO, GIMNASIO Y; ADQUISICIÓN DE EQUIPO DE OTROS ACTIVOS COMPLEMENTARIOS; EN EL(LA) PARQUE RAMÓN CASTILLA EN LA LOCALIDAD LINCE, DISTRITO DE LINCE, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (156446, 'Reparación de veredas y pavimento en los jirones Soledad y Los Jazmines', 'arreglo de veredas de los jirones Soledad y Los Jazmines', 'Jr. Soledad, cuadras 2 a 5, y Jr. Los Jazmines, cuadras 1 a 5', 'finalizada', 75.52, 'jul 2022', 432962.66, '2022-04-12', 'ADQUISICION DE EQUIPOS COMPLEMENTARIOS; REPARACION DE VEREDA, PAVIMENTO Y JARDINERA; EN EL(LA) JR. SOLEDAD Y JR. LOS JAZMINES, PARA EL SERVICIO DE MOVILIDAD URBANA, EN LA LOCALIDAD LINCE, DISTRITO DE LINCE, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (149331, 'Renovación del vivero municipal', 'vivero municipal', 'Parque Ramón Castilla', 'finalizada', 75.24, 'jul 2022', 342395.82, '2022-04-30', 'RENOVACION DE CERCO PERIMETRICO; CONSTRUCCION DE PLANTA DE VALORIZACION; ADQUISICION DE EQUIPO DE AMBIENTES DE PROCESOS OPERACIONALES Y CAMION BARANDA; EN EL(LA) VIVERO MUNICIPAL EN LA LOCALIDAD LINCE, DISTRITO DE LINCE, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (145347, 'Reparación de veredas y mobiliario urbano en Mariscal Las Heras e Ignacio Merino', 'arreglo de veredas de Mariscal Las Heras e Ignacio Merino', 'Calle Mariscal Las Heras, cuadras 2 y 3, y Av. Ignacio Merino, cuadras 21 y 22', 'finalizada', 100, 'mar 2022', 470699.3, '2022-01-26', 'ADQUISICION DE MOBILIARIO URBANO; REPARACION DE VEREDA; EN EL(LA) CALLES MARISCAL LAS HERAS E IGNACIO MERINO DE LA MUNICIPALIDAD DISTRITAL DE LINCE EN LA LOCALIDAD LINCE, DISTRITO DE LINCE, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (150453, 'Reparación de vereda y riego en el parque Elías Aguirre', 'parque Elías Aguirre', 'Parque Elías Aguirre', 'finalizada', 99.19, 'mar 2022', 454757.55, '2022-01-07', 'REPARACIÓN DE VEREDA; ADQUISICIÓN DE BANCA Y SISTEMA DE RIEGO; EN EL (LA) PARQUE ELÍAS AGUIRRE, ZONA EN LA LOCALIDAD LINCE, DISTRITO DE LINCE, PROVINCIA LIMA, DEPARTAMENTO LIMA')
) as v (codigo, nombre, nombre_corto, ubicacion, estado, avance, meta, monto, inicio, oficial)
where m.slug = 'lince'
on conflict (municipalidad_id, codigo_infobras) do nothing;
