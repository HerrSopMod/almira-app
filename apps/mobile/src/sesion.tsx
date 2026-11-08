import {
  deudas,
  HOY_EJEMPLO,
  municipalidades,
  obras,
  pagos,
  predios,
  reclamos as reclamosEjemplo,
  recordatorios,
  AREA_TIPO_RECLAMO,
  PLAZO_DIAS_RECLAMO,
  siguienteCodigoReclamo,
  tituloReclamo,
  totalDeuda,
  USUARIO_EJEMPLO,
  vecinos,
  type CanalAviso,
  type Deuda,
  type MedioPago,
  type Pago,
  type Reclamo,
  type TipoReclamo,
} from '@almira/shared';
import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';

// Lo que el vecino autoriza en la pantalla 03 (Tus datos, tus reglas).
export type Consentimientos = {
  asistenteIa: boolean;
  avisosWhatsapp: boolean;
  avisosSms: boolean;
};

// Estado en memoria con datos de ejemplo; todavía no hay conexión a Supabase.
type Sesion = {
  municipalidadId: string;
  elegirMunicipalidad: (id: string) => void;
  consentimientos: Consentimientos;
  guardarConsentimientos: (consentimientos: Consentimientos) => void;
  // Canal de aviso elegido en Recordatorios, por municipalidad. Sin elección, vale
  // el canal preferido del vecino.
  canalesAviso: Record<string, CanalAviso>;
  elegirCanalAviso: (canal: CanalAviso) => void;
  reclamosNuevos: Reclamo[];
  // Guarda en memoria un reclamo de la municipalidad elegida y devuelve su id.
  registrarReclamo: (datos: NuevoReclamo) => string | null;
  pagosSimulados: Pago[];
  // Devuelve el código de operación que comparten los pagos creados.
  registrarPagoSimulado: (deudasAPagar: Deuda[], medio: MedioPago) => string;
};

export type NuevoReclamo = {
  tipo: TipoReclamo;
  descripcion: string;
  direccion: string;
};

const ContextoSesion = createContext<Sesion | null>(null);

// La primera operación simulada coincide con la constancia del prototipo (OP-90412).
const PRIMERA_OPERACION = 90412;

// Fecha del "hoy" de ejemplo con la hora local del teléfono.
function momentoSimulado(): string {
  const ahora = new Date();
  const hora = String(ahora.getHours()).padStart(2, '0');
  const minutos = String(ahora.getMinutes()).padStart(2, '0');
  return `${HOY_EJEMPLO}T${hora}:${minutos}:00`;
}

export function SesionProvider({ children }: { children: ReactNode }) {
  const [municipalidadId, elegirMunicipalidad] = useState(municipalidades[0]!.id);
  const [canalesAviso, setCanalesAviso] = useState<Record<string, CanalAviso>>({});
  const [reclamosNuevos, setReclamosNuevos] = useState<Reclamo[]>([]);
  const [pagosSimulados, setPagosSimulados] = useState<Pago[]>([]);
  const [consentimientos, guardarConsentimientos] = useState<Consentimientos>({
    asistenteIa: true,
    avisosWhatsapp: true,
    avisosSms: true,
  });
  const valor = useMemo<Sesion>(
    () => ({
      municipalidadId,
      elegirMunicipalidad,
      consentimientos,
      guardarConsentimientos,
      canalesAviso,
      elegirCanalAviso: (canal) =>
        setCanalesAviso((previos) => ({ ...previos, [municipalidadId]: canal })),
      reclamosNuevos,
      registrarReclamo: ({ tipo, descripcion, direccion }) => {
        const vecino = vecinos.find(
          (v) => v.municipalidadId === municipalidadId && v.userId === USUARIO_EJEMPLO.id,
        );
        if (!vecino) return null;
        const codigo = siguienteCodigoReclamo(
          [...reclamosEjemplo, ...reclamosNuevos].filter(
            (r) => r.municipalidadId === municipalidadId,
          ),
        );
        // La foto y la ubicación son simuladas: no se sube ningún archivo ni se lee el GPS.
        const reclamo: Reclamo = {
          id: `nuevo-${municipalidadId}-${codigo}`,
          municipalidadId,
          vecinoId: vecino.id,
          codigo,
          tipo,
          titulo: tituloReclamo(descripcion),
          descripcion,
          estado: 'derivado',
          area: AREA_TIPO_RECLAMO[tipo],
          fotoRuta: `${municipalidadId}/simulada-${codigo}.jpg`,
          direccion,
          latitud: null,
          longitud: null,
          plazo: null,
          plazoDias: PLAZO_DIAS_RECLAMO,
          creadoEn: HOY_EJEMPLO,
        };
        setReclamosNuevos((previos) => [reclamo, ...previos]);
        return reclamo.id;
      },
      pagosSimulados,
      registrarPagoSimulado: (deudasAPagar, medio) => {
        const operaciones = new Set(pagosSimulados.map((pago) => pago.referencia));
        const referencia = `OP-${PRIMERA_OPERACION + operaciones.size}`;
        const creadoEn = momentoSimulado();
        // Pago simulado: queda "pendiente" porque solo el servidor confirma pagos.
        const nuevos: Pago[] = deudasAPagar.map((deuda) => ({
          id: `simulado-${referencia}-${deuda.id}`,
          municipalidadId: deuda.municipalidadId,
          vecinoId: deuda.vecinoId,
          deudaId: deuda.id,
          monto: totalDeuda(deuda),
          medio,
          estado: 'pendiente',
          referencia,
          creadoEn,
        }));
        setPagosSimulados((previos) => [...nuevos, ...previos]);
        return referencia;
      },
    }),
    [municipalidadId, canalesAviso, reclamosNuevos, consentimientos, pagosSimulados],
  );
  return <ContextoSesion.Provider value={valor}>{children}</ContextoSesion.Provider>;
}

export function useSesion() {
  const sesion = useContext(ContextoSesion);
  if (!sesion) throw new Error('useSesion debe usarse dentro de SesionProvider');
  return sesion;
}

// Todo lo que el vecino ve pertenece a la municipalidad elegida.
export function useDatosMunicipales() {
  const { municipalidadId, canalesAviso, reclamosNuevos, pagosSimulados } = useSesion();
  return useMemo(() => {
    const municipalidad = municipalidades.find((m) => m.id === municipalidadId)!;
    const vecino = vecinos.find(
      (v) => v.municipalidadId === municipalidadId && v.userId === USUARIO_EJEMPLO.id,
    );
    const delVecino = <T extends { vecinoId: string }>(filas: T[]) =>
      filas.filter((fila) => fila.vecinoId === vecino?.id);
    const simulados = delVecino(pagosSimulados);
    // Las deudas pagadas en esta sesión se ven como pagadas hasta cerrar la app.
    const pagadasEnSesion = new Set(simulados.map((pago) => pago.deudaId));
    return {
      municipalidad,
      vecino,
      predios: delVecino(predios),
      deudas: delVecino(deudas).map((deuda) =>
        pagadasEnSesion.has(deuda.id) ? { ...deuda, estado: 'pagada' as const } : deuda,
      ),
      pagos: [...simulados, ...delVecino(pagos)].sort((a, b) =>
        b.creadoEn.localeCompare(a.creadoEn),
      ),
      recordatorios: delVecino(recordatorios),
      canalAviso: canalesAviso[municipalidadId] ?? vecino?.canalPreferido ?? 'whatsapp',
      reclamos: [
        ...reclamosNuevos.filter((r) => r.municipalidadId === municipalidadId),
        ...delVecino(reclamosEjemplo),
      ],
      obras: obras.filter((o) => o.municipalidadId === municipalidadId && o.publicada),
    };
  }, [municipalidadId, canalesAviso, reclamosNuevos, pagosSimulados]);
}

export function municipalidadesDelVecino() {
  const propias = vecinos.filter((v) => v.userId === USUARIO_EJEMPLO.id);
  return propias.map((vecino) => ({
    municipalidad: municipalidades.find((m) => m.id === vecino.municipalidadId)!,
    cantidadPredios: predios.filter((p) => p.vecinoId === vecino.id).length,
  }));
}
