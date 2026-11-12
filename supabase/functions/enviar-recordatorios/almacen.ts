// Acceso a la base para `enviar-recordatorios`, con el cliente de service_role. Es la única pieza
// que habla con Supabase; el resto de la función se prueba sin ella.
import type { Candidato, Marca, RegistroNuevo } from './logica.ts';
import type { AlmacenCompleto, DatosBienvenida } from './manejador.ts';

// Lo mínimo que se usa del cliente de supabase-js.
// deno-lint-ignore no-explicit-any
type Cliente = any;

const LEER = (error: unknown) => {
  if (error) throw new Error('lectura');
};

export function crearAlmacen(admin: Cliente): AlmacenCompleto {
  return {
    async candidatos(ahora: Date): Promise<Candidato[]> {
      const { data, error } = await admin.rpc('recordatorios_candidatos', { p_ahora: ahora.toISOString() });
      LEER(error);
      return (data ?? []) as Candidato[];
    },

    async reclamar(r: RegistroNuevo): Promise<boolean> {
      // La restricción única (contribuyente, tipo, periodo) hace el envío idempotente: si ya hay
      // un registro, no se inserta nada y no se manda otro mensaje.
      const { data, error } = await admin
        .from('recordatorios_enviados')
        .upsert(
          {
            municipalidad_id: r.municipalidad_id,
            contribuyente_id: r.vecino_id,
            tipo: r.tipo,
            periodo: r.periodo,
            plantilla: r.plantilla,
            estado: 'en_cola',
          },
          { onConflict: 'contribuyente_id,tipo,periodo', ignoreDuplicates: true },
        )
        .select('id');
      LEER(error);
      return Array.isArray(data) && data.length > 0;
    },

    async marcar(m: Marca): Promise<void> {
      const { error } = await admin
        .from('recordatorios_enviados')
        .update({
          estado: m.estado,
          wa_message_id: m.wa_message_id ?? null,
          error_resumen: m.error_resumen ?? null,
          actualizado_at: new Date().toISOString(),
        })
        .eq('contribuyente_id', m.vecino_id)
        .eq('tipo', m.tipo)
        .eq('periodo', m.periodo);
      LEER(error);
    },

    async datosBienvenida(userId: string): Promise<DatosBienvenida | null> {
      const { data: vecinos, error } = await admin
        .from('vecinos')
        .select('id, municipalidad_id, nombre, nombres')
        .eq('user_id', userId)
        .order('creado_en', { ascending: true })
        .limit(1);
      LEER(error);
      const vecino = vecinos?.[0];
      if (!vecino) return null;

      const { data: prefs, error: errorPref } = await admin
        .from('preferencias_notificacion')
        .select('whatsapp_activo, whatsapp_numero, consentimiento_at, optout_at')
        .eq('contribuyente_id', vecino.id)
        .limit(1);
      LEER(errorPref);
      const pref = prefs?.[0];
      if (!pref) return null;

      const { data: municipalidades, error: errorMuni } = await admin
        .from('municipalidades')
        .select('nombre')
        .eq('id', vecino.municipalidad_id)
        .limit(1);
      LEER(errorMuni);

      const primerNombre = String(vecino.nombres || vecino.nombre || '').trim().split(/\s+/)[0] || 'vecino';
      return {
        vecino_id: vecino.id,
        municipalidad_id: vecino.municipalidad_id,
        municipalidad: municipalidades?.[0]?.nombre ?? 'tu municipalidad',
        nombre: primerNombre,
        numero: pref.whatsapp_numero,
        whatsapp_activo: pref.whatsapp_activo,
        optout_at: pref.optout_at,
        consentimiento_at: pref.consentimiento_at,
      };
    },

    async bienvenidasDesde(vecinoId: string, desde: Date): Promise<number> {
      const { count, error } = await admin
        .from('recordatorios_enviados')
        .select('id', { count: 'exact', head: true })
        .eq('contribuyente_id', vecinoId)
        .eq('tipo', 'bienvenida')
        .gte('creado_at', desde.toISOString());
      LEER(error);
      return count ?? 0;
    },
  };
}
