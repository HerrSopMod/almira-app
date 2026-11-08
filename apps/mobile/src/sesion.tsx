import {
  deudas,
  municipalidades,
  obras,
  predios,
  reclamos as reclamosEjemplo,
  recordatorios,
  USUARIO_EJEMPLO,
  vecinos,
  type Reclamo,
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
  reclamosNuevos: Reclamo[];
  agregarReclamo: (reclamo: Reclamo) => void;
};

const ContextoSesion = createContext<Sesion | null>(null);

export function SesionProvider({ children }: { children: ReactNode }) {
  const [municipalidadId, elegirMunicipalidad] = useState(municipalidades[0]!.id);
  const [reclamosNuevos, setReclamosNuevos] = useState<Reclamo[]>([]);
  const [consentimientos, guardarConsentimientos] = useState<Consentimientos>({
    asistenteIa: true,
    avisosWhatsapp: true,
    avisosSms: true,
  });
  const valor = useMemo(
    () => ({
      municipalidadId,
      elegirMunicipalidad,
      consentimientos,
      guardarConsentimientos,
      reclamosNuevos,
      agregarReclamo: (reclamo: Reclamo) => setReclamosNuevos((previos) => [reclamo, ...previos]),
    }),
    [municipalidadId, reclamosNuevos, consentimientos],
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
  const { municipalidadId, reclamosNuevos } = useSesion();
  return useMemo(() => {
    const municipalidad = municipalidades.find((m) => m.id === municipalidadId)!;
    const vecino = vecinos.find(
      (v) => v.municipalidadId === municipalidadId && v.userId === USUARIO_EJEMPLO.id,
    );
    const delVecino = <T extends { vecinoId: string }>(filas: T[]) =>
      filas.filter((fila) => fila.vecinoId === vecino?.id);
    return {
      municipalidad,
      vecino,
      predios: delVecino(predios),
      deudas: delVecino(deudas),
      recordatorios: delVecino(recordatorios),
      reclamos: [
        ...reclamosNuevos.filter((r) => r.municipalidadId === municipalidadId),
        ...delVecino(reclamosEjemplo),
      ],
      obras: obras.filter((o) => o.municipalidadId === municipalidadId && o.publicada),
    };
  }, [municipalidadId, reclamosNuevos]);
}

export function municipalidadesDelVecino() {
  const propias = vecinos.filter((v) => v.userId === USUARIO_EJEMPLO.id);
  return propias.map((vecino) => ({
    municipalidad: municipalidades.find((m) => m.id === vecino.municipalidadId)!,
    cantidadPredios: predios.filter((p) => p.vecinoId === vecino.id).length,
  }));
}
