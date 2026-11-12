-- Programa los recordatorios por WhatsApp: todos los días a las 10:00 de Lima (15:00 UTC).
-- NO es una migración: lleva datos de tu proyecto. Córrelo una vez, a mano, con los dos valores
-- de abajo cambiados (SQL Editor del panel de Supabase, o `supabase db query --linked -f`).
--
--   1. <REF_DEL_PROYECTO>: el identificador del proyecto (la parte antes de .supabase.co).
--   2. <RECORDATORIOS_SECRETO>: el mismo valor que pusiste con
--        supabase secrets set RECORDATORIOS_SECRETO=...
--
-- El secreto se guarda en Vault, no en el texto del trabajo programado. Requiere las extensiones
-- pg_cron y pg_net (Dashboard > Database > Extensions).

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- Guarda el secreto (si ya existe, bórralo antes: select vault.delete_secret(id) ...).
select vault.create_secret('<RECORDATORIOS_SECRETO>', 'recordatorios_secreto');

select cron.schedule(
  'enviar-recordatorios-whatsapp',
  '0 15 * * *',
  $cron$
    select net.http_post(
      url := 'https://<REF_DEL_PROYECTO>.supabase.co/functions/v1/enviar-recordatorios',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'recordatorios_secreto')
      ),
      body := '{"accion":"ejecutar"}'::jsonb,
      timeout_milliseconds := 120000
    );
  $cron$
);

-- Para ver que quedó programado y las últimas corridas:
--   select jobid, schedule, jobname from cron.job;
--   select status, return_message, start_time from cron.job_run_details order by start_time desc limit 5;
-- Para quitarlo:
--   select cron.unschedule('enviar-recordatorios-whatsapp');
