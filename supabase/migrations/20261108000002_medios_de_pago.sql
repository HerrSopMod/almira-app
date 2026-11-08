-- Medios de pago de la pantalla "Confirma tu pago" del prototipo:
-- Yape, Plin, tarjeta de débito o crédito, y banca móvil o agente.
-- No crea tablas ni cambia políticas.

alter table public.pagos drop constraint pagos_medio_check;
update public.pagos set medio = case medio
  when 'billetera' then 'yape'
  when 'pagoefectivo' then 'banca_movil'
  else medio
end;
alter table public.pagos add constraint pagos_medio_check
  check (medio in ('yape', 'plin', 'tarjeta', 'banca_movil'));
