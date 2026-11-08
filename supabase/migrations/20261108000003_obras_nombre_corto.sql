-- Nombre corto de la obra para los mensajes de aviso del prototipo
-- ("tu aporte financia obras como el parque Castilla").
-- No crea tablas ni cambia políticas: el personal ya escribe obras con
-- "personal registra obras" y "personal actualiza obras".

alter table public.obras add column nombre_corto text
  check (nombre_corto is null or length(trim(nombre_corto)) > 0);
