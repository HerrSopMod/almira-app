-- Estado de cuenta por tributo y periodo, pagos confirmados por el servidor y registro por cuponera.
-- El contribuyente es la fila de `vecinos` (un código de contribuyente por municipalidad).

-- Datos del contribuyente para el estado de cuenta.
alter table public.vecinos
  add column nombres text,
  add column apellidos text,
  add column domicilio_fiscal text;

-- Una fila de `deudas` por tributo y periodo.
alter table public.deudas drop constraint deudas_tipo_check;
alter table public.deudas
  add constraint deudas_tipo_check check (tipo in ('predial', 'arbitrios', 'multa', 'coactivo', 'otros'));

alter table public.deudas
  add column anio integer,
  add column trimestre integer check (trimestre between 1 and 4),
  add column fecha_pago date,
  add column gastos_emision numeric(12, 2) not null default 0 check (gastos_emision >= 0),
  add column interes_actualizacion numeric(12, 2) not null default 0 check (interes_actualizacion >= 0),
  add column descuento numeric(12, 2) not null default 0 check (descuento >= 0),
  add column pagos_aplicados numeric(12, 2) not null default 0 check (pagos_aplicados >= 0),
  add column nro_valor text,
  add column exp_coactivo text;

-- saldo = insoluto + gastos de emisión + interés de actualización - descuento - pagos.
alter table public.deudas
  add column saldo numeric(12, 2) generated always as (
    monto_insoluto + gastos_emision + interes_actualizacion - descuento - pagos_aplicados
  ) stored;
alter table public.deudas add constraint deudas_saldo_check check (saldo >= 0);

update public.deudas set anio = extract(year from vencimiento)::integer where anio is null;

-- Cada pago se confirma en el servidor: el cliente solo dice qué deudas y con qué medio.
create sequence public.operaciones_pago start 90500;
revoke all on sequence public.operaciones_pago from anon, authenticated;

create function public.registrar_pago(p_deudas uuid[], p_medio text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_operacion text;
  v_pedidas integer;
  v_pagadas integer := 0;
  v_fila record;
begin
  if v_usuario is null then
    raise exception 'sin_sesion';
  end if;
  if p_medio is null or p_medio not in ('yape', 'plin', 'tarjeta', 'banca_movil') then
    raise exception 'medio_invalido';
  end if;
  select count(distinct d) into v_pedidas from unnest(coalesce(p_deudas, '{}'::uuid[])) as d;
  if v_pedidas = 0 then
    raise exception 'sin_deudas';
  end if;

  v_operacion := 'OP-' || nextval('public.operaciones_pago');

  -- Solo deudas del propio contribuyente y con saldo; el monto sale de la base, nunca del cliente.
  for v_fila in
    select d.id, d.municipalidad_id, d.vecino_id, d.saldo
    from public.deudas d
    join public.vecinos v on v.id = d.vecino_id and v.municipalidad_id = d.municipalidad_id
    where d.id = any (p_deudas)
      and v.user_id = v_usuario
      and d.estado <> 'pagada'
      and d.saldo > 0
    for update of d
  loop
    insert into public.pagos (municipalidad_id, vecino_id, deuda_id, monto, medio, estado, referencia)
    values (v_fila.municipalidad_id, v_fila.vecino_id, v_fila.id, v_fila.saldo, p_medio, 'confirmado', v_operacion);

    update public.deudas
    set pagos_aplicados = pagos_aplicados + v_fila.saldo,
        estado = 'pagada',
        fecha_pago = (now() at time zone 'America/Lima')::date
    where id = v_fila.id;

    v_pagadas := v_pagadas + 1;
  end loop;

  if v_pagadas <> v_pedidas then
    raise exception 'deudas_invalidas';
  end if;
  return v_operacion;
end;
$$;

revoke all on function public.registrar_pago(uuid[], text) from public, anon;
grant execute on function public.registrar_pago(uuid[], text) to authenticated;

-- Intentos de registro por dirección (hash), para frenar la prueba de cuponeras al azar.
-- Solo la Edge Function (service_role) lo lee y escribe.
create table public.intentos_registro (
  id bigint generated always as identity primary key,
  municipalidad_id uuid references public.municipalidades (id) on delete cascade,
  origen text not null,
  acertado boolean not null,
  creado_en timestamptz not null default now()
);
create index intentos_registro_origen_idx on public.intentos_registro (origen, creado_en desc);
alter table public.intentos_registro enable row level security;
revoke all on public.intentos_registro from anon, authenticated;

-- La app se entera al instante cuando cambia una deuda (por ejemplo, tras un pago).
alter publication supabase_realtime add table public.deudas;
