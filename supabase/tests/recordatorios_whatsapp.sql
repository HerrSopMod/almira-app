-- Prueba de los recordatorios por WhatsApp en la base: activar y desactivar, permisos, y qué
-- avisos devuelve `recordatorios_candidatos`. Todo ocurre dentro de una excepción final, así que
-- no queda nada guardado:
--   supabase db query --linked -f supabase/tests/recordatorios_whatsapp.sql
-- Debe terminar con un error que empieza con "RESULTADO" y no contiene "FALLA".
-- Requiere la migración 20261112000002 y el seed de contribuyentes (usa PUL-0002, Pueblo Libre).

do $$
declare
  u uuid := gen_random_uuid();
  otro uuid := gen_random_uuid();
  v uuid;
  m uuid;
  d uuid;
  r text := '';
  res text;
  n integer;
  hoy date := (now() at time zone 'America/Lima')::date;
begin
  insert into auth.users (id, aud, role, email)
  values (u, 'authenticated', 'authenticated', 'rollback-' || u::text || '@invalido.local'),
         (otro, 'authenticated', 'authenticated', 'rollback-' || otro::text || '@invalido.local');
  select id into m from public.municipalidades where slug = 'pueblo-libre';
  select id into v from public.vecinos where municipalidad_id = m and codigo_contribuyente = 'PUL-0002';
  update public.vecinos set user_id = u where id = v;
  select id into d from public.deudas where vecino_id = v and saldo > 0 and estado <> 'pagada' limit 1;

  -- --- Como el vecino ---
  perform set_config('request.jwt.claims', json_build_object('sub', u, 'role', 'authenticated')::text, true);
  set local role authenticated;

  res := public.activar_whatsapp('12345', 'wa-2026-11-12-v1');
  r := r || case when res = 'numero_invalido' then 'numero_invalido=OK | ' else 'FALLA: aceptó un número malo | ' end;
  res := public.activar_whatsapp('987654321', 'MAL VERSION');
  r := r || case when res = 'version_invalida' then 'version_invalida=OK | ' else 'FALLA: aceptó una versión mala | ' end;
  res := public.activar_whatsapp('987654321', 'wa-2026-11-12-v1');
  r := r || case when res = 'ok' then 'activa=OK | ' else 'FALLA: no activó (' || res || ') | ' end;

  select count(*) into n from public.preferencias_notificacion
   where whatsapp_activo and whatsapp_numero = '+51987654321' and consentimiento_at is not null and optout_at is null;
  r := r || case when n = 1 then 've_su_preferencia=OK | ' else 'FALLA: no ve su preferencia | ' end;

  -- No puede escribir directo (el sello de consentimiento lo pone el servidor).
  begin
    update public.preferencias_notificacion set whatsapp_activo = true;
    r := r || 'FALLA: actualizó directo | ';
  exception when insufficient_privilege then
    r := r || 'sin_escritura_directa=OK | ';
  end;
  begin
    insert into public.recordatorios_enviados (municipalidad_id, contribuyente_id, tipo, periodo, plantilla)
    values (m, v, 'bienvenida', 'x', 'x');
    r := r || 'FALLA: escribió el log | ';
  exception when insufficient_privilege then
    r := r || 'sin_escritura_log=OK | ';
  end;
  -- No puede pedir los candidatos.
  begin
    perform * from public.recordatorios_candidatos();
    r := r || 'FALLA: ejecutó los candidatos | ';
  exception when insufficient_privilege then
    r := r || 'sin_candidatos_para_vecino=OK | ';
  end;
  -- No hay columna de cuponera ni de DNI en las tablas nuevas.
  begin
    perform numero_cuponera from public.preferencias_notificacion;
    r := r || 'FALLA: existe numero_cuponera | ';
  exception when undefined_column then
    r := r || 'sin_cuponera=OK | ';
  end;

  -- Otro usuario no ve nada de lo ajeno.
  reset role;
  perform set_config('request.jwt.claims', json_build_object('sub', otro, 'role', 'authenticated')::text, true);
  set local role authenticated;
  select count(*) into n from public.preferencias_notificacion;
  r := r || case when n = 0 then 'aislamiento=OK | ' else 'FALLA: ve preferencias ajenas | ' end;
  res := public.activar_whatsapp('987654321', 'wa-2026-11-12-v1');
  r := r || case when res = 'sin_vinculo' then 'sin_vinculo=OK | ' else 'FALLA: activó sin contribuyente | ' end;

  -- --- Como el servidor ---
  reset role;
  set local role service_role;

  -- Deuda que vence dentro de 3 días: sale un aviso de vencimiento.
  update public.deudas set vencimiento = hoy + 3 where id = d;
  select count(*) into n from public.recordatorios_candidatos() where vecino_id = v and tipo = 'vencimiento';
  r := r || case when n = 1 then 'vence_en_3_dias=OK | ' else 'FALLA: vencimiento (' || n || ') | ' end;
  update public.deudas set vencimiento = hoy + 4 where id = d;
  select count(*) into n from public.recordatorios_candidatos() where vecino_id = v and tipo = 'vencimiento';
  r := r || case when n = 0 then 'no_a_los_4_dias=OK | ' else 'FALLA: avisó a 4 días | ' end;

  -- Deuda vencida: aviso de pendiente; una vez registrado, no vuelve a salir en 15 días.
  update public.deudas set vencimiento = hoy - 10 where id = d;
  select count(*) into n from public.recordatorios_candidatos() where vecino_id = v and tipo = 'pendiente';
  r := r || case when n = 1 then 'pendiente=OK | ' else 'FALLA: pendiente (' || n || ') | ' end;
  insert into public.recordatorios_enviados (municipalidad_id, contribuyente_id, tipo, periodo, plantilla, estado)
  values (m, v, 'pendiente', hoy::text, 'almira_pendiente', 'enviado');
  select count(*) into n from public.recordatorios_candidatos() where vecino_id = v and tipo = 'pendiente';
  r := r || case when n = 0 then 'pendiente_una_vez_cada_15_dias=OK | ' else 'FALLA: repitió el pendiente | ' end;

  -- Misma restricción única: no se puede registrar dos veces el mismo tipo y periodo.
  begin
    insert into public.recordatorios_enviados (municipalidad_id, contribuyente_id, tipo, periodo, plantilla)
    values (m, v, 'pendiente', hoy::text, 'almira_pendiente');
    r := r || 'FALLA: permitió un duplicado | ';
  exception when unique_violation then
    r := r || 'idempotente=OK | ';
  end;

  -- Saldo 0: no hay nada que avisar.
  delete from public.recordatorios_enviados where contribuyente_id = v;
  update public.deudas set pagos_aplicados = monto_insoluto + gastos_emision + interes_actualizacion - descuento,
                           estado = 'pagada'
   where vecino_id = v;
  select count(*) into n from public.recordatorios_candidatos() where vecino_id = v and tipo in ('vencimiento', 'pendiente');
  r := r || case when n = 0 then 'saldo_cero=OK | ' else 'FALLA: avisó con saldo 0 | ' end;

  -- Baja: ya no sale ningún aviso aunque haya deuda.
  update public.deudas set pagos_aplicados = 0, estado = 'vencida' where id = d;
  select count(*) into n from public.recordatorios_candidatos() where vecino_id = v;
  r := r || case when n >= 1 then 'hay_candidato=OK | ' else 'FALLA: no hay candidato | ' end;
  update public.preferencias_notificacion set optout_at = now(), whatsapp_activo = false where contribuyente_id = v;
  select count(*) into n from public.recordatorios_candidatos() where vecino_id = v;
  r := r || case when n = 0 then 'baja=OK | ' else 'FALLA: avisó a quien dio de baja | ' end;

  reset role;
  raise exception 'RESULTADO: %', r;
end;
$$;
