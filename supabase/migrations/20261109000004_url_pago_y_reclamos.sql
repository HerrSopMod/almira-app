-- Enlace al portal de pago de cada municipalidad y reclamos creados desde la app.
-- Almira no procesa pagos: lleva al vecino al portal oficial de su municipalidad.

alter table public.municipalidades
  add column url_pago text check (url_pago is null or url_pago ~ '^https://');

-- El reclamo creado desde la app guarda la dirección y el plazo de atención.
grant insert (direccion) on public.reclamos to authenticated;
alter table public.reclamos alter column plazo_dias set default 10;
