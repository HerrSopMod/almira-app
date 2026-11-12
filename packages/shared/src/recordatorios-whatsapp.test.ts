// Pruebas de los recordatorios por WhatsApp (supabase/functions/enviar-recordatorios y
// whatsapp-webhook), con la API de Meta simulada y almacenes en memoria.
import migracionSql from '../../../supabase/migrations/20261112000002_recordatorios_whatsapp.sql?raw';
import { describe, expect, it } from 'vitest';
import {
  dentroDeHorario,
  elegible,
  enviarUno,
  fechaCorta,
  construirMensaje,
  municipalidadCorta,
  montoSinMoneda,
  nombreDeTributos,
  procesarCandidatos,
  variablesSeguras,
  PLANTILLAS,
  type Candidato,
  type DependenciasEnvio,
  type Marca,
  type RegistroNuevo,
} from '../../../supabase/functions/enviar-recordatorios/logica.ts';
import {
  crearManejador as crearManejadorRecordatorios,
  type AlmacenCompleto,
  type DatosBienvenida,
} from '../../../supabase/functions/enviar-recordatorios/manejador.ts';
import {
  crearManejador as crearManejadorWebhook,
  esBaja,
  MENSAJE_BAJA,
  MENSAJE_GENERAL,
  type AlmacenWebhook,
  type EstadoMensaje,
} from '../../../supabase/functions/whatsapp-webhook/manejador.ts';
import {
  enmascararTelefono,
  enviarPlantilla,
  firmarCuerpo,
  firmaValida,
  limpiarVariable,
  type FetchLike,
} from '../../../supabase/functions/_shared/whatsapp.ts';

// 12 de noviembre de 2026, 10:00 en Lima (15:00 UTC).
const A_LAS_10 = new Date('2026-11-12T15:00:00Z');

const ENV: Record<string, string> = {
  WA_PHONE_NUMBER_ID: '123456',
  WA_ACCESS_TOKEN: 'token-de-prueba',
  WA_APP_SECRET: 'secreto-de-la-app',
  WA_VERIFY_TOKEN: 'verificacion',
  RECORDATORIOS_SECRETO: 'secreto-programado',
};
const env = (n: string) => ENV[n];

const candidato = (extra: Partial<Candidato> = {}): Candidato => ({
  vecino_id: 'v1',
  municipalidad_id: 'm1',
  municipalidad: 'Municipalidad de Lince',
  nombre: 'Rosa',
  numero: '+51987654321',
  tipo: 'vencimiento',
  periodo: '2026-11-15',
  tipos: ['predial'],
  monto: 80.5,
  fecha: '2026-11-15',
  referencia: null,
  con_coactivo: false,
  saldo_pendiente: 120.5,
  whatsapp_activo: true,
  optout_at: null,
  consentimiento_at: '2026-11-01T12:00:00Z',
  ...extra,
});

// --- Meta simulada ---
type Llamada = { url: string; cuerpo: Record<string, any> };

function metaSimulada(respuestas: { status: number; cuerpo: unknown }[] = []) {
  const llamadas: Llamada[] = [];
  let i = 0;
  const fetchMeta: FetchLike = async (url, init) => {
    llamadas.push({ url, cuerpo: JSON.parse(init.body) });
    const r = respuestas[Math.min(i++, respuestas.length - 1)] ?? {
      status: 200,
      cuerpo: { messages: [{ id: `wamid.${i}` }] },
    };
    return { ok: r.status >= 200 && r.status < 300, status: r.status, json: async () => r.cuerpo };
  };
  return { fetchMeta, llamadas };
}

const OK = { status: 200, cuerpo: { messages: [{ id: 'wamid.ABC' }] } };

// --- Almacén en memoria, con la restricción única (contribuyente, tipo, periodo) ---
function almacenEnMemoria() {
  const registros = new Map<string, RegistroNuevo & { estado: string; wa?: string | null; error?: string | null }>();
  const clave = (vecino: string, tipo: string, periodo: string) => `${vecino}|${tipo}|${periodo}`;
  return {
    registros,
    async reclamar(r: RegistroNuevo) {
      const k = clave(r.vecino_id, r.tipo, r.periodo);
      if (registros.has(k)) return false;
      registros.set(k, { ...r, estado: 'en_cola' });
      return true;
    },
    async marcar(m: Marca) {
      const r = registros.get(clave(m.vecino_id, m.tipo, m.periodo))!;
      r.estado = m.estado;
      r.wa = m.wa_message_id ?? null;
      r.error = m.error_resumen ?? null;
    },
  };
}

function dependencias(meta = metaSimulada([OK])) {
  const almacen = almacenEnMemoria();
  const logs: string[] = [];
  const pausas: number[] = [];
  const dep: DependenciasEnvio = {
    almacen,
    fetchMeta: meta.fetchMeta,
    env,
    pausa: async (ms) => {
      pausas.push(ms);
    },
    log: (...partes) => logs.push(partes.join(' ')),
  };
  return { dep, almacen, meta, logs, pausas };
}

describe('horario', () => {
  it('solo de 9:00 a 20:00, hora de Lima', () => {
    expect(dentroDeHorario(new Date('2026-11-12T14:00:00Z'))).toBe(true); // 9:00
    expect(dentroDeHorario(new Date('2026-11-12T13:59:00Z'))).toBe(false); // 8:59
    expect(dentroDeHorario(new Date('2026-11-13T00:59:00Z'))).toBe(true); // 19:59
    expect(dentroDeHorario(new Date('2026-11-13T01:00:00Z'))).toBe(false); // 20:00
    expect(dentroDeHorario(new Date('2026-11-12T03:00:00Z'))).toBe(false); // 22:00 del día anterior
  });
});

describe('quién recibe un aviso', () => {
  it('con todo en regla, sí', () => {
    expect(elegible(candidato(), A_LAS_10)).toEqual({ ok: true });
  });

  it('nunca con saldo 0', () => {
    expect(elegible(candidato({ saldo_pendiente: 0 }), A_LAS_10)).toEqual({ ok: false, motivo: 'saldo_cero' });
    expect(elegible(candidato({ tipo: 'pendiente', saldo_pendiente: '0.00' }), A_LAS_10)).toEqual({
      ok: false,
      motivo: 'saldo_cero',
    });
  });

  it('nunca sin consentimiento, con baja o con el servicio apagado', () => {
    expect(elegible(candidato({ consentimiento_at: null }), A_LAS_10)).toEqual({ ok: false, motivo: 'sin_consentimiento' });
    expect(elegible(candidato({ optout_at: '2026-11-10T10:00:00Z' }), A_LAS_10)).toEqual({ ok: false, motivo: 'baja' });
    expect(elegible(candidato({ whatsapp_activo: false }), A_LAS_10)).toEqual({ ok: false, motivo: 'inactivo' });
  });

  it('nunca con un número que no es E.164', () => {
    expect(elegible(candidato({ numero: '987654321' }), A_LAS_10)).toEqual({ ok: false, motivo: 'numero_invalido' });
  });

  it('nunca fuera de horario, salvo la bienvenida que pide la propia persona', () => {
    const noche = new Date('2026-11-13T03:00:00Z'); // 22:00 en Lima
    expect(elegible(candidato(), noche)).toEqual({ ok: false, motivo: 'fuera_de_horario' });
    expect(elegible(candidato({ tipo: 'bienvenida' }), noche)).toEqual({ ok: true });
  });

  it('la confirmación de un pago sale aunque el saldo haya quedado en 0', () => {
    const pago = candidato({ tipo: 'pago_confirmado', saldo_pendiente: 0, monto: 41.35, referencia: 'OP-90500' });
    expect(elegible(pago, A_LAS_10)).toEqual({ ok: true });
  });
});

describe('envío', () => {
  it('manda una plantilla con las variables numeradas y deja el registro', async () => {
    const { dep, almacen, meta } = dependencias();
    const r = await enviarUno(candidato(), A_LAS_10, dep);
    expect(r.estado).toBe('enviado');
    expect(meta.llamadas).toHaveLength(1);
    const { url, cuerpo } = meta.llamadas[0]!;
    expect(url).toBe('https://graph.facebook.com/v25.0/123456/messages');
    expect(cuerpo.to).toBe('51987654321');
    expect(cuerpo.type).toBe('template');
    expect(cuerpo.template.name).toBe(PLANTILLAS.vencimiento);
    expect(cuerpo.template.language.code).toBe('es_PE');
    expect(cuerpo.template.components[0].parameters.map((p: { text: string }) => p.text)).toEqual([
      'Rosa',
      'Lince',
      'impuesto predial',
      '15 de noviembre',
    ]);
    expect([...almacen.registros.values()][0]).toMatchObject({ estado: 'enviado', wa: 'wamid.ABC' });
  });

  it('no manda nada con saldo 0, sin consentimiento ni con baja', async () => {
    const { dep, meta, almacen } = dependencias();
    for (const c of [
      candidato({ saldo_pendiente: 0 }),
      candidato({ consentimiento_at: null }),
      candidato({ optout_at: '2026-11-10T00:00:00Z' }),
      candidato({ whatsapp_activo: false }),
    ]) {
      expect((await enviarUno(c, A_LAS_10, dep)).estado).toBe('omitido');
    }
    expect(meta.llamadas).toHaveLength(0);
    expect(almacen.registros.size).toBe(0);
  });

  it('no manda nada fuera de horario', async () => {
    const { dep, meta } = dependencias();
    const resumen = await procesarCandidatos([candidato()], new Date('2026-11-13T03:00:00Z'), dep);
    expect(resumen).toMatchObject({ enviados: 0, omitidos: 1, fuera_de_horario: true });
    expect(meta.llamadas).toHaveLength(0);
  });

  it('no manda dos veces el mismo tipo y periodo', async () => {
    const { dep, meta } = dependencias();
    const a = await enviarUno(candidato(), A_LAS_10, dep);
    const b = await enviarUno(candidato(), A_LAS_10, dep);
    expect([a.estado, b.estado]).toEqual(['enviado', 'duplicado']);
    expect(meta.llamadas).toHaveLength(1);
    // Otro periodo del mismo tipo sí sale.
    const c = await enviarUno(candidato({ periodo: '2026-11-30', fecha: '2026-11-30' }), A_LAS_10, dep);
    expect(c.estado).toBe('enviado');
    expect(meta.llamadas).toHaveLength(2);
  });

  it('un aviso fallido no se vuelve a mandar con el mismo periodo, y deja el código del error', async () => {
    const { dep, almacen } = dependencias(metaSimulada([{ status: 400, cuerpo: { error: { code: 131030 } } }]));
    const a = await enviarUno(candidato(), A_LAS_10, dep);
    expect(a).toEqual({ estado: 'fallido', motivo: 'meta_131030' });
    expect([...almacen.registros.values()][0]).toMatchObject({ estado: 'fallido', error: 'meta_131030' });
    expect((await enviarUno(candidato(), A_LAS_10, dep)).estado).toBe('duplicado');
  });

  it('reintenta los errores transitorios con una pausa creciente', async () => {
    const meta = metaSimulada([
      { status: 503, cuerpo: {} },
      { status: 429, cuerpo: { error: { code: 130429 } } },
      OK,
    ]);
    const { dep, pausas } = dependencias(meta);
    const r = await enviarUno(candidato(), A_LAS_10, dep);
    expect(r.estado).toBe('enviado');
    expect(meta.llamadas).toHaveLength(3);
    expect(pausas).toEqual([500, 1000]);
  });

  it('no reintenta un error permanente', async () => {
    const meta = metaSimulada([{ status: 400, cuerpo: { error: { code: 131030 } } }]);
    const { dep } = dependencias(meta);
    await enviarUno(candidato(), A_LAS_10, dep);
    expect(meta.llamadas).toHaveLength(1);
  });

  it('si la cuenta no tiene la plantilla en es_PE, prueba con es', async () => {
    const meta = metaSimulada([{ status: 404, cuerpo: { error: { code: 132001 } } }, OK]);
    const r = await enviarPlantilla(meta.fetchMeta, env, '+51987654321', 'almira_bienvenida', ['Rosa']);
    expect(r.ok).toBe(true);
    expect(meta.llamadas.map((l) => l.cuerpo.template.language.code)).toEqual(['es_PE', 'es']);
  });

  it('sin credenciales no envía y lo dice sin ruido', async () => {
    const meta = metaSimulada([OK]);
    const r = await enviarPlantilla(meta.fetchMeta, () => undefined, '+51987654321', 'almira_bienvenida', ['Rosa']);
    expect(r).toEqual({ ok: false, codigo: 'sin_configurar', transitorio: false });
    expect(meta.llamadas).toHaveLength(0);
  });

  it('en los logs el teléfono va enmascarado', async () => {
    const { dep, logs } = dependencias(metaSimulada([{ status: 400, cuerpo: { error: { code: 131030 } } }]));
    await enviarUno(candidato(), A_LAS_10, dep);
    const texto = logs.join('\n');
    expect(texto).toContain('+51 9** *** 321');
    expect(texto).not.toContain('987654321');
  });

  it('procesa varios candidatos, con una pausa corta entre envíos', async () => {
    const { dep, pausas } = dependencias();
    const resumen = await procesarCandidatos(
      [candidato(), candidato({ vecino_id: 'v2', nombre: 'Luis' }), candidato({ vecino_id: 'v3', saldo_pendiente: 0 })],
      A_LAS_10,
      dep,
    );
    expect(resumen).toMatchObject({ candidatos: 3, enviados: 2, omitidos: 1, fallidos: 0, duplicados: 0 });
    expect(pausas).toEqual([150, 150]);
  });
});

describe('plantillas y variables', () => {
  it('pendiente: nombre, monto sin "S/" y municipalidad', () => {
    expect(construirMensaje(candidato({ tipo: 'pendiente', monto: 1234.5 }))).toEqual({
      plantilla: 'almira_pendiente',
      variables: ['Rosa', '1,234.50', 'Lince'],
    });
  });

  it('pendiente con cobranza coactiva usa la variante informativa, sin monto', () => {
    const m = construirMensaje(candidato({ tipo: 'pendiente', con_coactivo: true, monto: 958.03 }))!;
    expect(m.plantilla).toBe('almira_pendiente_info');
    expect(m.variables).toEqual(['Rosa', 'Lince']);
  });

  it('pago confirmado y bienvenida', () => {
    expect(construirMensaje(candidato({ tipo: 'pago_confirmado', monto: 41.35, referencia: 'OP-90500' }))).toEqual({
      plantilla: 'almira_pago_confirmado',
      variables: ['Rosa', '41.35', 'OP-90500'],
    });
    expect(construirMensaje(candidato({ tipo: 'bienvenida' }))).toEqual({
      plantilla: 'almira_bienvenida',
      variables: ['Rosa'],
    });
  });

  it('ayudas de formato', () => {
    expect(fechaCorta('2026-11-05')).toBe('5 de noviembre');
    expect(nombreDeTributos(['predial', 'arbitrios'])).toBe('impuesto predial y arbitrios municipales');
    expect(municipalidadCorta('Municipalidad Distrital de Pueblo Libre')).toBe('Pueblo Libre');
    expect(municipalidadCorta('Municipalidad de Lince')).toBe('Lince');
    expect(montoSinMoneda(120.5)).toBe('120.50');
    expect(limpiarVariable('uno\n\ndos    tres')).toBe('uno dos tres');
  });

  it('el mensaje nunca contiene la cuponera ni el DNI, aunque estén en los datos de entrada', async () => {
    // Datos de entrada contaminados: la función solo toma los campos que necesita.
    const sucio = {
      ...candidato({ tipo: 'pendiente', monto: 120.5 }),
      dni: '73126351',
      numero_cuponera: '5817403962',
      codigo_cuponera: '5817403962',
    } as Candidato;
    const { dep, meta } = dependencias();
    await enviarUno(sucio, A_LAS_10, dep);
    await enviarUno({ ...sucio, tipo: 'vencimiento', periodo: 'a' }, A_LAS_10, dep);
    await enviarUno({ ...sucio, tipo: 'pago_confirmado', periodo: 'b', referencia: 'OP-90500' }, A_LAS_10, dep);
    await enviarUno({ ...sucio, tipo: 'bienvenida', periodo: 'c' }, A_LAS_10, dep);
    const todo = JSON.stringify(meta.llamadas);
    expect(meta.llamadas).toHaveLength(4);
    expect(todo).not.toContain('73126351');
    expect(todo).not.toContain('5817403962');
    expect(todo).not.toMatch(/dni|cuponera/i);
  });

  it('si una variable parece un DNI o una cuponera, no sale', async () => {
    expect(variablesSeguras(['Rosa', '120.50', 'Lince'])).toBe(true);
    expect(variablesSeguras(['Rosa', '1,234,567.89', 'OP-90500'])).toBe(true);
    expect(variablesSeguras(['73126351'])).toBe(false);
    expect(variablesSeguras(['Rosa 5817403962'])).toBe(false);
    const { dep, meta, almacen } = dependencias();
    const r = await enviarUno(candidato({ nombre: '73126351' }), A_LAS_10, dep);
    expect(r).toEqual({ estado: 'fallido', motivo: 'dato_sensible' });
    expect(meta.llamadas).toHaveLength(0);
    expect([...almacen.registros.values()][0]).toMatchObject({ estado: 'fallido', error: 'dato_sensible' });
  });
});

describe('enmascarar teléfonos', () => {
  it('deja solo los tres últimos dígitos', () => {
    expect(enmascararTelefono('+51987654321')).toBe('+51 9** *** 321');
    expect(enmascararTelefono('51987654321')).toBe('+51 9** *** 321');
    expect(enmascararTelefono('1234567')).toBe('***567');
    expect(enmascararTelefono(null)).toBe('***');
  });
});

// --- Función enviar-recordatorios: quién puede llamarla ---
function almacenCompleto(datos: DatosBienvenida | null, bienvenidasPrevias = 0) {
  const base = almacenEnMemoria();
  const almacen: AlmacenCompleto = {
    candidatos: async () => [candidato(), candidato({ vecino_id: 'v9', saldo_pendiente: 0 })],
    reclamar: base.reclamar,
    marcar: base.marcar,
    datosBienvenida: async () => datos,
    bienvenidasDesde: async () => bienvenidasPrevias,
  };
  return { almacen, base };
}

const datosBienvenida = (extra: Partial<DatosBienvenida> = {}): DatosBienvenida => ({
  vecino_id: 'v1',
  municipalidad_id: 'm1',
  municipalidad: 'Municipalidad de Lince',
  nombre: 'Rosa',
  numero: '+51987654321',
  whatsapp_activo: true,
  optout_at: null,
  consentimiento_at: '2026-11-12T14:00:00Z',
  ...extra,
});

function manejadorRecordatorios(opciones: { datos?: DatosBienvenida | null; previas?: number; ahora?: Date } = {}) {
  const meta = metaSimulada([OK]);
  const { almacen, base } = almacenCompleto(opciones.datos === undefined ? datosBienvenida() : opciones.datos, opciones.previas);
  const manejador = crearManejadorRecordatorios({
    almacen,
    usuarioDe: async (jwt) => (jwt === 'jwt-de-rosa' ? 'u1' : null),
    fetchMeta: meta.fetchMeta,
    env,
    ahora: () => opciones.ahora ?? A_LAS_10,
    pausa: async () => {},
    log: () => {},
  });
  const llamar = (token: string | null, cuerpo: unknown = {}) =>
    manejador(
      new Request('https://x.test/enviar-recordatorios', {
        method: 'POST',
        headers: token ? { Authorization: `Bearer ${token}` } : {},
        body: JSON.stringify(cuerpo),
      }),
    );
  return { llamar, meta, base };
}

describe('enviar-recordatorios: llamadas', () => {
  it('sin autorización o con un secreto incorrecto, 401 y no envía nada', async () => {
    const { llamar, meta } = manejadorRecordatorios();
    expect((await llamar(null)).status).toBe(401);
    expect((await llamar('otro-secreto')).status).toBe(401);
    expect((await llamar('jwt-ajeno', { accion: 'bienvenida' })).status).toBe(401);
    expect(meta.llamadas).toHaveLength(0);
  });

  it('con el secreto ejecuta los recordatorios del día', async () => {
    const { llamar, meta } = manejadorRecordatorios();
    const r = await llamar('secreto-programado');
    expect(r.status).toBe(200);
    expect(await r.json()).toMatchObject({ candidatos: 2, enviados: 1, omitidos: 1 });
    expect(meta.llamadas).toHaveLength(1);
  });

  it('con el secreto, fuera de horario no envía', async () => {
    const { llamar, meta } = manejadorRecordatorios({ ahora: new Date('2026-11-13T03:00:00Z') });
    expect(await (await llamar('secreto-programado')).json()).toMatchObject({ enviados: 0, fuera_de_horario: true });
    expect(meta.llamadas).toHaveLength(0);
  });

  it('el JWT de un vecino solo sirve para su bienvenida, y va al número que ya guardó', async () => {
    const { llamar, meta } = manejadorRecordatorios();
    // Un vecino no puede disparar la ejecución general.
    expect((await llamar('jwt-de-rosa', {})).status).toBe(401);
    // Ni mandar su propio número o texto: el cuerpo se ignora.
    const r = await llamar('jwt-de-rosa', { accion: 'bienvenida', numero: '+51900000000', texto: 'hola' });
    expect(await r.json()).toEqual({ enviado: true });
    expect(meta.llamadas).toHaveLength(1);
    expect(meta.llamadas[0]!.cuerpo.to).toBe('51987654321');
    expect(meta.llamadas[0]!.cuerpo.template.name).toBe('almira_bienvenida');
  });

  it('la bienvenida sale aunque sea de noche (la pidió la propia persona), pero una sola vez por consentimiento', async () => {
    const { llamar, meta } = manejadorRecordatorios({ ahora: new Date('2026-11-13T03:00:00Z') });
    expect(await (await llamar('jwt-de-rosa', { accion: 'bienvenida' })).json()).toEqual({ enviado: true });
    expect(await (await llamar('jwt-de-rosa', { accion: 'bienvenida' })).json()).toEqual({ enviado: true });
    expect(meta.llamadas).toHaveLength(1);
  });

  it('sin activar, con baja o sin consentimiento, no hay bienvenida', async () => {
    for (const datos of [
      null,
      datosBienvenida({ whatsapp_activo: false }),
      datosBienvenida({ optout_at: '2026-11-12T12:00:00Z' }),
      datosBienvenida({ consentimiento_at: null }),
      datosBienvenida({ numero: null }),
    ]) {
      const { llamar, meta } = manejadorRecordatorios({ datos });
      expect(await (await llamar('jwt-de-rosa', { accion: 'bienvenida' })).json()).toEqual({
        enviado: false,
        motivo: 'sin_activar',
      });
      expect(meta.llamadas).toHaveLength(0);
    }
  });

  it('limita las bienvenidas por día', async () => {
    const { llamar, meta } = manejadorRecordatorios({ previas: 3 });
    const r = await llamar('jwt-de-rosa', { accion: 'bienvenida' });
    expect(r.status).toBe(429);
    expect(meta.llamadas).toHaveLength(0);
  });
});

// --- whatsapp-webhook ---
function webhook() {
  const estados: { id: string; estado: EstadoMensaje; error: string | null }[] = [];
  const bajas: string[] = [];
  const almacen: AlmacenWebhook = {
    actualizarEstado: async (id, estado, error) => {
      estados.push({ id, estado, error });
    },
    darDeBaja: async (numero) => {
      bajas.push(numero);
      return 1;
    },
  };
  const meta = metaSimulada([OK]);
  const manejador = crearManejadorWebhook({
    almacen,
    fetchMeta: meta.fetchMeta,
    env,
    ahora: () => A_LAS_10,
    log: () => {},
  });
  const post = async (cuerpo: unknown, firma?: 'valida' | 'invalida' | 'ausente') => {
    const texto = JSON.stringify(cuerpo);
    const headers: Record<string, string> = {};
    if (firma === 'valida') headers['X-Hub-Signature-256'] = `sha256=${await firmarCuerpo(texto, ENV.WA_APP_SECRET!)}`;
    if (firma === 'invalida') headers['X-Hub-Signature-256'] = `sha256=${await firmarCuerpo(texto, 'otro-secreto')}`;
    return manejador(new Request('https://x.test/whatsapp-webhook', { method: 'POST', headers, body: texto }));
  };
  return { post, estados, bajas, meta, manejador };
}

const mensajeDe = (texto: string) => ({
  entry: [{ changes: [{ value: { messages: [{ from: '51987654321', type: 'text', text: { body: texto } }] } }] }],
});

describe('whatsapp-webhook', () => {
  it('GET: verifica el token y devuelve el desafío', async () => {
    const { manejador } = webhook();
    const bueno = await manejador(
      new Request('https://x.test/w?hub.mode=subscribe&hub.verify_token=verificacion&hub.challenge=12345'),
    );
    expect(bueno.status).toBe(200);
    expect(await bueno.text()).toBe('12345');
    const malo = await manejador(
      new Request('https://x.test/w?hub.mode=subscribe&hub.verify_token=otro&hub.challenge=12345'),
    );
    expect(malo.status).toBe(403);
  });

  it('rechaza una firma inválida o ausente y no toca nada', async () => {
    const { post, estados, bajas, meta } = webhook();
    const cuerpo = mensajeDe('BAJA');
    expect((await post(cuerpo, 'invalida')).status).toBe(401);
    expect((await post(cuerpo, 'ausente')).status).toBe(401);
    expect(estados).toHaveLength(0);
    expect(bajas).toHaveLength(0);
    expect(meta.llamadas).toHaveLength(0);
  });

  it('la firma depende del cuerpo exacto', async () => {
    const firma = `sha256=${await firmarCuerpo('{"a":1}', 'secreto')}`;
    expect(await firmaValida('{"a":1}', firma, 'secreto')).toBe(true);
    expect(await firmaValida('{"a":2}', firma, 'secreto')).toBe(false);
    expect(await firmaValida('{"a":1}', firma, undefined)).toBe(false);
    expect(await firmaValida('{"a":1}', 'sha256=zzzz', 'secreto')).toBe(false);
    expect(await firmaValida('{"a":1}', firma.replace('sha256=', ''), 'secreto')).toBe(false);
  });

  it('actualiza los estados de los mensajes', async () => {
    const { post, estados } = webhook();
    const r = await post(
      {
        entry: [
          {
            changes: [
              {
                value: {
                  statuses: [
                    { id: 'wamid.1', status: 'sent' },
                    { id: 'wamid.1', status: 'delivered' },
                    { id: 'wamid.1', status: 'read' },
                    { id: 'wamid.2', status: 'failed', errors: [{ code: 131026 }] },
                    { id: 'wamid.3', status: 'desconocido' },
                  ],
                },
              },
            ],
          },
        ],
      },
      'valida',
    );
    expect(r.status).toBe(200);
    expect(estados).toEqual([
      { id: 'wamid.1', estado: 'enviado', error: null },
      { id: 'wamid.1', estado: 'entregado', error: null },
      { id: 'wamid.1', estado: 'leido', error: null },
      { id: 'wamid.2', estado: 'fallido', error: 'meta_131026' },
    ]);
  });

  it.each(['BAJA', 'baja', 'Stop', 'STOP', 'no', 'NO', ' Baja. '])('"%s" da de baja y confirma con amabilidad', async (texto) => {
    const { post, bajas, meta } = webhook();
    expect((await post(mensajeDe(texto), 'valida')).status).toBe(200);
    expect(bajas).toEqual(['+51987654321']);
    expect(meta.llamadas).toHaveLength(1);
    expect(meta.llamadas[0]!.cuerpo.type).toBe('text');
    expect(meta.llamadas[0]!.cuerpo.text.body).toBe(MENSAJE_BAJA);
    expect(meta.llamadas[0]!.cuerpo.to).toBe('51987654321');
  });

  it('cualquier otro mensaje recibe una respuesta breve y no da de baja', async () => {
    const { post, bajas, meta } = webhook();
    await post(mensajeDe('¿Cuánto debo?'), 'valida');
    await post(mensajeDe('no gracias, ya pagué'), 'valida');
    expect(bajas).toHaveLength(0);
    expect(meta.llamadas.map((l) => l.cuerpo.text.body)).toEqual([MENSAJE_GENERAL, MENSAJE_GENERAL]);
    expect(MENSAJE_GENERAL).toContain('asistente de la app');
  });

  it('esBaja solo acepta las tres palabras', () => {
    expect(['baja', 'stop', 'no', 'BAJA!', 'Stop.'].map(esBaja)).toEqual([true, true, true, true, true]);
    expect(['bajar', 'nota', 'hola', '', null, 42].map(esBaja)).toEqual([false, false, false, false, false, false]);
  });

  it('un cuerpo que no es JSON, aun bien firmado, es 400', async () => {
    const { manejador } = webhook();
    const texto = 'no es json';
    const r = await manejador(
      new Request('https://x.test/w', {
        method: 'POST',
        headers: { 'X-Hub-Signature-256': `sha256=${await firmarCuerpo(texto, ENV.WA_APP_SECRET!)}` },
        body: texto,
      }),
    );
    expect(r.status).toBe(400);
  });
});

// --- La migración ---
describe('migración de recordatorios por WhatsApp', () => {
  const sql = migracionSql;
  const sinComentarios = sql.replace(/--[^\n]*/g, '');

  it('las tablas nuevas no guardan DNI ni número de cuponera', () => {
    const tablas = sinComentarios.match(/create table public\.\w+ \([\s\S]*?\n\);/g) ?? [];
    expect(tablas).toHaveLength(2);
    for (const t of tablas) expect(t).not.toMatch(/dni|cuponera/i);
  });

  it('la selección de candidatos no lee DNI ni cuponera', () => {
    const funcion = sinComentarios.slice(sinComentarios.indexOf('create function public.recordatorios_candidatos'));
    expect(funcion).not.toMatch(/\bdni\b|cuponera/i);
  });

  it('las dos tablas llevan municipalidad_id, RLS y sin permisos para anon', () => {
    for (const tabla of ['preferencias_notificacion', 'recordatorios_enviados']) {
      expect(sinComentarios).toMatch(new RegExp(`alter table public\\.${tabla} enable row level security`));
      expect(sinComentarios).toMatch(new RegExp(`revoke all on public\\.${tabla} from anon, authenticated`));
    }
    expect(sinComentarios.match(/municipalidad_id uuid not null/g)?.length).toBeGreaterThanOrEqual(2);
    expect(sinComentarios).toMatch(/unique \(contribuyente_id, tipo, periodo\)/);
    expect(sinComentarios).toMatch(/unique \(contribuyente_id\)/);
  });

  it('el cliente no puede escribir en ninguna de las dos tablas', () => {
    expect(sinComentarios).not.toMatch(/grant (insert|update|delete)[^;]*on public\.(preferencias_notificacion|recordatorios_enviados)/i);
  });

  it('la selección de candidatos solo la ejecuta service_role', () => {
    expect(sinComentarios).toMatch(
      /revoke all on function public\.recordatorios_candidatos\(timestamptz\) from public, anon, authenticated/,
    );
    expect(sinComentarios).toMatch(/grant execute on function public\.recordatorios_candidatos\(timestamptz\) to service_role/);
  });
});
