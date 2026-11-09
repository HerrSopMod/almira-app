-- Vínculos entre la cuenta del vecino y su código de contribuyente (o de predio).
-- Un vecino puede vincular varios códigos. La tabla no guarda el DNI.
-- Solo se escribe desde el servidor, con vincular_contribuyente(): el cliente no tiene
-- permisos de escritura.

create table public.vinculos_contribuyente (
  id uuid primary key default gen_random_uuid(),
  municipalidad_id uuid not null references public.municipalidades (id) on delete restrict,
  user_id uuid not null references auth.users (id) on delete cascade,
  vecino_id uuid not null,
  codigo text not null,
  creado_en timestamptz not null default now(),
  foreign key (municipalidad_id, vecino_id) references public.vecinos (municipalidad_id, id),
  unique (user_id, municipalidad_id, codigo)
);

alter table public.vinculos_contribuyente enable row level security;
revoke all on public.vinculos_contribuyente from anon, authenticated;
grant select on public.vinculos_contribuyente to authenticated;

create policy "vinculo propio" on public.vinculos_contribuyente
  for select to authenticated
  using (user_id = (select auth.uid()));

-- Vincula la cuenta si el código y el DNI son de la misma persona en el padrón de esa
-- municipalidad. Devuelve true si quedó vinculado. No registra DNI en ningún log.
create function public.vincular_contribuyente(p_municipalidad uuid, p_codigo text, p_dni text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_vecino public.vecinos%rowtype;
  v_codigo text := upper(btrim(p_codigo));
begin
  if v_usuario is null then
    return false;
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
    return false;
  end if;

  update public.vecinos set user_id = v_usuario where id = v_vecino.id and user_id is null;

  insert into public.vinculos_contribuyente (municipalidad_id, user_id, vecino_id, codigo)
  values (p_municipalidad, v_usuario, v_vecino.id, v_codigo)
  on conflict (user_id, municipalidad_id, codigo) do nothing;

  return true;
end;
$$;

revoke all on function public.vincular_contribuyente(uuid, text, text) from public, anon;
grant execute on function public.vincular_contribuyente(uuid, text, text) to authenticated;

-- Pendiente: limitar los intentos por cuenta para frenar la prueba de códigos al azar.
