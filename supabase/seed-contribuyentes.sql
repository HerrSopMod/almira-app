-- Datos de los cinco contribuyentes de prueba: predio, deudas por tributo y periodo, y pagos.
-- Se ejecuta a mano: supabase db query --linked -f supabase/seed-contribuyentes.sql
-- Es idempotente: borra y vuelve a crear lo de estos cinco contribuyentes (identificados por su
-- slug y su código de contribuyente, que no se tocan). Requiere la migración 20261111000001.
-- Generado a partir de reglas fijas: ver los escenarios al final de cada bloque.

begin;

-- Limpia lo de estos cinco contribuyentes. Los vínculos con cuentas (user_id) se conservan.
delete from public.recordatorios r using public.vecinos v
  where r.vecino_id = v.id and v.codigo_contribuyente in ('LIN-0001', 'PUL-0002', 'LAV-0003', 'MIR-0004', 'CER-0005');
delete from public.pagos p using public.vecinos v
  where p.vecino_id = v.id and v.codigo_contribuyente in ('LIN-0001', 'PUL-0002', 'LAV-0003', 'MIR-0004', 'CER-0005');
delete from public.deudas d using public.vecinos v
  where d.vecino_id = v.id and v.codigo_contribuyente in ('LIN-0001', 'PUL-0002', 'LAV-0003', 'MIR-0004', 'CER-0005');
delete from public.predios p using public.vecinos v
  where p.vecino_id = v.id and v.codigo_contribuyente in ('LIN-0001', 'PUL-0002', 'LAV-0003', 'MIR-0004', 'CER-0005');

-- LIN-0001 · lince: al día (saldo 0)
update public.vecinos v
set nombres = 'Mario Alberto', apellidos = 'Cárdenas Tello',
    nombre = 'Mario Alberto Cárdenas Tello', domicilio_fiscal = 'Av. Arequipa 2150, Dpto. 302 - Lima / Lima / Lince'
from public.municipalidades m
where m.id = v.municipalidad_id and m.slug = 'lince' and v.codigo_contribuyente = 'LIN-0001';

insert into public.predios (municipalidad_id, vecino_id, codigo, direccion)
select v.municipalidad_id, v.id, 'LIN-PR-0001', 'Av. Arequipa 2150, Dpto. 302, Lince'
from public.vecinos v join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'lince' and v.codigo_contribuyente = 'LIN-0001';

insert into public.deudas (municipalidad_id, vecino_id, predio_id, tipo, concepto, anio, trimestre, periodo,
  monto_insoluto, gastos_emision, interes_actualizacion, descuento, pagos_aplicados,
  vencimiento, fecha_pago, estado, nro_valor, exp_coactivo)
select v.municipalidad_id, v.id, p.id, x.tipo, x.concepto, x.anio, x.trimestre, x.periodo,
  x.insoluto, x.ge, x.interes, x.descuento, x.pagado, x.vence::date, x.fecha_pago::date, x.estado, x.nro_valor, x.exp
from public.vecinos v
join public.municipalidades m on m.id = v.municipalidad_id
join public.predios p on p.vecino_id = v.id
cross join (values
    ('predial', 'IMPUESTO PREDIAL', 2024, 1, '2024-TRIM.1', 20.24, 7.10, 0.00, 0.00, 27.34, '2024-02-29', '2024-02-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 2, '2024-TRIM.2', 20.24, 0.00, 0.00, 0.00, 20.24, '2024-05-31', '2024-05-25', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 3, '2024-TRIM.3', 20.24, 0.00, 0.00, 0.00, 20.24, '2024-08-31', '2024-08-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 4, '2024-TRIM.4', 20.22, 0.00, 0.00, 0.00, 20.22, '2024-11-30', '2024-11-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 1, '2025-TRIM.1', 21.18, 7.10, 0.00, 0.00, 28.28, '2025-02-28', '2025-02-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 2, '2025-TRIM.2', 21.18, 0.00, 0.00, 0.00, 21.18, '2025-05-31', '2025-05-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 3, '2025-TRIM.3', 21.18, 0.00, 0.00, 0.00, 21.18, '2025-08-31', '2025-08-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 4, '2025-TRIM.4', 21.16, 0.00, 0.00, 0.00, 21.16, '2025-11-30', '2025-11-21', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 1, '2026-TRIM.1', 27.25, 7.10, 0.00, 0.00, 34.35, '2026-02-28', '2026-02-21', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 2, '2026-TRIM.2', 27.25, 0.00, 0.00, 0.00, 27.25, '2026-05-31', '2026-05-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 3, '2026-TRIM.3', 27.25, 0.00, 0.00, 0.00, 27.25, '2026-08-31', '2026-08-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 4, '2026-TRIM.4', 27.23, 0.00, 0.00, 0.00, 27.23, '2026-11-30', '2026-11-05', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2025, 1, '2025-TRIM.1', 48.60, 0.00, 0.00, 0.00, 48.60, '2025-02-28', '2025-02-22', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2025, 2, '2025-TRIM.2', 48.60, 0.00, 0.00, 0.00, 48.60, '2025-05-31', '2025-05-24', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2025, 3, '2025-TRIM.3', 48.60, 0.00, 0.00, 0.00, 48.60, '2025-08-31', '2025-08-23', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2025, 4, '2025-TRIM.4', 48.58, 0.00, 0.00, 0.00, 48.58, '2025-11-30', '2025-11-21', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 1, '2026-TRIM.1', 52.10, 0.00, 0.00, 0.00, 52.10, '2026-02-28', '2026-02-21', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 2, '2026-TRIM.2', 52.10, 0.00, 0.00, 0.00, 52.10, '2026-05-31', '2026-05-23', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 3, '2026-TRIM.3', 52.10, 0.00, 0.00, 0.00, 52.10, '2026-08-31', '2026-08-22', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 4, '2026-TRIM.4', 52.08, 0.00, 0.00, 0.00, 52.08, '2026-11-30', '2026-11-05', 'pagada', null, null)
  ) as x(tipo, concepto, anio, trimestre, periodo, insoluto, ge, interes, descuento, pagado, vence, fecha_pago, estado, nro_valor, exp)
where m.slug = 'lince' and v.codigo_contribuyente = 'LIN-0001';

-- Un pago por cada deuda pagada, con el medio y la fecha de pago.
insert into public.pagos (municipalidad_id, vecino_id, deuda_id, monto, medio, estado, referencia, creado_en)
select d.municipalidad_id, d.vecino_id, d.id, d.pagos_aplicados,
  (array['yape', 'plin', 'tarjeta', 'banca_movil'])[1 + (row_number() over (order by d.fecha_pago, d.vencimiento))::int % 4],
  'confirmado', 'OP-' || (70100 + row_number() over (order by d.fecha_pago, d.vencimiento)),
  (d.fecha_pago + time '10:30') at time zone 'America/Lima'
from public.deudas d join public.vecinos v on v.id = d.vecino_id join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'lince' and v.codigo_contribuyente = 'LIN-0001' and d.estado = 'pagada' and d.pagos_aplicados > 0;

-- PUL-0002 · pueblo-libre: un trimestre pendiente
update public.vecinos v
set nombres = 'Carmen Rosa', apellidos = 'Huamaní Paredes',
    nombre = 'Carmen Rosa Huamaní Paredes', domicilio_fiscal = 'Jr. Mariano Melgar 685 - Lima / Lima / Pueblo Libre'
from public.municipalidades m
where m.id = v.municipalidad_id and m.slug = 'pueblo-libre' and v.codigo_contribuyente = 'PUL-0002';

insert into public.predios (municipalidad_id, vecino_id, codigo, direccion)
select v.municipalidad_id, v.id, 'PUL-PR-0001', 'Jr. Mariano Melgar 685, Pueblo Libre'
from public.vecinos v join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'pueblo-libre' and v.codigo_contribuyente = 'PUL-0002';

insert into public.deudas (municipalidad_id, vecino_id, predio_id, tipo, concepto, anio, trimestre, periodo,
  monto_insoluto, gastos_emision, interes_actualizacion, descuento, pagos_aplicados,
  vencimiento, fecha_pago, estado, nro_valor, exp_coactivo)
select v.municipalidad_id, v.id, p.id, x.tipo, x.concepto, x.anio, x.trimestre, x.periodo,
  x.insoluto, x.ge, x.interes, x.descuento, x.pagado, x.vence::date, x.fecha_pago::date, x.estado, x.nro_valor, x.exp
from public.vecinos v
join public.municipalidades m on m.id = v.municipalidad_id
join public.predios p on p.vecino_id = v.id
cross join (values
    ('predial', 'IMPUESTO PREDIAL', 2025, 1, '2025-TRIM.1', 22.80, 6.40, 0.00, 0.00, 29.20, '2025-02-28', '2025-02-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 2, '2025-TRIM.2', 22.80, 0.00, 0.00, 0.00, 22.80, '2025-05-31', '2025-05-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 3, '2025-TRIM.3', 22.80, 0.00, 0.00, 0.00, 22.80, '2025-08-31', '2025-08-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 4, '2025-TRIM.4', 22.78, 0.00, 0.00, 0.00, 22.78, '2025-11-30', '2025-11-21', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 1, '2026-TRIM.1', 23.90, 6.40, 0.00, 0.00, 30.30, '2026-02-28', '2026-02-21', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 2, '2026-TRIM.2', 23.90, 0.00, 0.00, 0.00, 23.90, '2026-05-31', '2026-05-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 3, '2026-TRIM.3', 23.90, 0.00, 0.00, 0.00, 23.90, '2026-08-31', '2026-08-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 4, '2026-TRIM.4', 23.88, 0.00, 0.00, 0.00, 0.00, '2026-11-30', null, 'vigente', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 1, '2026-TRIM.1', 61.50, 0.00, 0.00, 0.00, 61.50, '2026-02-28', '2026-02-21', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 2, '2026-TRIM.2', 61.50, 0.00, 0.00, 0.00, 61.50, '2026-05-31', '2026-05-23', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 3, '2026-TRIM.3', 61.50, 0.00, 0.00, 0.00, 61.50, '2026-08-31', '2026-08-22', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 4, '2026-TRIM.4', 61.48, 0.00, 0.00, 0.00, 61.48, '2026-11-30', '2026-11-05', 'pagada', null, null)
  ) as x(tipo, concepto, anio, trimestre, periodo, insoluto, ge, interes, descuento, pagado, vence, fecha_pago, estado, nro_valor, exp)
where m.slug = 'pueblo-libre' and v.codigo_contribuyente = 'PUL-0002';

-- Un pago por cada deuda pagada, con el medio y la fecha de pago.
insert into public.pagos (municipalidad_id, vecino_id, deuda_id, monto, medio, estado, referencia, creado_en)
select d.municipalidad_id, d.vecino_id, d.id, d.pagos_aplicados,
  (array['yape', 'plin', 'tarjeta', 'banca_movil'])[1 + (row_number() over (order by d.fecha_pago, d.vencimiento))::int % 4],
  'confirmado', 'OP-' || (70200 + row_number() over (order by d.fecha_pago, d.vencimiento)),
  (d.fecha_pago + time '10:30') at time zone 'America/Lima'
from public.deudas d join public.vecinos v on v.id = d.vecino_id join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'pueblo-libre' and v.codigo_contribuyente = 'PUL-0002' and d.estado = 'pagada' and d.pagos_aplicados > 0;

-- LAV-0003 · la-victoria: dos trimestres pendientes
update public.vecinos v
set nombres = 'Julio César', apellidos = 'Quispe Ramos',
    nombre = 'Julio César Quispe Ramos', domicilio_fiscal = 'Jr. Hipólito Unanue 1120 - Lima / Lima / La Victoria'
from public.municipalidades m
where m.id = v.municipalidad_id and m.slug = 'la-victoria' and v.codigo_contribuyente = 'LAV-0003';

insert into public.predios (municipalidad_id, vecino_id, codigo, direccion)
select v.municipalidad_id, v.id, 'LAV-PR-0001', 'Jr. Hipólito Unanue 1120, La Victoria'
from public.vecinos v join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'la-victoria' and v.codigo_contribuyente = 'LAV-0003';

insert into public.deudas (municipalidad_id, vecino_id, predio_id, tipo, concepto, anio, trimestre, periodo,
  monto_insoluto, gastos_emision, interes_actualizacion, descuento, pagos_aplicados,
  vencimiento, fecha_pago, estado, nro_valor, exp_coactivo)
select v.municipalidad_id, v.id, p.id, x.tipo, x.concepto, x.anio, x.trimestre, x.periodo,
  x.insoluto, x.ge, x.interes, x.descuento, x.pagado, x.vence::date, x.fecha_pago::date, x.estado, x.nro_valor, x.exp
from public.vecinos v
join public.municipalidades m on m.id = v.municipalidad_id
join public.predios p on p.vecino_id = v.id
cross join (values
    ('predial', 'IMPUESTO PREDIAL', 2025, 1, '2025-TRIM.1', 19.40, 5.80, 0.00, 0.00, 25.20, '2025-02-28', '2025-02-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 2, '2025-TRIM.2', 19.40, 0.00, 0.00, 0.00, 19.40, '2025-05-31', '2025-05-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 3, '2025-TRIM.3', 19.40, 0.00, 0.00, 0.00, 19.40, '2025-08-31', '2025-08-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 4, '2025-TRIM.4', 19.38, 0.00, 0.00, 0.00, 19.38, '2025-11-30', '2025-11-21', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 1, '2026-TRIM.1', 20.35, 5.80, 0.00, 0.00, 26.15, '2026-02-28', '2026-02-21', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 2, '2026-TRIM.2', 20.35, 0.00, 0.00, 0.00, 20.35, '2026-05-31', '2026-05-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 3, '2026-TRIM.3', 20.35, 0.00, 0.73, 0.00, 0.00, '2026-08-31', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 4, '2026-TRIM.4', 20.33, 0.00, 0.00, 0.00, 0.00, '2026-11-30', null, 'vigente', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 1, '2026-TRIM.1', 44.20, 0.00, 0.00, 0.00, 44.20, '2026-02-28', '2026-02-21', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 2, '2026-TRIM.2', 44.20, 0.00, 0.00, 0.00, 44.20, '2026-05-31', '2026-05-23', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 3, '2026-TRIM.3', 44.20, 0.00, 0.00, 0.00, 44.20, '2026-08-31', '2026-08-22', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 4, '2026-TRIM.4', 44.18, 0.00, 0.00, 0.00, 44.18, '2026-11-30', '2026-11-05', 'pagada', null, null)
  ) as x(tipo, concepto, anio, trimestre, periodo, insoluto, ge, interes, descuento, pagado, vence, fecha_pago, estado, nro_valor, exp)
where m.slug = 'la-victoria' and v.codigo_contribuyente = 'LAV-0003';

-- Un pago por cada deuda pagada, con el medio y la fecha de pago.
insert into public.pagos (municipalidad_id, vecino_id, deuda_id, monto, medio, estado, referencia, creado_en)
select d.municipalidad_id, d.vecino_id, d.id, d.pagos_aplicados,
  (array['yape', 'plin', 'tarjeta', 'banca_movil'])[1 + (row_number() over (order by d.fecha_pago, d.vencimiento))::int % 4],
  'confirmado', 'OP-' || (70300 + row_number() over (order by d.fecha_pago, d.vencimiento)),
  (d.fecha_pago + time '10:30') at time zone 'America/Lima'
from public.deudas d join public.vecinos v on v.id = d.vecino_id join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'la-victoria' and v.codigo_contribuyente = 'LAV-0003' and d.estado = 'pagada' and d.pagos_aplicados > 0;

-- MIR-0004 · miraflores: deuda de varios años
update public.vecinos v
set nombres = 'Patricia Elena', apellidos = 'Vásquez Lara',
    nombre = 'Patricia Elena Vásquez Lara', domicilio_fiscal = 'Calle Schell 345, Dpto. 801 - Lima / Lima / Miraflores'
from public.municipalidades m
where m.id = v.municipalidad_id and m.slug = 'miraflores' and v.codigo_contribuyente = 'MIR-0004';

insert into public.predios (municipalidad_id, vecino_id, codigo, direccion)
select v.municipalidad_id, v.id, 'MIR-PR-0001', 'Calle Schell 345, Dpto. 801, Miraflores'
from public.vecinos v join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'miraflores' and v.codigo_contribuyente = 'MIR-0004';

insert into public.deudas (municipalidad_id, vecino_id, predio_id, tipo, concepto, anio, trimestre, periodo,
  monto_insoluto, gastos_emision, interes_actualizacion, descuento, pagos_aplicados,
  vencimiento, fecha_pago, estado, nro_valor, exp_coactivo)
select v.municipalidad_id, v.id, p.id, x.tipo, x.concepto, x.anio, x.trimestre, x.periodo,
  x.insoluto, x.ge, x.interes, x.descuento, x.pagado, x.vence::date, x.fecha_pago::date, x.estado, x.nro_valor, x.exp
from public.vecinos v
join public.municipalidades m on m.id = v.municipalidad_id
join public.predios p on p.vecino_id = v.id
cross join (values
    ('predial', 'IMPUESTO PREDIAL', 2023, 1, '2023-TRIM.1', 41.20, 8.90, 22.25, 0.00, 0.00, '2023-02-28', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2023, 2, '2023-TRIM.2', 41.20, 0.00, 20.76, 0.00, 0.00, '2023-05-31', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2023, 3, '2023-TRIM.3', 41.20, 0.00, 19.28, 0.00, 0.00, '2023-08-31', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2023, 4, '2023-TRIM.4', 41.18, 0.00, 17.79, 0.00, 0.00, '2023-11-30', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 1, '2024-TRIM.1', 43.75, 8.90, 0.00, 0.00, 52.65, '2024-02-29', '2024-02-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 2, '2024-TRIM.2', 43.75, 0.00, 0.00, 0.00, 43.75, '2024-05-31', '2024-05-25', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 3, '2024-TRIM.3', 43.75, 0.00, 14.18, 0.00, 0.00, '2024-08-31', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 4, '2024-TRIM.4', 43.73, 0.00, 12.59, 0.00, 0.00, '2024-11-30', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 1, '2025-TRIM.1', 45.10, 8.90, 0.00, 0.00, 54.00, '2025-02-28', '2025-02-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 2, '2025-TRIM.2', 45.10, 0.00, 0.00, 0.00, 45.10, '2025-05-31', '2025-05-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 3, '2025-TRIM.3', 45.10, 0.00, 0.00, 0.00, 45.10, '2025-08-31', '2025-08-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 4, '2025-TRIM.4', 45.08, 0.00, 6.49, 0.00, 0.00, '2025-11-30', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 1, '2026-TRIM.1', 47.30, 8.90, 0.00, 0.00, 56.20, '2026-02-28', '2026-02-21', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 2, '2026-TRIM.2', 47.30, 0.00, 0.00, 0.00, 47.30, '2026-05-31', '2026-05-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 3, '2026-TRIM.3', 47.30, 0.00, 1.70, 0.00, 0.00, '2026-08-31', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 4, '2026-TRIM.4', 47.28, 0.00, 0.00, 0.00, 0.00, '2026-11-30', null, 'vigente', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2025, 1, '2025-TRIM.1', 88.40, 0.00, 0.00, 0.00, 88.40, '2025-02-28', '2025-02-22', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2025, 2, '2025-TRIM.2', 88.40, 0.00, 0.00, 0.00, 88.40, '2025-05-31', '2025-05-24', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2025, 3, '2025-TRIM.3', 88.40, 0.00, 15.91, 0.00, 0.00, '2025-08-31', null, 'vencida', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2025, 4, '2025-TRIM.4', 88.38, 0.00, 12.73, 0.00, 0.00, '2025-11-30', null, 'vencida', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 1, '2026-TRIM.1', 92.60, 0.00, 0.00, 0.00, 92.60, '2026-02-28', '2026-02-21', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 2, '2026-TRIM.2', 92.60, 0.00, 0.00, 0.00, 92.60, '2026-05-31', '2026-05-23', 'pagada', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 3, '2026-TRIM.3', 92.60, 0.00, 3.33, 0.00, 0.00, '2026-08-31', null, 'vencida', null, null),
    ('arbitrios', 'ARBITRIOS MUNICIPALES', 2026, 4, '2026-TRIM.4', 92.58, 0.00, 0.00, 0.00, 0.00, '2026-11-30', null, 'vigente', null, null)
  ) as x(tipo, concepto, anio, trimestre, periodo, insoluto, ge, interes, descuento, pagado, vence, fecha_pago, estado, nro_valor, exp)
where m.slug = 'miraflores' and v.codigo_contribuyente = 'MIR-0004';

-- Un pago por cada deuda pagada, con el medio y la fecha de pago.
insert into public.pagos (municipalidad_id, vecino_id, deuda_id, monto, medio, estado, referencia, creado_en)
select d.municipalidad_id, d.vecino_id, d.id, d.pagos_aplicados,
  (array['yape', 'plin', 'tarjeta', 'banca_movil'])[1 + (row_number() over (order by d.fecha_pago, d.vencimiento))::int % 4],
  'confirmado', 'OP-' || (70400 + row_number() over (order by d.fecha_pago, d.vencimiento)),
  (d.fecha_pago + time '10:30') at time zone 'America/Lima'
from public.deudas d join public.vecinos v on v.id = d.vecino_id join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'miraflores' and v.codigo_contribuyente = 'MIR-0004' and d.estado = 'pagada' and d.pagos_aplicados > 0;

-- CER-0005 · cercado-de-lima: deuda en cobranza coactiva
update public.vecinos v
set nombres = 'Luis Fernando', apellidos = 'Mendoza Rojas',
    nombre = 'Luis Fernando Mendoza Rojas', domicilio_fiscal = 'Jr. Ancash 560, Int. 12 - Lima / Lima / Cercado de Lima'
from public.municipalidades m
where m.id = v.municipalidad_id and m.slug = 'cercado-de-lima' and v.codigo_contribuyente = 'CER-0005';

insert into public.predios (municipalidad_id, vecino_id, codigo, direccion)
select v.municipalidad_id, v.id, 'CER-PR-0001', 'Jr. Ancash 560, Int. 12, Cercado de Lima'
from public.vecinos v join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'cercado-de-lima' and v.codigo_contribuyente = 'CER-0005';

insert into public.deudas (municipalidad_id, vecino_id, predio_id, tipo, concepto, anio, trimestre, periodo,
  monto_insoluto, gastos_emision, interes_actualizacion, descuento, pagos_aplicados,
  vencimiento, fecha_pago, estado, nro_valor, exp_coactivo)
select v.municipalidad_id, v.id, p.id, x.tipo, x.concepto, x.anio, x.trimestre, x.periodo,
  x.insoluto, x.ge, x.interes, x.descuento, x.pagado, x.vence::date, x.fecha_pago::date, x.estado, x.nro_valor, x.exp
from public.vecinos v
join public.municipalidades m on m.id = v.municipalidad_id
join public.predios p on p.vecino_id = v.id
cross join (values
    ('predial', 'IMPUESTO PREDIAL', 2024, 1, '2024-TRIM.1', 25.60, 7.00, 0.00, 0.00, 32.60, '2024-02-29', '2024-02-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 2, '2024-TRIM.2', 25.60, 0.00, 0.00, 0.00, 25.60, '2024-05-31', '2024-05-25', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 3, '2024-TRIM.3', 25.60, 0.00, 0.00, 0.00, 25.60, '2024-08-31', '2024-08-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2024, 4, '2024-TRIM.4', 25.58, 0.00, 0.00, 0.00, 25.58, '2024-11-30', '2024-11-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 1, '2025-TRIM.1', 26.90, 7.00, 0.00, 0.00, 33.90, '2025-02-28', '2025-02-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 2, '2025-TRIM.2', 26.90, 0.00, 0.00, 0.00, 26.90, '2025-05-31', '2025-05-24', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 3, '2025-TRIM.3', 26.90, 0.00, 0.00, 0.00, 26.90, '2025-08-31', '2025-08-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2025, 4, '2025-TRIM.4', 26.88, 0.00, 3.87, 0.00, 0.00, '2025-11-30', null, 'vencida', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 1, '2026-TRIM.1', 27.80, 7.00, 0.00, 0.00, 34.80, '2026-02-28', '2026-02-21', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 2, '2026-TRIM.2', 27.80, 0.00, 0.00, 0.00, 27.80, '2026-05-31', '2026-05-23', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 3, '2026-TRIM.3', 27.80, 0.00, 0.00, 0.00, 27.80, '2026-08-31', '2026-08-22', 'pagada', null, null),
    ('predial', 'IMPUESTO PREDIAL', 2026, 4, '2026-TRIM.4', 27.78, 0.00, 0.00, 0.00, 0.00, '2026-11-30', null, 'vigente', null, null),
    ('coactivo', 'COBRANZA COACTIVA · IMPUESTO PREDIAL 2023', 2023, 4, '2023-TRIM.4', 412.30, 38.50, 71.20, 0.00, 0.00, '2023-11-30', null, 'vencida', 'RD-2024-003187', 'EC-0457-2025'),
    ('coactivo', 'COBRANZA COACTIVA · ARBITRIOS 2023', 2023, 4, '2023-TRIM.4', 286.90, 38.50, 52.10, 0.00, 0.00, '2023-11-30', null, 'vencida', 'RD-2024-003188', 'EC-0457-2025')
  ) as x(tipo, concepto, anio, trimestre, periodo, insoluto, ge, interes, descuento, pagado, vence, fecha_pago, estado, nro_valor, exp)
where m.slug = 'cercado-de-lima' and v.codigo_contribuyente = 'CER-0005';

-- Un pago por cada deuda pagada, con el medio y la fecha de pago.
insert into public.pagos (municipalidad_id, vecino_id, deuda_id, monto, medio, estado, referencia, creado_en)
select d.municipalidad_id, d.vecino_id, d.id, d.pagos_aplicados,
  (array['yape', 'plin', 'tarjeta', 'banca_movil'])[1 + (row_number() over (order by d.fecha_pago, d.vencimiento))::int % 4],
  'confirmado', 'OP-' || (70500 + row_number() over (order by d.fecha_pago, d.vencimiento)),
  (d.fecha_pago + time '10:30') at time zone 'America/Lima'
from public.deudas d join public.vecinos v on v.id = d.vecino_id join public.municipalidades m on m.id = v.municipalidad_id
where m.slug = 'cercado-de-lima' and v.codigo_contribuyente = 'CER-0005' and d.estado = 'pagada' and d.pagos_aplicados > 0;

-- Número de cuponera (dato privado, distinto del código de contribuyente) de cada contribuyente.
update public.vecinos v set numero_cuponera = x.cuponera
from (values
  ('lince', 'LIN-0001', '5817403962'),
  ('pueblo-libre', 'PUL-0002', '6204891735'),
  ('la-victoria', 'LAV-0003', '4952706183'),
  ('miraflores', 'MIR-0004', '8136520947'),
  ('cercado-de-lima', 'CER-0005', '3079468215'),
  ('lince', '0048217', '7390215846')
) as x(slug, codigo, cuponera), public.municipalidades m
where m.id = v.municipalidad_id and m.slug = x.slug and v.codigo_contribuyente = x.codigo;

-- Los contribuyentes anteriores de Lince y Villa Verde pasan a verse como datos normales.
update public.vecinos set nombre = replace(nombre, ' (ejemplo)', ''),
  nombres = coalesce(nombres, 'Rosa'), apellidos = coalesce(apellidos, 'Quispe Huamán'),
  domicilio_fiscal = coalesce(domicilio_fiscal, 'Jr. Bernardo Alcedo 480 - Lima / Lima / Lince')
where dni = '40000082';
update public.deudas set anio = extract(year from vencimiento)::integer where anio is null;

commit;

select m.slug, v.codigo_contribuyente, v.nombre,
  (select count(*) from public.deudas d where d.vecino_id = v.id and d.saldo > 0) as periodos_pendientes,
  (select coalesce(sum(d.saldo), 0) from public.deudas d where d.vecino_id = v.id) as saldo_total
from public.vecinos v join public.municipalidades m on m.id = v.municipalidad_id
where v.codigo_contribuyente in ('LIN-0001', 'PUL-0002', 'LAV-0003', 'MIR-0004', 'CER-0005') order by 2;
