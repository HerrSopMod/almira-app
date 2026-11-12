-- Recordatorios por WhatsApp (opt-in).
--
-- Dos tablas nuevas:
--   preferencias_notificacion  una fila por contribuyente: si activó WhatsApp, a qué número y con
--                              qué texto legal (versionado) dio su consentimiento.
--   recordatorios_enviados     un registro por mensaje, con restricción única
--                              (contribuyente, tipo, periodo): el envío es idempotente.
--
-- El contribuyente es la fila de `vecinos`. Ninguna de las dos tablas guarda ni recibe el número
-- de cuponera ni el DNI. El cliente solo LEE sus filas; escribe a través de las funciones de
-- abajo (el sello de consentimiento lo pone el servidor) y el log lo escribe únicamente la Edge
-- Function con service_role.

create table public.preferencias_notificacion (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  contribuyente_id uuid not null,
  whatsapp_activo boolean not null default false,
  -- E.164, por ejemplo +51987654321.
  whatsapp_numero text check (whatsapp_numero ~ '^\+[1-9][0-9]{7,14}$'),
  consentimiento_at timestamptz,
  -- Identifica el texto legal que se mostró y aceptó (ver docs/whatsapp-plantillas.md).
  consentimiento_version text,
  -- Se llena cuando la persona responde BAJA, STOP o NO por WhatsApp.
  optout_at timestamptz,
  actualizado_at timestamptz not null default now(),
  unique (contribuyente_id),
  foreign key (municipalidad_id, contribuyente_id)
    references public.vecinos (municipalidad_id, id) on delete cascade,
  -- Activo solo con número y consentimiento.
  check (
    not whatsapp_activo
    or (whatsapp_numero is not null and consentimiento_at is not null and consentimiento_version is not null)
  )
);
create index on public.preferencias_notificacion (municipalidad_id);
create index on public.preferencias_notificacion (whatsapp_numero) where whatsapp_numero is not null;

create table public.recordatorios_enviados (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  contribuyente_id uuid not null,
  tipo text not null check (tipo in ('vencimiento', 'pendiente', 'pago_confirmado', 'bienvenida')),
  -- Qué se avisó: la fecha de vencimiento, el día del aviso, el número de operación, etc.
  periodo text not null,
  plantilla text not null,
  estado text not null default 'en_cola'
    check (estado in ('en_cola', 'enviado', 'entregado', 'leido', 'fallido')),
  wa_message_id text,
  -- Solo un código corto de error de Meta, nunca el mensaje ni el teléfono.
  error_resumen text,
  creado_at timestamptz not null default now(),
  actualizado_at timestamptz not null default now(),
  foreign key (municipalidad_id, contribuyente_id)
    references public.vecinos (municipalidad_id, id) on delete cascade,
  unique (contribuyente_id, tipo, periodo)
);
create index on public.recordatorios_enviados (wa_message_id) where wa_message_id is not null;
create index on public.recordatorios_enviados (contribuyente_id, tipo, creado_at desc);

alter table public.preferencias_notificacion enable row level security;
alter table public.recordatorios_enviados enable row level security;

-- Nada para anon; el vecino autenticado solo lee lo suyo. Sin escrituras desde el cliente.
revoke all on public.preferencias_notificacion from anon, authenticated;
revoke all on public.recordatorios_enviados from anon, authenticated;
-- Las Edge Functions (service_role) leen y escriben las dos tablas: el log y la baja.
grant select, insert, update, delete on public.preferencias_notificacion to service_role;
grant select, insert, update, delete on public.recordatorios_enviados to service_role;
grant select (id, contribuyente_id, whatsapp_activo, whatsapp_numero, consentimiento_at, optout_at, actualizado_at)
  on public.preferencias_notificacion to authenticated;
grant select (id, contribuyente_id, tipo, periodo, plantilla, estado, creado_at)
  on public.recordatorios_enviados to authenticated;

create policy "preferencia propia" on public.preferencias_notificacion
  for select to authenticated
  using (privado.es_vecino_propio(contribuyente_id));

create policy "recordatorio enviado propio" on public.recordatorios_enviados
  for select to authenticated
  using (privado.es_vecino_propio(contribuyente_id));

-- ---------------------------------------------------------------------------------------------
-- El vecino activa, cambia o desactiva su WhatsApp.
-- ---------------------------------------------------------------------------------------------

-- Devuelve 'ok', 'numero_invalido', 'version_invalida', 'sin_vinculo' o 'sin_sesion'.
-- El número llega como 9 dígitos (9XXXXXXXX) o ya en E.164 (+519XXXXXXXX).
create function public.activar_whatsapp(p_numero text, p_version text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_digitos text;
  v_numero text;
  v_vecino record;
begin
  if v_usuario is null then
    return 'sin_sesion';
  end if;
  v_digitos := regexp_replace(coalesce(p_numero, ''), '[^0-9]', '', 'g');
  if v_digitos ~ '^9[0-9]{8}$' then
    v_numero := '+51' || v_digitos;
  elsif v_digitos ~ '^519[0-9]{8}$' then
    v_numero := '+' || v_digitos;
  else
    return 'numero_invalido';
  end if;
  if p_version is null or p_version !~ '^[a-z0-9._-]{3,40}$' then
    return 'version_invalida';
  end if;

  -- El contribuyente de la cuenta (el primero, si tributa en más de una municipalidad).
  select v.id, v.municipalidad_id into v_vecino
  from public.vecinos v
  where v.user_id = v_usuario
  order by v.creado_en
  limit 1;
  if not found then
    return 'sin_vinculo';
  end if;

  insert into public.preferencias_notificacion
    (municipalidad_id, contribuyente_id, whatsapp_activo, whatsapp_numero,
     consentimiento_at, consentimiento_version, optout_at, actualizado_at)
  values
    (v_vecino.municipalidad_id, v_vecino.id, true, v_numero, now(), p_version, null, now())
  on conflict (contribuyente_id) do update
    set whatsapp_activo = true,
        whatsapp_numero = excluded.whatsapp_numero,
        consentimiento_at = excluded.consentimiento_at,
        consentimiento_version = excluded.consentimiento_version,
        optout_at = null,
        actualizado_at = now();
  return 'ok';
end;
$$;

-- Apaga los recordatorios. Conserva el número y el consentimiento anteriores como constancia.
create function public.desactivar_whatsapp()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_filas integer;
begin
  if v_usuario is null then
    return false;
  end if;
  update public.preferencias_notificacion p
  set whatsapp_activo = false, actualizado_at = now()
  from public.vecinos v
  where p.contribuyente_id = v.id and v.user_id = v_usuario;
  get diagnostics v_filas = row_count;
  return v_filas > 0;
end;
$$;

revoke all on function public.activar_whatsapp(text, text) from public, anon;
revoke all on function public.desactivar_whatsapp() from public, anon;
grant execute on function public.activar_whatsapp(text, text) to authenticated;
grant execute on function public.desactivar_whatsapp() to authenticated;

-- ---------------------------------------------------------------------------------------------
-- Qué se debe avisar hoy. El cálculo vive aquí, no en el código del mensaje.
-- ---------------------------------------------------------------------------------------------
-- Solo la Edge Function (service_role) la llama. Devuelve una fila por aviso posible:
--   vencimiento      deudas pendientes (sin coactivo) que vencen dentro de 3 días; una fila por fecha.
--   pendiente        quien tiene alguna deuda vencida y no recibió este aviso en los últimos 15 días.
--   pago_confirmado  pagos confirmados después de dar el consentimiento, de los últimos 7 días.
-- Todas las filas son de contribuyentes con WhatsApp activo, consentimiento y sin baja, y que no
-- tienen ya registrado ese (tipo, periodo). La función de Edge además valida el horario.
-- `saldo_pendiente` es el saldo total del contribuyente; `monto` es el del aviso.

create function public.recordatorios_candidatos(p_ahora timestamptz default now())
returns table (
  vecino_id uuid,
  municipalidad_id uuid,
  municipalidad text,
  nombre text,
  numero text,
  tipo text,
  periodo text,
  tipos text[],
  monto numeric,
  fecha date,
  referencia text,
  con_coactivo boolean,
  saldo_pendiente numeric,
  whatsapp_activo boolean,
  optout_at timestamptz,
  consentimiento_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  with hoy as (
    select (p_ahora at time zone 'America/Lima')::date as dia
  ),
  activos as (
    select v.id as vecino_id,
           v.municipalidad_id,
           m.nombre as municipalidad,
           coalesce(nullif(split_part(coalesce(nullif(v.nombres, ''), v.nombre), ' ', 1), ''), 'vecino') as nombre,
           p.whatsapp_numero as numero,
           p.whatsapp_activo,
           p.optout_at,
           p.consentimiento_at
    from public.preferencias_notificacion p
    join public.vecinos v on v.id = p.contribuyente_id and v.municipalidad_id = p.municipalidad_id
    join public.municipalidades m on m.id = v.municipalidad_id
    where p.whatsapp_activo
      and p.optout_at is null
      and p.consentimiento_at is not null
      and p.whatsapp_numero is not null
  ),
  saldos as (
    select d.vecino_id, sum(d.saldo) as total
    from public.deudas d
    where d.estado <> 'pagada' and d.saldo > 0
    group by d.vecino_id
  ),
  por_vencer as (
    select a.*, 'vencimiento'::text as tipo, d.vencimiento::text as periodo,
           array_agg(distinct d.tipo) as tipos,
           sum(d.saldo) as monto, d.vencimiento as fecha, null::text as referencia,
           false as con_coactivo
    from activos a
    join public.deudas d on d.vecino_id = a.vecino_id
    cross join hoy
    where d.estado <> 'pagada' and d.saldo > 0
      and d.tipo <> 'coactivo'
      and d.vencimiento = hoy.dia + 3
    group by a.vecino_id, a.municipalidad_id, a.municipalidad, a.nombre, a.numero,
             a.whatsapp_activo, a.optout_at, a.consentimiento_at, d.vencimiento
  ),
  vencidas as (
    select a.*, 'pendiente'::text as tipo, hoy.dia::text as periodo,
           array_agg(distinct d.tipo) as tipos,
           coalesce(s.total, 0) as monto, null::date as fecha, null::text as referencia,
           bool_or(d.tipo = 'coactivo') as con_coactivo
    from activos a
    join public.deudas d on d.vecino_id = a.vecino_id
    left join saldos s on s.vecino_id = a.vecino_id
    cross join hoy
    where d.estado <> 'pagada' and d.saldo > 0
      and d.vencimiento < hoy.dia
      and not exists (
        select 1 from public.recordatorios_enviados r
        where r.contribuyente_id = a.vecino_id
          and r.tipo = 'pendiente'
          and r.estado <> 'fallido'
          and r.creado_at > p_ahora - interval '15 days'
      )
    group by a.vecino_id, a.municipalidad_id, a.municipalidad, a.nombre, a.numero,
             a.whatsapp_activo, a.optout_at, a.consentimiento_at, hoy.dia, s.total
  ),
  pagados as (
    select a.*, 'pago_confirmado'::text as tipo, p.referencia as periodo,
           array_agg(distinct d.tipo) as tipos,
           sum(p.monto) as monto, null::date as fecha, p.referencia,
           false as con_coactivo
    from activos a
    join public.pagos p on p.vecino_id = a.vecino_id
    join public.deudas d on d.id = p.deuda_id
    where p.estado = 'confirmado'
      and p.referencia is not null
      and p.creado_en >= a.consentimiento_at
      and p.creado_en > p_ahora - interval '7 days'
    group by a.vecino_id, a.municipalidad_id, a.municipalidad, a.nombre, a.numero,
             a.whatsapp_activo, a.optout_at, a.consentimiento_at, p.referencia
  ),
  todos as (
    select vecino_id, municipalidad_id, municipalidad, nombre, numero, tipo, periodo, tipos, monto, fecha,
           referencia, con_coactivo, whatsapp_activo, optout_at, consentimiento_at
    from por_vencer
    union all
    select vecino_id, municipalidad_id, municipalidad, nombre, numero, tipo, periodo, tipos, monto, fecha,
           referencia, con_coactivo, whatsapp_activo, optout_at, consentimiento_at
    from vencidas
    union all
    select vecino_id, municipalidad_id, municipalidad, nombre, numero, tipo, periodo, tipos, monto, fecha,
           referencia, con_coactivo, whatsapp_activo, optout_at, consentimiento_at
    from pagados
  )
  select t.vecino_id, t.municipalidad_id, t.municipalidad, t.nombre, t.numero, t.tipo, t.periodo, t.tipos,
         t.monto, t.fecha, t.referencia, t.con_coactivo,
         coalesce((select s.total from saldos s where s.vecino_id = t.vecino_id), 0) as saldo_pendiente,
         t.whatsapp_activo, t.optout_at, t.consentimiento_at
  from todos t
  where not exists (
    select 1 from public.recordatorios_enviados r
    where r.contribuyente_id = t.vecino_id and r.tipo = t.tipo and r.periodo = t.periodo
  )
  order by t.tipo, t.vecino_id;
$$;

revoke all on function public.recordatorios_candidatos(timestamptz) from public, anon, authenticated;
grant execute on function public.recordatorios_candidatos(timestamptz) to service_role;
