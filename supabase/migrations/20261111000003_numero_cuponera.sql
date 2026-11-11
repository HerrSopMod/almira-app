-- La cuponera es un dato privado, distinto del código de contribuyente: el código identifica
-- al contribuyente (figura en el estado de cuenta) y el número de cuponera solo lo tiene quien
-- recibe la cuponera impresa. Sirve para vincular la cuenta la primera vez y crear la clave web.
-- Nunca se registra en logs.

alter table public.vecinos add column numero_cuponera text;
alter table public.vecinos
  add constraint vecinos_numero_cuponera_key unique (municipalidad_id, numero_cuponera);

-- Vincula la cuenta si el número de cuponera y el DNI son de la misma persona en esa municipalidad.
-- Devuelve true si quedó vinculado. Con 5 fallos en 15 minutos la cuenta debe esperar.
create or replace function public.vincular_contribuyente(p_municipalidad uuid, p_codigo text, p_dni text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_vecino public.vecinos%rowtype;
  v_cuponera text := regexp_replace(upper(btrim(p_codigo)), '[^A-Z0-9]', '', 'g');
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
    and v.numero_cuponera is not null
    and regexp_replace(upper(v.numero_cuponera), '[^A-Z0-9]', '', 'g') = v_cuponera
    and upper(v.dni) = upper(btrim(p_dni))
    and (v.user_id is null or v.user_id = v_usuario);

  if not found then
    insert into public.intentos_vinculo (municipalidad_id, user_id, acertado)
    values (p_municipalidad, v_usuario, false);
    return false;
  end if;

  update public.vecinos set user_id = v_usuario where id = v_vecino.id and user_id is null;

  insert into public.vinculos_contribuyente (municipalidad_id, user_id, vecino_id, codigo)
  values (p_municipalidad, v_usuario, v_vecino.id, coalesce(v_vecino.codigo_contribuyente, v_cuponera))
  on conflict (user_id, municipalidad_id, codigo) do nothing;

  insert into public.intentos_vinculo (municipalidad_id, user_id, acertado)
  values (p_municipalidad, v_usuario, true);
  return true;
end;
$$;

revoke all on function public.vincular_contribuyente(uuid, text, text) from public, anon;
grant execute on function public.vincular_contribuyente(uuid, text, text) to authenticated;
