-- Límite de intentos de vincular_contribuyente: frena la prueba de DNI y códigos al azar.
-- Cada intento (acertado o no) queda registrado por cuenta, sin guardar DNI ni código.
-- Con 5 intentos fallidos en los últimos 15 minutos la cuenta debe esperar.

create table public.intentos_vinculo (
  id bigint generated always as identity primary key,
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete cascade,
  acertado boolean not null,
  creado_en timestamptz not null default now()
);

create index intentos_vinculo_usuario_idx on public.intentos_vinculo (user_id, creado_en desc);

-- Nadie lo lee ni escribe desde el cliente; solo la función de abajo, que corre como dueño.
alter table public.intentos_vinculo enable row level security;
revoke all on public.intentos_vinculo from anon, authenticated;

create or replace function public.vincular_contribuyente(p_municipalidad uuid, p_codigo text, p_dni text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_vecino public.vecinos%rowtype;
  v_codigo text := upper(btrim(p_codigo));
  v_fallidos integer;
begin
  if v_usuario is null then
    return false;
  end if;

  select count(*) into v_fallidos
  from public.intentos_vinculo i
  where i.user_id = v_usuario
    and not i.acertado
    and i.creado_en > now() - interval '15 minutes';

  if v_fallidos >= 5 then
    raise exception 'demasiados_intentos' using errcode = 'P0001';
  end if;

  select v.* into v_vecino
  from public.vecinos v
  where v.municipalidad_id = p_municipalidad
    and upper(v.dni) = upper(btrim(p_dni))
    and (v.user_id is null or v.user_id = v_usuario)
    and (
      upper(v.codigo_contribuyente) = v_codigo
      or exists (
        select 1 from public.predios p
        where p.vecino_id = v.id and p.municipalidad_id = v.municipalidad_id
          and upper(p.codigo) = v_codigo
      )
    );

  if not found then
    insert into public.intentos_vinculo (municipalidad_id, user_id, acertado)
    values (p_municipalidad, v_usuario, false);
    return false;
  end if;

  update public.vecinos set user_id = v_usuario where id = v_vecino.id and user_id is null;

  insert into public.vinculos_contribuyente (municipalidad_id, user_id, vecino_id, codigo)
  values (p_municipalidad, v_usuario, v_vecino.id, v_codigo)
  on conflict (user_id, municipalidad_id, codigo) do nothing;

  insert into public.intentos_vinculo (municipalidad_id, user_id, acertado)
  values (p_municipalidad, v_usuario, true);
  return true;
end;
$$;

revoke all on function public.vincular_contribuyente(uuid, text, text) from public, anon;
grant execute on function public.vincular_contribuyente(uuid, text, text) to authenticated;
