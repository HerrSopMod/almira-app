-- Contribuyente con deudas para ver cómo se paga: Lince, DNI 73126352.
--   código de contribuyente: LIN-0006   número de cuponera (privado): 4417268503
-- Idempotente: si el DNI ya existe en Lince, no hace nada. Las fechas salen de la fecha de hoy en
-- Lima, así que siempre hay deudas vencidas, una que vence en 3 días y otras por vencer.
--   supabase db query --linked -f supabase/seed-usuario-pago.sql
--
-- Agrega: 1 contribuyente, 1 predio, 5 deudas (4 pendientes y 1 pagada) y 1 pago. No toca nada más.

do $$
declare
  m uuid;
  v uuid;
  p uuid;
  d_pagada uuid;
  hoy date := (now() at time zone 'America/Lima')::date;
begin
  select id into m from public.municipalidades where slug = 'lince';
  if m is null then
    raise exception 'No existe la municipalidad lince';
  end if;
  if exists (select 1 from public.vecinos where municipalidad_id = m and dni = '73126352') then
    raise notice 'El DNI 73126352 ya existe en Lince: no se hizo nada.';
    return;
  end if;

  insert into public.vecinos
    (municipalidad_id, dni, nombre, nombres, apellidos, domicilio_fiscal, codigo_contribuyente, numero_cuponera)
  values
    (m, '73126352', 'Andrea Lucía Torres Vega', 'Andrea Lucía', 'Torres Vega',
     'Jr. Risso 640, Dpto. 201 - Lima / Lima / Lince', 'LIN-0006', '4417268503')
  returning id into v;

  insert into public.predios (municipalidad_id, vecino_id, codigo, direccion)
  values (m, v, 'LIN-PR-0006', 'Jr. Risso 640, Dpto. 201, Lince')
  returning id into p;

  insert into public.deudas
    (municipalidad_id, vecino_id, predio_id, tipo, concepto, anio, trimestre, periodo,
     monto_insoluto, gastos_emision, interes_actualizacion, descuento, pagos_aplicados,
     vencimiento, fecha_pago, estado)
  values
    -- Vencidas.
    (m, v, p, 'predial',   'IMPUESTO PREDIAL',      extract(year from hoy)::int, 2, extract(year from hoy)::int || '-TRIM.2',
     27.25, 0, 1.80, 0, 0, hoy - 75, null, 'vencida'),
    (m, v, p, 'arbitrios', 'ARBITRIOS MUNICIPALES', extract(year from hoy)::int, 2, extract(year from hoy)::int || '-TRIM.2',
     52.10, 0, 3.40, 0, 0, hoy - 75, null, 'vencida'),
    -- Vence en 3 días.
    (m, v, p, 'predial',   'IMPUESTO PREDIAL',      extract(year from hoy)::int, 3, extract(year from hoy)::int || '-TRIM.3',
     27.25, 0, 0, 0, 0, hoy + 3, null, 'vigente'),
    -- Por vencer.
    (m, v, p, 'arbitrios', 'ARBITRIOS MUNICIPALES', extract(year from hoy)::int, 3, extract(year from hoy)::int || '-TRIM.3',
     52.08, 0, 0, 0, 0, hoy + 28, null, 'vigente');

  -- Una deuda ya pagada, con su pago, para que el historial no esté vacío.
  insert into public.deudas
    (municipalidad_id, vecino_id, predio_id, tipo, concepto, anio, trimestre, periodo,
     monto_insoluto, gastos_emision, interes_actualizacion, descuento, pagos_aplicados,
     vencimiento, fecha_pago, estado)
  values
    (m, v, p, 'predial', 'IMPUESTO PREDIAL', extract(year from hoy)::int, 1, extract(year from hoy)::int || '-TRIM.1',
     27.25, 0, 0, 0, 27.25, hoy - 160, hoy - 165, 'pagada')
  returning id into d_pagada;

  insert into public.pagos (municipalidad_id, vecino_id, deuda_id, monto, medio, estado, referencia, creado_en)
  values (m, v, d_pagada, 27.25, 'yape', 'confirmado', 'OP-70999', (hoy - 165 + time '10:30') at time zone 'America/Lima');

  raise notice 'Creado LIN-0006 (DNI 73126352) con 4 deudas pendientes y 1 pagada.';
end;
$$;

select v.codigo_contribuyente, v.dni, v.nombre,
       count(*) filter (where d.saldo > 0) as deudas_pendientes,
       coalesce(sum(d.saldo), 0) as total_pendiente
from public.vecinos v
join public.municipalidades m on m.id = v.municipalidad_id and m.slug = 'lince'
left join public.deudas d on d.vecino_id = v.id
where v.dni = '73126352'
group by v.codigo_contribuyente, v.dni, v.nombre;
