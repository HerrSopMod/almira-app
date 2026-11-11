// Edge Function: registro e ingreso con número de cuponera.
// La tabla de contribuyentes nunca se expone al cliente: la cuponera se valida aquí, con
// service_role, y recién entonces se crea la cuenta y se vincula con el contribuyente.
//
// Acciones (POST, JSON):
//   { accion: 'municipalidades' }
//   { accion: 'verificar', slug, cuponera, dni }   (comprueba sin crear nada)
//   { accion: 'registrar', slug, cuponera, dni, correo, clave, celular }
//   { accion: 'ingresar', cuponera, clave }  → devuelve la sesión
//
// Cualquier fallo de validación responde igual: no revela si falló la municipalidad, la
// cuponera, el DNI o si ya estaba vinculada. Nunca se escriben DNI, correos ni teléfonos en logs.
import { createClient } from 'jsr:@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const MENSAJE_GENERICO = 'No pudimos verificar tus datos. Revisa la municipalidad, la cuponera y el DNI.';
const MAXIMO_FALLOS = 8;
const VENTANA_MINUTOS = 15;

function responder(cuerpo: unknown, status = 200) {
  return new Response(JSON.stringify(cuerpo), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });
}

const rechazo = () => responder({ ok: false, error: MENSAJE_GENERICO }, 400);

async function huella(texto: string): Promise<string> {
  const datos = new TextEncoder().encode(`almira:${texto}`);
  const hash = await crypto.subtle.digest('SHA-256', datos);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
    .slice(0, 32);
}

const normalizarCuponera = (texto: unknown) => String(texto ?? '').trim().toUpperCase();
const soloDigitos = (texto: unknown) => String(texto ?? '').replace(/\D/g, '');
const correoValido = (texto: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(texto);

Deno.serve(async (solicitud) => {
  if (solicitud.method === 'OPTIONS') return new Response(null, { headers: CORS });
  if (solicitud.method !== 'POST') return responder({ error: 'Método no permitido' }, 405);

  let cuerpo: Record<string, unknown>;
  try {
    cuerpo = await solicitud.json();
  } catch {
    return responder({ error: 'Solicitud inválida' }, 400);
  }

  const url = Deno.env.get('SUPABASE_URL')!;
  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false },
  });

  if (cuerpo.accion === 'municipalidades') {
    const { data, error } = await admin
      .from('municipalidades')
      .select('id, slug, nombre, zona')
      .eq('activa', true)
      .order('nombre');
    if (error) return responder({ ok: false, error: 'No pudimos cargar las municipalidades.' }, 500);
    return responder({ ok: true, municipalidades: data });
  }

  if (cuerpo.accion !== 'registrar' && cuerpo.accion !== 'verificar' && cuerpo.accion !== 'ingresar') {
    return responder({ error: 'Acción no válida' }, 400);
  }

  // Límite de fallos por origen: frena la prueba de cuponeras al azar.
  const origen = await huella(
    (solicitud.headers.get('x-forwarded-for') ?? 'sin-origen').split(',')[0]!.trim(),
  );
  const desde = new Date(Date.now() - VENTANA_MINUTOS * 60_000).toISOString();
  const { count } = await admin
    .from('intentos_registro')
    .select('id', { count: 'exact', head: true })
    .eq('origen', origen)
    .eq('acertado', false)
    .gte('creado_en', desde);
  if ((count ?? 0) >= MAXIMO_FALLOS) {
    return responder({ ok: false, error: 'Hiciste demasiados intentos. Espera unos minutos.' }, 429);
  }
  const fallar = async (municipalidadId: string | null) => {
    await admin
      .from('intentos_registro')
      .insert({ municipalidad_id: municipalidadId, origen, acertado: false });
    return rechazo();
  };

  const cuponera = normalizarCuponera(cuerpo.cuponera);
  const clave = String(cuerpo.clave ?? '');
  // En 'verificar' todavía no hay clave: solo se comprueban la cuponera y el DNI.
  if (cuponera.length < 4 || (cuerpo.accion !== 'verificar' && clave.length < 8)) {
    return await fallar(null);
  }

  if (cuerpo.accion === 'ingresar') {
    // Ingreso con cuponera: se busca el contribuyente ya vinculado y se inicia sesión con su correo.
    const { data: filas } = await admin
      .from('vecinos')
      .select('id, municipalidad_id, user_id')
      .eq('codigo_contribuyente', cuponera)
      .not('user_id', 'is', null);
    if (!filas || filas.length !== 1) return await fallar(null);
    const fila = filas[0]!;
    const { data: usuario } = await admin.auth.admin.getUserById(fila.user_id as string);
    const correo = usuario?.user?.email;
    if (!correo) return await fallar(fila.municipalidad_id as string);

    const cliente = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
      auth: { persistSession: false },
    });
    const { data: sesion, error } = await cliente.auth.signInWithPassword({ email: correo, password: clave });
    if (error || !sesion.session) return await fallar(fila.municipalidad_id as string);
    return responder({
      ok: true,
      access_token: sesion.session.access_token,
      refresh_token: sesion.session.refresh_token,
    });
  }

  // Registro.
  const slug = String(cuerpo.slug ?? '').trim();
  const dni = soloDigitos(cuerpo.dni);
  const correo = String(cuerpo.correo ?? '').trim().toLowerCase();
  const celular = soloDigitos(cuerpo.celular);
  const soloVerificar = cuerpo.accion === 'verificar';
  if (!slug || dni.length !== 8 || (!soloVerificar && !correoValido(correo))) {
    return await fallar(null);
  }

  const { data: municipalidad } = await admin
    .from('municipalidades')
    .select('id')
    .eq('slug', slug)
    .eq('activa', true)
    .maybeSingle();
  if (!municipalidad) return await fallar(null);

  // Misma municipalidad, cuponera y DNI, y que nadie la haya vinculado todavía.
  const { data: contribuyente } = await admin
    .from('vecinos')
    .select('id, nombre')
    .eq('municipalidad_id', municipalidad.id)
    .eq('codigo_contribuyente', cuponera)
    .eq('dni', dni)
    .is('user_id', null)
    .maybeSingle();
  if (!contribuyente) return await fallar(municipalidad.id as string);
  if (soloVerificar) return responder({ ok: true });

  const { data: creado, error: errorCuenta } = await admin.auth.admin.createUser({
    email: correo,
    password: clave,
    email_confirm: true,
    user_metadata: { full_name: contribuyente.nombre },
  });
  if (errorCuenta || !creado.user) return await fallar(municipalidad.id as string);

  // Vínculo atómico: solo si sigue libre. Si otra solicitud ganó, se deshace la cuenta.
  const cambios: Record<string, unknown> = { user_id: creado.user.id };
  if (celular.length === 9) cambios.telefono = celular;
  const { data: vinculado } = await admin
    .from('vecinos')
    .update(cambios)
    .eq('id', contribuyente.id)
    .is('user_id', null)
    .select('id');
  if (!vinculado || vinculado.length === 0) {
    await admin.auth.admin.deleteUser(creado.user.id);
    return await fallar(municipalidad.id as string);
  }
  await admin.from('vinculos_contribuyente').insert({
    municipalidad_id: municipalidad.id,
    user_id: creado.user.id,
    vecino_id: contribuyente.id,
    codigo: cuponera,
  });
  return responder({ ok: true });
});
