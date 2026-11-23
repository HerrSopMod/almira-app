-- Obras: el personal escribe solo las columnas que edita, no la tabla completa.
-- Cierra el pendiente de 20261031000002_rls.sql y 20261109000001_obras_ubicacion.sql (CLAUDE.md:
-- escrituras desde el cliente solo con permisos por columna y política explícita).
--
-- Antes: grant insert, update on public.obras to authenticated (todas las columnas).
-- Ahora el personal de la municipalidad puede escribir:
--   nombre, nombre_corto, ubicacion, estado, avance_pct, meta, monto_asignado, monto_ejecutado,
--   publicada, inicio, actualizada_en, porcentaje_tributos e hitos.
--   Al crear una obra, además municipalidad_id (la política exige que sea la suya).
-- Solo service_role escribe:
--   id, creado_en y fotos (las pone la base o el servidor),
--   codigo_infobras y nombre_oficial (salen tal cual de Infobras),
--   latitud y longitud (se cargan verificadas; el panel no tiene pantalla para fijarlas).
-- Los vecinos siguen sin escribir: las políticas exigen ser personal de la municipalidad.
--
-- REVOKE a nivel de tabla también quita los permisos por columna de ese tipo, así que primero
-- se revoca y después se concede por columna.

revoke insert, update on public.obras from authenticated;

grant insert (
  municipalidad_id, nombre, nombre_corto, ubicacion, estado, avance_pct, meta,
  monto_asignado, monto_ejecutado, publicada, inicio, actualizada_en, porcentaje_tributos, hitos
) on public.obras to authenticated;

grant update (
  nombre, nombre_corto, ubicacion, estado, avance_pct, meta,
  monto_asignado, monto_ejecutado, publicada, inicio, actualizada_en, porcentaje_tributos, hitos
) on public.obras to authenticated;

-- Políticas explícitas (las mismas de 20261031000002, recreadas para dejarlas junto a los permisos).
drop policy if exists "personal registra obras" on public.obras;
create policy "personal registra obras" on public.obras
  for insert to authenticated
  with check (privado.es_personal_de(municipalidad_id));

drop policy if exists "personal actualiza obras" on public.obras;
create policy "personal actualiza obras" on public.obras
  for update to authenticated
  using (privado.es_personal_de(municipalidad_id))
  with check (privado.es_personal_de(municipalidad_id));
