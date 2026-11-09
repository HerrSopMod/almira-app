-- Datos iniciales de prueba para un proyecto Supabase ya migrado y con seed.sql aplicado.
-- Se ejecuta a mano: supabase db query --linked -f supabase/datos-iniciales.sql
-- Es idempotente: se puede correr más de una vez sin duplicar filas.
-- Todo es ficticio. Los vecinos de prueba (DNI 9000000x) y "Rosa" salen de datos-ejemplo.ts.

do $$
declare
  lince constant uuid := '00000000-0000-4000-8000-000000000001';
  villa_verde constant uuid := '00000000-0000-4000-8000-000000000002';
  v record;
  predio uuid;
  d_multa uuid;
  d_arbitrios uuid;
  d_predial uuid;
  d_arbitrios_3t uuid;
begin
  -- Rosa, la vecina de ejemplo del prototipo, sin cuenta vinculada todavía.
  insert into public.vecinos (municipalidad_id, dni, nombre, canal_preferido)
  values (lince, '40000082', 'Rosa Quispe Huamán (ejemplo)', 'whatsapp')
  on conflict (municipalidad_id, dni) do nothing;

  for v in
    select id, dni, nombre from public.vecinos where municipalidad_id = lince
  loop
    insert into public.predios (municipalidad_id, vecino_id, codigo, direccion)
    values (lince, v.id, 'PR-' || v.dni, 'Jr. Bernardo Alcedo 480, Lince')
    on conflict (municipalidad_id, codigo) do nothing;
    select id into predio from public.predios where municipalidad_id = lince and codigo = 'PR-' || v.dni;

    insert into public.deudas (municipalidad_id, vecino_id, predio_id, tipo, concepto, periodo, monto_insoluto, vencimiento, estado)
    select lince, v.id, x.predio_id, x.tipo, x.concepto, x.periodo, x.monto, x.vence::date, x.estado
    from (values
      (null::uuid, 'multa', 'Multa administrativa', 'Fiscalización · 2026', 40.00, '2026-10-15', 'vencida'),
      (predio, 'arbitrios', 'Arbitrios', '4.º trimestre 2026 · Limpieza, parques y serenazgo', 80.50, '2026-11-30', 'vigente'),
      (predio, 'predial', 'Impuesto predial', '4.ª cuota 2026', 186.40, '2026-11-30', 'pagada'),
      (predio, 'arbitrios', 'Arbitrios', '3.er trimestre 2026', 78.00, '2026-08-31', 'pagada')
    ) as x(predio_id, tipo, concepto, periodo, monto, vence, estado)
    where not exists (
      select 1 from public.deudas e
      where e.municipalidad_id = lince and e.vecino_id = v.id and e.concepto = x.concepto and e.periodo = x.periodo
    );

    select id into d_multa from public.deudas where municipalidad_id = lince and vecino_id = v.id and tipo = 'multa';
    select id into d_arbitrios from public.deudas where municipalidad_id = lince and vecino_id = v.id and concepto = 'Arbitrios' and estado = 'vigente';
    select id into d_predial from public.deudas where municipalidad_id = lince and vecino_id = v.id and tipo = 'predial';
    select id into d_arbitrios_3t from public.deudas where municipalidad_id = lince and vecino_id = v.id and periodo = '3.er trimestre 2026';

    insert into public.pagos (municipalidad_id, vecino_id, deuda_id, monto, medio, estado, referencia, creado_en)
    select lince, v.id, x.deuda, x.monto, 'yape', 'confirmado', x.ref, x.fecha::timestamptz
    from (values
      (d_predial, 186.40, 'OP-' || v.dni || '-1', '2026-10-28'),
      (d_arbitrios_3t, 78.00, 'OP-' || v.dni || '-2', '2026-08-28')
    ) as x(deuda, monto, ref, fecha)
    where not exists (select 1 from public.pagos p where p.municipalidad_id = lince and p.referencia = x.ref);

    insert into public.recordatorios (municipalidad_id, vecino_id, deuda_id, codigo, tipo, canal, estado, programado_para, entregado_en)
    values
      (lince, v.id, d_arbitrios, 'AV-' || v.dni || '-1', 'preventivo', 'app', 'entregado', '2026-10-31T10:15:00-05:00', '2026-10-31T10:15:00-05:00'),
      (lince, v.id, d_multa, 'AV-' || v.dni || '-2', 'mora', 'app', 'entregado', '2026-10-24T09:02:00-05:00', '2026-10-24T09:02:00-05:00')
    on conflict (municipalidad_id, codigo) do nothing;

    insert into public.reclamos (municipalidad_id, vecino_id, codigo, tipo, titulo, descripcion, estado, area, plazo, plazo_dias, foto_ruta, direccion, latitud, longitud, creado_en)
    values
      (lince, v.id, 'R-' || right(v.dni, 5), 'alumbrado', 'Poste sin luz',
       'El poste de la esquina lleva una semana apagado y la cuadra queda muy oscura.',
       'en_atencion', 'Obras', 'Quedan 3 d', 10, lince || '/R-' || right(v.dni, 5) || '.jpg',
       'Jr. Pumacahua 1450', -12.0850, -77.0372, '2026-10-22')
    on conflict (municipalidad_id, codigo) do nothing;
  end loop;

  -- Rosa también tributa en Villa Verde: una fila por municipalidad.
  insert into public.vecinos (municipalidad_id, dni, nombre, canal_preferido)
  values (villa_verde, '40000082', 'Rosa Quispe Huamán (ejemplo)', 'whatsapp')
  on conflict (municipalidad_id, dni) do nothing;
  select id into v from public.vecinos where municipalidad_id = villa_verde and dni = '40000082';
  insert into public.predios (municipalidad_id, vecino_id, codigo, direccion)
  select villa_verde, v.id, 'PR-010233', 'Calle Los Sauces 75'
  on conflict (municipalidad_id, codigo) do nothing;
  insert into public.deudas (municipalidad_id, vecino_id, predio_id, tipo, concepto, periodo, monto_insoluto, vencimiento, estado)
  select villa_verde, v.id, p.id, 'arbitrios', 'Arbitrios', '4.º trimestre 2026 · Limpieza, parques y serenazgo', 95, '2026-11-30', 'vigente'
  from public.predios p
  where p.municipalidad_id = villa_verde and p.codigo = 'PR-010233'
    and not exists (select 1 from public.deudas e where e.municipalidad_id = villa_verde and e.vecino_id = v.id);
end $$;

select
  (select count(*) from public.vecinos) as vecinos,
  (select count(*) from public.predios) as predios,
  (select count(*) from public.deudas) as deudas,
  (select count(*) from public.pagos) as pagos,
  (select count(*) from public.recordatorios) as recordatorios,
  (select count(*) from public.reclamos) as reclamos;
