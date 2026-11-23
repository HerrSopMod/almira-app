-- Obras reales de la Municipalidad Distrital de Lurín, tomadas de Infobras (Contraloría).
-- Consulta del 22 de noviembre de 2026. Fuente: https://infobras.contraloria.gob.pe
--
-- Qué hace:
--   1. Agrega dos columnas a obras: codigo_infobras (para no duplicar al volver a cargar)
--      y nombre_oficial (el nombre registrado en Infobras, sin cambios de redacción).
--   2. Crea la municipalidad de Lurín solo si aún no existe (es un dato, no código).
--   3. Carga 24 obras: 17 publicadas y 7 sin publicar.
--
-- Criterios:
--   - Publicadas: las obras en ejecución con fechas vigentes y las finalizadas desde 2024,
--     sin repetir las etapas de videovigilancia.
--   - Sin publicar: registros «en ejecución» desactualizados en Infobras (fin previsto entre
--     2015 y 2024) y dos etapas repetidas. Quedan guardados para que el personal los revise.
--   - avance_pct es el avance físico que reporta Infobras (0 si no lo reporta).
--   - monto_asignado es el monto de contrato de Infobras; 0 significa que no hay dato y la
--     app no lo muestra. monto_ejecutado queda en 0: Infobras no lo informa.
--   - Sin coordenadas: la obra sale en la lista, pero no en el mapa, hasta verificarlas.
--   - Sin fotos: Infobras es de la entidad ejecutora; solo se publican fotos con su permiso.
--
-- No crea tablas ni cambia políticas: obras ya tiene municipalidad_id y RLS.
-- Pendiente (igual que 20261109000001): obras usa grant de tabla completa para
-- authenticated, así que las columnas nuevas también quedan escribibles por el personal.

alter table public.obras
  add column codigo_infobras integer,
  add column nombre_oficial text;

create unique index obras_codigo_infobras_unico
  on public.obras (municipalidad_id, codigo_infobras);

insert into public.municipalidades (slug, nombre, zona)
values ('lurin', 'Municipalidad Distrital de Lurín', 'Lima Sur')
on conflict (slug) do nothing;

insert into public.obras
  (municipalidad_id, codigo_infobras, nombre, nombre_corto, ubicacion, estado, avance_pct, meta,
   monto_asignado, monto_ejecutado, fotos, publicada, inicio, actualizada_en, hitos, nombre_oficial)
select m.id, v.codigo, v.nombre, v.nombre_corto, v.ubicacion, v.estado, v.avance, v.meta,
       v.monto, 0, 0, v.publicada, v.inicio::date, '2026-11-22', '[]'::jsonb, v.oficial
from public.municipalidades m
cross join (values
  (559956, 'Renovación del complejo deportivo Villa Libertad', 'complejo deportivo Villa Libertad', 'Complejo deportivo Villa Libertad, Zona C', 'en_ejecucion', 87.47, 'oct 2026', 1361418.68, true, '2026-08-01', 'RENOVACION DE INFRAESTRUCTURA DEPORTIVA; EN EL(LA) COMPLEJO DEPORTIVO CENTRO POBLADO RURAL (CPR) VILLA LIBERTAD- MZ X1 LOTE ÚNICO, ZONA C DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (557113, 'Creación del PRONOEI de Las Viñas de José Gálvez', 'PRONOEI de Las Viñas de José Gálvez', 'Psje. Andrés A. Cáceres, Mz. D Lote 3, Zona E', 'en_ejecucion', 74.2, 'oct 2026', 779705.24, true, '2026-06-09', 'CREACION DEL SERVICIO DE EDUCACIÓN INICIAL - PRONOEI, EN LA MZ. D LOTE 3, A.H. LAS VIÑAS DE JOSÉ GÁLVEZ, ZONA E, DISTRITO DE LURIN - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (555253, 'Centro de cuidado diurno en Las Virreynas, I etapa', 'centro de cuidado diurno de Las Virreynas', 'Urb. Las Virreynas, Zona B', 'en_ejecucion', 44.59, 'feb 2027', 0, true, '2026-05-04', 'CREACION DEL SERVICIO DE PROTECCIÓN Y CUIDADO DIURNO PARA POBLACIÓN VULNERABLE EN RIESGO DE DESPROTECCIÓN EN ASOCIACIÓN DE PROPIETARIOS DE LA URBANIZACIÓN LAS VIRREYNAS, MZ. B´ PARTE DE PARCELA B-84-84-A EDF.PIS. /REF. ZONA B DISTRITO DE LURIN DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA I ETAPA, con CUI N.°2719762'),
  (549961, 'Mejoramiento del estadio municipal Guadulfo Silva Carbajal, saldo 2', 'estadio municipal Guadulfo Silva Carbajal', 'Estadio municipal Guadulfo Silva Carbajal, Zona B', 'en_ejecucion', 28.48, 'sep 2026', 14500047.43, true, '2026-04-01', 'SALDO 2 DE OBRA DEL PROYECTO DE INCVERSIÓN: "MEJORAMIENTO Y AMPLIACION DEL SERVICIO DE PRÁCTICA DEPORTIVA EN EL ESTADIO MUNICIPAL GUADULFO SILVA CARBAJAL, ZONA B DEL DISTRITO DE LURIN - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (538068, 'Alumbrado público en Cruz del Portillo', 'alumbrado público de Cruz del Portillo', 'Calle Los Jazmines, calle La Molina y prol. El Portillo, Zona C', 'en_ejecucion', 91.67, 'jun 2026', 970518.73, true, '2025-04-24', 'CONSTRUCCION DE ARMADO DE ALUMBRADO PUBLICO; EN EL(LA) CALLE LOS JAZMINES, CALLE LA MOLINA Y PROLONGACIÓN EL PORTILLO; CENTRO POBLADO RURAL CRUZ DEL PORTILLO DE RINCONADA DE PURUHUAY, ZONA C, DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (544745, 'Vereda y área verde en Nuevo Lurín Km 40, II etapa', 'vereda y área verde de Nuevo Lurín Km 40', 'A.H. Nuevo Lurín Km 40 y anexos, Zona A', 'finalizada', 99.07, 'may 2026', 0, true, '2025-08-04', 'CONSTRUCCIÓN DE VEREDA Y ÁREA VERDE; EN EL(LA) A.H. NUEVO LURÍN KM. 40 Y ANEXOS ETAPA PRIMERA - ZONA A DISTRITO DE LURÍN, PROVINCIA LIMA, DEPARTAMENTO LIMA II ETAPA'),
  (540067, 'Renovación de vereda y área verde en Villa Alejandro', 'veredas y áreas verdes de Villa Alejandro', 'Avenidas y calles del P.J. Villa Alejandro, Zona E', 'finalizada', 98.07, 'abr 2026', 3259639.92, true, '2025-07-03', 'RENOVACION DE VEREDA Y AREA VERDE; EN EL(LA) DEL SERVICIO DE MOVILIDAD URBANA EN AVENIDAS Y CALLES DEL PUEBLO JOVEN VILLA ALEJANDRO, ZONA E, DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (518410, 'Mejoramiento del estadio municipal, saldo de obra', 'estadio municipal Guadulfo Silva Carbajal', 'Polideportivo Ichiro Arakaki, Zona B', 'finalizada', 42.58, 'ago 2025', 1080000, true, '2024-10-10', 'SALDO DE OBRA: MEJORAMIENTO Y AMPLIACION DEL SERVICIO DE PRACTICA DEPORTIVA EN EL ESTADIO MUNICIPAL GUADULFO SILVA CARBAJAL - ZONA B, DISTRITO DE LURIN, PROVINCIA DE LIMA, DEPARTAMENTO DE LIMA'),
  (525884, 'Sede central de videovigilancia de seguridad ciudadana', 'sede de videovigilancia de seguridad ciudadana', 'Antigua Panamericana Sur, altura paradero La Cruz, Jr. Independencia, Zona D', 'finalizada', 97.22, 'jul 2025', 1669883.91, true, '2025-01-07', 'CREACION DEL SERVICIO DE SEGURIDAD CIUDADANA LOCAL EN LA SEDE CENTRAL DE VIDEOVIGILANCIA EN EL DISTRITO DE LURIN DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA" - con código único Nº2573356 - Componente 01 ADECUADA INFRAESTRUCTURA DE SEGURIDAD CIUDADANA - JULIO C. TELLO - ZONA D'),
  (522278, 'Servicios bibliotecarios en Nuevo Lurín Km 40', 'biblioteca de Nuevo Lurín Km 40', 'Mz. 12 lote Bibl., A.H. Nuevo Lurín Km 40, Zona A', 'finalizada', 100, 'may 2025', 2790683.54, true, '2024-10-11', 'CREACION DE LOS SERVICIOS BIBLIOTECARIOS EN LA MANZANA 12 LOTE BIBL., A.H. NUEVO LURÍN KM. 40 Y ANEXOS ETAPA PRIMERA, ZONA A, DISTRITO DE LURIN DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (520835, 'Vereda y área verde en Nuevo Lurín Km 40, I etapa', 'vereda y área verde de Nuevo Lurín Km 40', 'A.H. Nuevo Lurín Km 40 y anexos, Zona A', 'finalizada', 99.4, 'abr 2025', 0, true, '2024-08-27', 'CONSTRUCCIÓN DE VEREDA Y ÁREA VERDE; EN EL(LA) A.H. NUEVO LURÍN KM. 40 Y ANEXOS ETAPA PRIMERA - ZONA A DISTRITO DE LURÍN, PROVINCIA LIMA, DEPARTAMENTO LIMA I ETAPA, CUI N.º 2652655.'),
  (536730, 'Parque central de Villa Alejandro', 'parque central de Villa Alejandro', 'Mz. S lotes 1 y 2, A.H. Villa Alejandro, Zona E', 'finalizada', 99.87, 'mar 2025', 0, true, '2025-01-28', 'RENOVACIÓN DE ESPACIO DE RECREACION PASIVA Y ESPACIO DE SOCIALIZACION; EN EL(LA) PARQUE CENTRAL UBICADO EN MZ. S LOTE 1 Y MZ. S LOTE 2, DEL A.H. VILLA ALEJANDRO, ZONA E, PARQUE CENTRAL UBICADO EN MZ. S LOTE 1 Y MZ. S LOTE 2, DEL A.H. VILLA ALEJANDRO, ZONA E DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA.'),
  (521023, 'Renovación de losa deportiva en Julio C. Tello, sector II', 'losa deportiva de Julio C. Tello', 'Mz. V4 Lote 1, A.H. Julio C. Tello, sector II, Zona D', 'finalizada', 100, 'ene 2025', 680276.44, true, '2024-09-20', 'RENOVACION DE LOSA DEPORTIVA; EN EL(LA) MZ. V4 LOTE 1, A.H. JULIO C. TELLO, SECTOR II, ZONA D, DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (518937, 'Renovación de pista, vereda y área verde en Julio C. Tello, sector I', 'pistas y veredas de Julio C. Tello', 'Av. Las Palmas y calle Los Naranjos, A.H. Julio C. Tello, sector I, Zona D', 'finalizada', 99.27, 'dic 2024', 2155649.25, true, '2024-08-22', 'RENOVACION DE PISTA, VEREDA Y AREA VERDE; EN EL(LA) MANZANAS: E, E1, E2, E3, F, F1, F2, F3, G, G1, G2, G3, G4, H, H1, H2, H3, H4, H5, H6, H7, H8, H9 Y K; DEL A.H. JULIO C. TELLO, SECTOR I, ZONA D, DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (514939, 'Remodelación de la sede municipal de servicios para la mujer y el adulto mayor', 'sede de servicios para la mujer y el adulto mayor', 'Mz. 2 Lote 19, A.H. Nuevo Lurín Km 40, Zona A', 'finalizada', 98.57, 'sep 2024', 1364319.65, true, '2024-05-01', 'REMODELACION DE EDIFICACION; EN EL(LA) SEDE MUNICIPAL PARA LOS SERVICIOS INTEGRALES DE LA MUJER Y DEL ADULTO MAYOR EN LA MZ. 2 LOTE 19, A.H. NUEVO LURÍN KM. 40 Y ANEXOS, ETAPA: SEGUNDA, ZONA A, DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (509645, 'Transitabilidad peatonal en Julio C. Tello', 'veredas peatonales de Julio C. Tello', 'A.H. Julio C. Tello, Zona D', 'finalizada', 83.25, 'abr 2024', 1538974.16, true, '2023-12-12', 'CREACION DEL SERVICIO DE TRANSITABILIDAD PEATONAL EN MZ: G, G1, F1, F2, G2, H2, E3, F3, G3 DEL A.H. JULIO C. TELLO, ZONA D DEL DISTRITO DE LURIN - PROVINCIA DE LIMA - DEPARTAMENTO DE LIMA'),
  (502874, 'Práctica deportiva y recreativa en UPIS San José de Lurín', 'espacio deportivo de UPIS San José de Lurín', 'Mz. Z1 Lote 01, UPIS San José de Lurín, Zona E', 'finalizada', 100, 'ene 2024', 1991193.95, true, '2023-08-05', 'CREACION DEL SERVICIO DE PRACTICA DEPORTIVA Y/O RECREATIVA EN MANZANA Z1 LOTE 01, UPIS SAN JOSE DE LURIN, ZONA E, DISTRITO DE LURIN DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (521481, 'Sede central de videovigilancia, II etapa', 'sede de videovigilancia de seguridad ciudadana', 'Antigua Panamericana Sur, Zona D', 'finalizada', 98.3, 'oct 2024', 0, false, '2024-08-13', 'CREACION DEL SERVICIO DE SEGURIDAD CIUDADANA LOCAL EN LA SEDE CENTRAL DE VIDEOVIGILACIA EN EL DISTRITO DE LURIN DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA - COMPONENTE 01 ADECUADA INFRAESTRUCTURA DE SEGURIDAD CIUDADANA COMPONENTE 01 - ADECUADA INFRAESTRUCTURA DE SEGURIDAD CIUDADANA'),
  (509650, 'Sede central de videovigilancia, I etapa', 'sede de videovigilancia de seguridad ciudadana', 'Mz. 2 Lote 9, A.H. Nuevo Lurín Km 40, I etapa, Zona A', 'finalizada', 55.97, 'jul 2024', 1524512.82, false, '2023-12-14', 'CREACION DEL SERVICIO DE SEGURIDAD CIUDADANA LOCAL EN LA SEDE CENTRAL DE VIDEOVIGILACIA EN EL DISTRITO DE LURIN DE LA PROVINCIA DE LIMA DEL DEPARTAMENTO DE LIMA'),
  (518707, 'Renovación del complejo deportivo José Fuentes (Chapeta)', 'complejo deportivo José Fuentes', 'Km 40, Av. Antigua Panamericana Sur, Zona A', 'en_ejecucion', 14.25, 'oct 2023', 0, false, '2023-07-10', 'RENOVACION DE INFRAESTRUCTURA DEPORTIVA; EN EL(LA) COMPLEJO DEPORTIVO JOSE FUENTES (CHAPETA) KM 40 AV. ANTIGUA PANAMERICANA SUR, ZONA A, DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (518708, 'Renovación de losa deportiva en Martha Milagros Baja', 'losa deportiva de Martha Milagros', 'Mz. B Lote 2, sector Martha Milagros Baja, Zona E', 'en_ejecucion', 0, 'sep 2023', 0, false, '2023-08-01', 'RENOVACION DE LOSA DEPORTIVA; EN EL(LA) MZ. B LOTE 2, A.H. PROYECTO INTEGRAL MARTHA MILAGROS 1º DE DICIEMBRE, SECTOR MARTHA MILAGROS BAJA, ZONA E, DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (518366, 'Renovación del centro deportivo Villa Alejandro (Cuatro Losas)', 'centro deportivo de Villa Alejandro', 'Mz. P Lote 1, P.J. Villa Alejandro, Zona E', 'en_ejecucion', 0, 'sep 2024', 0, false, '2024-03-22', 'RENOVACION DE INFRAESTRUCTURA DEPORTIVA; EN EL(LA) CENTRO DEPORTIVO VILLA ALEJANDRO (CUATRO LOSAS), MANZANA P LOTE 1, PUEBLO JOVEN VILLA ALEJANDRO, ZONA E, DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (132624, 'Remodelación de parques temáticos', 'parques temáticos', 'Distrito', 'en_ejecucion', 0, 'nov 2019', 0, false, '2019-10-30', 'REMODELACION DE PARQUES TEMÁTICOS; EN EL(LA) PARQUES TEMÁTICOS DISTRITO DE LURIN, PROVINCIA LIMA, DEPARTAMENTO LIMA'),
  (29777, 'Seguridad ciudadana, componente 1: ambientes del servicio', 'ambientes de seguridad ciudadana', 'Distrito', 'en_ejecucion', 98.81, 'sep 2015', 0, false, '2015-01-20', 'MEJORAMIENTO Y AMPLIACIÓN DEL SERVICIO DE SEGURIDAD CIUDADANA - DISTRITO DE LURIN - LIMA - LIMA - COMPONENTE 1 ADECUADOS AMBIENTES PARA LA PRESTACIÓN DEL SERVICIO')
) as v (codigo, nombre, nombre_corto, ubicacion, estado, avance, meta, monto, publicada, inicio, oficial)
where m.slug = 'lurin'
on conflict (municipalidad_id, codigo_infobras) do nothing;
