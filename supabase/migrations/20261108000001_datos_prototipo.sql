-- Ajusta el esquema a los datos del prototipo de Figma.
-- No crea tablas. La única política que cambia es "obras visibles".

-- Deudas: el prototipo cobra multas administrativas además de predial y arbitrios.
alter table public.deudas drop constraint deudas_tipo_check;
alter table public.deudas add constraint deudas_tipo_check
  check (tipo in ('predial', 'arbitrios', 'multa'));

-- Vecinos: código de contribuyente que muestra "Mi perfil".
alter table public.vecinos add column codigo_contribuyente text;
alter table public.vecinos add constraint vecinos_codigo_contribuyente_key
  unique (municipalidad_id, codigo_contribuyente);

-- Reclamos: categorías de la pantalla "Envío al área", dirección y plazo en días hábiles.
alter table public.reclamos drop constraint reclamos_tipo_check;
update public.reclamos set tipo = case tipo
  when 'basura' then 'limpieza'
  when 'bache' then 'pistas_veredas'
  when 'luminaria' then 'alumbrado'
  else tipo
end;
alter table public.reclamos add constraint reclamos_tipo_check
  check (tipo in (
    'pistas_veredas', 'alumbrado', 'limpieza', 'vehiculo_mal_estacionado',
    'deposito_vehicular', 'cobro_indebido', 'otro'
  ));
alter table public.reclamos add column direccion text;
alter table public.reclamos add column plazo_dias integer check (plazo_dias > 0);

-- El vecino escribe la dirección al crear su reclamo; la política
-- "vecino crea su reclamo" sigue exigiendo que el reclamo sea suyo.
grant insert (direccion) on public.reclamos to authenticated;

-- Obras: la municipalidad decide qué publica y lo actualiza con fecha.
alter table public.obras add column publicada boolean not null default true;
alter table public.obras add column inicio date;
alter table public.obras add column actualizada_en timestamptz not null default now();
alter table public.obras add column porcentaje_tributos numeric(5, 2)
  check (porcentaje_tributos between 0 and 100);
alter table public.obras add column hitos jsonb not null default '[]'::jsonb
  check (jsonb_typeof(hitos) = 'array');

-- Las obras sin publicar solo las ve el personal de su municipalidad.
drop policy "obras visibles" on public.obras;
create policy "obras visibles" on public.obras
  for select to authenticated
  using (publicada or privado.es_personal_de(municipalidad_id));
