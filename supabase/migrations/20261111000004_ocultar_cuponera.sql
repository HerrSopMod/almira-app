-- Dos códigos distintos, con propósitos distintos:
--   codigo_contribuyente: identifica al contribuyente en su municipalidad (figura en el estado de
--     cuenta). Se muestra en la app y, con la clave web, sirve para ingresar.
--   numero_cuponera: privado. Solo está impreso en la cuponera. Valida que quien se registra es
--     el contribuyente real. Nunca se muestra ni se devuelve al cliente.
-- Los dos son únicos por municipalidad (vecinos_codigo_contribuyente_key y
-- vecinos_numero_cuponera_key).

comment on column public.vecinos.codigo_contribuyente is
  'Identifica al contribuyente en la municipalidad (por ejemplo 5866 en Lince). Público para su dueño: se muestra en la app y sirve para ingresar junto con la clave web. Único por municipalidad.';
comment on column public.vecinos.numero_cuponera is
  'PRIVADO. Número impreso en la cuponera. Solo lo validan vincular_contribuyente y la Edge Function registro-contribuyente; nunca se muestra ni se devuelve al cliente. Único por municipalidad.';

-- El cliente ya no puede leer numero_cuponera ni con `select *`: se concede la lectura solo de
-- las demás columnas. Las funciones security definer y service_role no se ven afectadas.
revoke select on public.vecinos from authenticated;
grant select (
  id, municipalidad_id, user_id, dni, nombre, telefono, canal_preferido, creado_en,
  codigo_contribuyente, nombres, apellidos, domicilio_fiscal
) on public.vecinos to authenticated;
