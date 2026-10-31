-- Fotos de los reclamos. Ruta: {municipalidad_id}/{user_id}/{archivo}.
-- Sin políticas de update ni delete: la evidencia no se reemplaza.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('evidencias', 'evidencias', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']);

create function privado.es_vecino_en_carpeta(p_carpeta text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.vecinos
    where municipalidad_id::text = p_carpeta and user_id = (select auth.uid())
  );
$$;

create function privado.es_personal_en_carpeta(p_carpeta text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.personal
    where municipalidad_id::text = p_carpeta and user_id = (select auth.uid())
  );
$$;

revoke all on function privado.es_vecino_en_carpeta(text) from public;
revoke all on function privado.es_personal_en_carpeta(text) from public;
grant execute on function privado.es_vecino_en_carpeta(text) to authenticated;
grant execute on function privado.es_personal_en_carpeta(text) to authenticated;

create policy "vecino sube su evidencia" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'evidencias'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and privado.es_vecino_en_carpeta((storage.foldername(name))[1])
  );

create policy "evidencia propia o personal" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'evidencias'
    and (
      (storage.foldername(name))[2] = (select auth.uid())::text
      or privado.es_personal_en_carpeta((storage.foldername(name))[1])
    )
  );
