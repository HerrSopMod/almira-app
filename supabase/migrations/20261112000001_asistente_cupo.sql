-- Límite de uso del asistente por persona: un contador simple de mensajes por hora.
-- Lo usa la Edge Function `asistente` con el JWT de la persona, a través de consumir_cupo_asistente.
-- La tabla no guarda mensajes ni datos personales: solo quién y cuándo.

create table public.asistente_uso (
  id bigint generated always as identity primary key,
  municipalidad_id uuid not null references public.municipalidades (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  creado_en timestamptz not null default now()
);
create index asistente_uso_usuario_idx on public.asistente_uso (user_id, creado_en desc);
alter table public.asistente_uso enable row level security;
revoke all on public.asistente_uso from anon, authenticated;

-- Devuelve 'ok' (y cuenta el mensaje), 'limite' (ya usó p_limite en la última hora),
-- 'sin_vinculo' (la cuenta no tiene contribuyente) o 'sin_sesion'.
create function public.consumir_cupo_asistente(p_limite integer default 30)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_municipalidad uuid;
  v_usados integer;
begin
  if v_usuario is null then
    return 'sin_sesion';
  end if;

  select v.municipalidad_id into v_municipalidad
  from public.vecinos v where v.user_id = v_usuario
  order by v.creado_en limit 1;
  if v_municipalidad is null then
    return 'sin_vinculo';
  end if;

  -- Limpieza: nada de más de un día.
  delete from public.asistente_uso where user_id = v_usuario and creado_en < now() - interval '1 day';

  select count(*) into v_usados
  from public.asistente_uso
  where user_id = v_usuario and creado_en > now() - interval '1 hour';
  if v_usados >= greatest(p_limite, 1) then
    return 'limite';
  end if;

  insert into public.asistente_uso (municipalidad_id, user_id) values (v_municipalidad, v_usuario);
  return 'ok';
end;
$$;

revoke all on function public.consumir_cupo_asistente(integer) from public, anon;
grant execute on function public.consumir_cupo_asistente(integer) to authenticated;
