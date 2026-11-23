-- Fotos de las obras. Ruta: {municipalidad_id}/{obra_id}/{archivo}.
-- Bucket privado: la app muestra cada foto con una dirección firmada temporal, como las de los reclamos.
--
-- Solo el personal de la municipalidad sube, cambia o quita fotos. Los vecinos de esa municipalidad
-- (y el personal) las ven. Solo se suben fotos que la municipalidad haya autorizado publicar.
-- No es una tabla: no lleva municipalidad_id ni columnas nuevas; la carpeta es el municipalidad_id.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('obras', 'obras', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']);

create policy "obras: ver las de mi municipalidad" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'obras'
    and (
      privado.es_vecino_en_carpeta((storage.foldername(name))[1])
      or privado.es_personal_en_carpeta((storage.foldername(name))[1])
    )
  );

create policy "obras: el personal sube" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'obras'
    and privado.es_personal_en_carpeta((storage.foldername(name))[1])
  );

create policy "obras: el personal cambia" on storage.objects
  for update to authenticated
  using (bucket_id = 'obras' and privado.es_personal_en_carpeta((storage.foldername(name))[1]))
  with check (bucket_id = 'obras' and privado.es_personal_en_carpeta((storage.foldername(name))[1]));

create policy "obras: el personal quita" on storage.objects
  for delete to authenticated
  using (bucket_id = 'obras' and privado.es_personal_en_carpeta((storage.foldername(name))[1]));
