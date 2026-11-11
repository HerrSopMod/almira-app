-- El vecino guarda el celular de sus avisos. El cliente no puede escribir `vecinos.telefono`
-- (solo `canal_preferido`), así que va por una función que corre como dueño y solo toca las
-- filas de la propia cuenta. El teléfono nunca se registra en logs.

create function public.guardar_celular(p_celular text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_usuario uuid := (select auth.uid());
  v_filas integer;
begin
  if v_usuario is null or p_celular is null or p_celular !~ '^9[0-9]{8}$' then
    return false;
  end if;
  update public.vecinos set telefono = p_celular where user_id = v_usuario;
  get diagnostics v_filas = row_count;
  return v_filas > 0;
end;
$$;

revoke all on function public.guardar_celular(text) from public, anon;
grant execute on function public.guardar_celular(text) to authenticated;
