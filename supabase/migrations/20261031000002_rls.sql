-- Row Level Security por municipalidad.
-- Personal: ve solo su municipalidad. Vecino: ve solo sus propias filas.
-- Las escrituras sin política (padrón, deudas, pagos, recordatorios) quedan
-- para service_role: importaciones, pasarela de pago y Edge Functions.

-- Fuera de public para que PostgREST no las exponga como RPC.
create schema privado;
revoke all on schema privado from public;
grant usage on schema privado to authenticated;

create function privado.es_personal_de(p_municipalidad uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.personal
    where municipalidad_id = p_municipalidad and user_id = (select auth.uid())
  );
$$;

create function privado.es_vecino_propio(p_vecino uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.vecinos
    where id = p_vecino and user_id = (select auth.uid())
  );
$$;

revoke all on function privado.es_personal_de(uuid) from public;
revoke all on function privado.es_vecino_propio(uuid) from public;
grant execute on function privado.es_personal_de(uuid) to authenticated;
grant execute on function privado.es_vecino_propio(uuid) to authenticated;

alter table public.municipalidades enable row level security;
alter table public.personal enable row level security;
alter table public.vecinos enable row level security;
alter table public.predios enable row level security;
alter table public.deudas enable row level security;
alter table public.pagos enable row level security;
alter table public.recordatorios enable row level security;
alter table public.reclamos enable row level security;
alter table public.obras enable row level security;

-- Los permisos por columna solo limitan si no hay permiso sobre toda la tabla.
revoke all on all tables in schema public from anon, authenticated;
grant select on all tables in schema public to authenticated;

create policy "municipalidades activas visibles" on public.municipalidades
  for select to authenticated
  using (activa or privado.es_personal_de(id));

create policy "personal ve a su municipalidad" on public.personal
  for select to authenticated
  using (user_id = (select auth.uid()) or privado.es_personal_de(municipalidad_id));

create policy "vecino propio o personal" on public.vecinos
  for select to authenticated
  using (user_id = (select auth.uid()) or privado.es_personal_de(municipalidad_id));

grant update (canal_preferido) on public.vecinos to authenticated;
create policy "vecino elige su canal" on public.vecinos
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "predio propio o personal" on public.predios
  for select to authenticated
  using (privado.es_vecino_propio(vecino_id) or privado.es_personal_de(municipalidad_id));

create policy "deuda propia o personal" on public.deudas
  for select to authenticated
  using (privado.es_vecino_propio(vecino_id) or privado.es_personal_de(municipalidad_id));

create policy "pago propio o personal" on public.pagos
  for select to authenticated
  using (privado.es_vecino_propio(vecino_id) or privado.es_personal_de(municipalidad_id));

create policy "recordatorio propio o personal" on public.recordatorios
  for select to authenticated
  using (privado.es_vecino_propio(vecino_id) or privado.es_personal_de(municipalidad_id));

create policy "reclamo propio o personal" on public.reclamos
  for select to authenticated
  using (privado.es_vecino_propio(vecino_id) or privado.es_personal_de(municipalidad_id));

grant insert (municipalidad_id, vecino_id, tipo, titulo, descripcion, foto_ruta, latitud, longitud)
  on public.reclamos to authenticated;
create policy "vecino crea su reclamo" on public.reclamos
  for insert to authenticated
  with check (privado.es_vecino_propio(vecino_id));

grant update (estado, area, plazo) on public.reclamos to authenticated;
create policy "personal atiende reclamos" on public.reclamos
  for update to authenticated
  using (privado.es_personal_de(municipalidad_id))
  with check (privado.es_personal_de(municipalidad_id));

-- Las obras son información pública para cualquier vecino con sesión.
create policy "obras visibles" on public.obras
  for select to authenticated
  using (true);

grant insert, update on public.obras to authenticated;
create policy "personal registra obras" on public.obras
  for insert to authenticated
  with check (privado.es_personal_de(municipalidad_id));
create policy "personal actualiza obras" on public.obras
  for update to authenticated
  using (privado.es_personal_de(municipalidad_id))
  with check (privado.es_personal_de(municipalidad_id));
