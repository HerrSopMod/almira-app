-- Prueba de la separación entre código de contribuyente y número de cuponera.
-- Corre todo dentro de una excepción final, así que no deja nada guardado:
--   supabase db query --linked -f supabase/tests/separacion_codigos.sql
-- Debe terminar con un error que empieza con "RESULTADO" y no contiene "FALLA".
-- Requiere las migraciones hasta 20261111000004 y el seed de contribuyentes.

do $$
declare
  u uuid := gen_random_uuid();
  m uuid;
  r text := '';
  ok boolean;
  leido text;
begin
  insert into auth.users (id, aud, role, email)
  values (u, 'authenticated', 'authenticated', 'rollback-' || u::text || '@invalido.local');
  select id into m from public.municipalidades where slug = 'pueblo-libre';

  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  set local role authenticated;

  -- El código de contribuyente NO vincula.
  ok := public.vincular_contribuyente(m, 'PUL-0002', '72046183');
  r := r || case when ok then 'FALLA: el código vinculó | ' else 'codigo_no_vincula=OK | ' end;

  -- La cuponera con el DNI equivocado NO vincula.
  ok := public.vincular_contribuyente(m, '6204891735', '00000000');
  r := r || case when ok then 'FALLA: DNI malo vinculó | ' else 'dni_malo=OK | ' end;

  -- La cuponera correcta con su DNI sí vincula, y desde entonces se ven los datos propios.
  ok := public.vincular_contribuyente(m, '6204891735', '72046183');
  r := r || case when ok then 'cuponera_vincula=OK | ' else 'FALLA: la cuponera no vinculó | ' end;
  r := r || case when (select count(*) from public.vecinos) = 1 then 've_su_fila=OK | ' else 'FALLA: no ve su fila | ' end;

  -- El código de contribuyente es legible; el número de cuponera, no, ni con select *.
  select codigo_contribuyente into leido from public.vecinos limit 1;
  r := r || case when leido = 'PUL-0002' then 'lee_codigo=OK | ' else 'FALLA: no lee el código | ' end;
  begin
    perform numero_cuponera from public.vecinos;
    r := r || 'FALLA: leyó numero_cuponera | ';
  exception when insufficient_privilege then
    r := r || 'cuponera_oculta=OK | ';
  end;
  begin
    execute 'select * from public.vecinos';
    r := r || 'FALLA: select * funcionó | ';
  exception when insufficient_privilege then
    r := r || 'select_estrella_bloqueado=OK | ';
  end;

  raise exception 'RESULTADO %', r;
end $$;
