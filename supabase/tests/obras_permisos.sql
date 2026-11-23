-- Prueba de los permisos por columna de obras (20261123000004). No escribe nada:
--   supabase db query --linked -f supabase/tests/obras_permisos.sql
-- Debe terminar con un error que empieza con "RESULTADO" y no contiene "FALLA".

do $$
declare
  r text := '';
  c text;
begin
  -- Columnas que el personal edita.
  foreach c in array array['nombre', 'ubicacion', 'estado', 'avance_pct', 'publicada', 'actualizada_en', 'hitos'] loop
    r := r || case when has_column_privilege('authenticated', 'public.obras', c, 'UPDATE')
                   then '' else 'FALLA: no puede cambiar ' || c || ' | ' end;
  end loop;

  -- Columnas que solo escribe service_role.
  foreach c in array array['id', 'municipalidad_id', 'creado_en', 'fotos', 'codigo_infobras', 'nombre_oficial', 'latitud', 'longitud'] loop
    r := r || case when has_column_privilege('authenticated', 'public.obras', c, 'UPDATE')
                   then 'FALLA: puede cambiar ' || c || ' | ' else '' end;
  end loop;
  foreach c in array array['id', 'creado_en', 'fotos', 'codigo_infobras', 'nombre_oficial', 'latitud', 'longitud'] loop
    r := r || case when has_column_privilege('authenticated', 'public.obras', c, 'INSERT')
                   then 'FALLA: puede insertar ' || c || ' | ' else '' end;
  end loop;
  r := r || case when has_column_privilege('authenticated', 'public.obras', 'municipalidad_id', 'INSERT')
                 then '' else 'FALLA: no puede crear obras | ' end;

  -- Sin permiso de tabla completa, y nada para anon ni para borrar.
  r := r || case when has_table_privilege('authenticated', 'public.obras', 'UPDATE')
                 then 'FALLA: sigue el grant de tabla completa | ' else '' end;
  r := r || case when has_table_privilege('authenticated', 'public.obras', 'DELETE')
                 then 'FALLA: authenticated puede borrar | ' else '' end;
  r := r || case when has_any_column_privilege('anon', 'public.obras', 'INSERT, UPDATE')
                 then 'FALLA: anon puede escribir | ' else '' end;

  raise exception 'RESULTADO %', case when r = '' then 'todo OK' else r end;
end
$$;
