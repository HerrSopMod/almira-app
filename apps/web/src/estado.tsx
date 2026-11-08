import {
  HOY_EJEMPLO,
  municipalidades,
  obras as obrasEjemplo,
  panelEjemplo,
  plazoReclamo,
  reclamos as reclamosEjemplo,
  type CasoAtencion,
  type Municipalidad,
  type Obra,
  type PanelEjemplo,
  type Reclamo,
} from '@almira/shared';
import { createContext, useContext, useState, type ReactNode } from 'react';

// Todo vive en memoria: no hay autenticación real ni se guarda nada. Al
// recargar la página el panel vuelve a los datos de ejemplo.

export type Sesion = {
  municipalidad: Municipalidad;
  panel: PanelEjemplo;
  usuario: string;
};

type DatosSesion = {
  reclamos: Reclamo[];
  obras: Obra[];
  casos: CasoAtencion[];
  // Variante de la prueba A/B elegida para el próximo ciclo (web-04).
  varianteElegida: string | null;
  // Interruptor del simulador de cuotas en Alertas y auditoría (web-08).
  simuladorActivo: boolean;
};

type ContextoPanel = {
  sesion: Sesion | null;
  datos: DatosSesion;
  ingresar: (municipalidadId: string, usuario: string) => void;
  cambiarDatos: (cambio: (datos: DatosSesion) => DatosSesion) => void;
};

const Contexto = createContext<ContextoPanel | null>(null);

// Solo se puede entrar a municipalidades que tienen cifras de ejemplo para el panel.
export const municipalidadesConPanel = municipalidades.filter(
  (municipalidad) => municipalidad.activa && panelEjemplo(municipalidad.id),
);

const SIN_DATOS: DatosSesion = {
  reclamos: [],
  obras: [],
  casos: [],
  varianteElegida: null,
  simuladorActivo: true,
};

export function ProveedorPanel({ children }: { children: ReactNode }) {
  const [sesion, setSesion] = useState<Sesion | null>(null);
  const [datos, setDatos] = useState<DatosSesion>(SIN_DATOS);

  const ingresar = (municipalidadId: string, usuario: string) => {
    const municipalidad = municipalidadesConPanel.find((m) => m.id === municipalidadId);
    const panel = panelEjemplo(municipalidadId);
    if (!municipalidad || !panel) return;
    // El personal solo ve su municipalidad; en Supabase lo garantiza RLS.
    setDatos({
      reclamos: reclamosEjemplo.filter((r) => r.municipalidadId === municipalidadId),
      obras: obrasEjemplo.filter((o) => o.municipalidadId === municipalidadId),
      casos: panel.casos.map((caso) => ({ ...caso })),
      varianteElegida: null,
      simuladorActivo: true,
    });
    setSesion({ municipalidad, panel, usuario });
  };

  return (
    <Contexto.Provider value={{ sesion, datos, ingresar, cambiarDatos: setDatos }}>
      {children}
    </Contexto.Provider>
  );
}

export function usePanel() {
  const contexto = useContext(Contexto);
  if (!contexto) throw new Error('usePanel va dentro de ProveedorPanel');
  return contexto;
}

// Para las páginas internas, que solo se muestran con sesión.
export function useSesion() {
  const { sesion, ...resto } = usePanel();
  if (!sesion) throw new Error('useSesion necesita una sesión iniciada');
  return { sesion, ...resto };
}

// "Vencido 2 d", "Quedan 3 d" o "Resuelto", contado desde el hoy del prototipo.
export function etiquetaPlazoReclamo(reclamo: Reclamo): string {
  return plazoReclamo(reclamo, HOY_EJEMPLO)?.etiqueta ?? 'Resuelto';
}

export function estaVencido(reclamo: Reclamo): boolean {
  return etiquetaPlazoReclamo(reclamo).startsWith('Vencido');
}

// Obras con más días sin actualizar que la frecuencia acordada.
export function diasSinActualizar(obra: Obra): number {
  const desde = Date.parse(`${obra.actualizadaEn.slice(0, 10)}T00:00:00Z`);
  const hoy = Date.parse(`${HOY_EJEMPLO}T00:00:00Z`);
  return Math.round((hoy - desde) / 86_400_000);
}

// Cifras de la barra lateral: reclamos vencidos, casos en cola y alertas activas.
export function pendientes({ datos, sesion }: { datos: DatosSesion; sesion: Sesion }) {
  return {
    reclamosVencidos: datos.reclamos.filter(estaVencido),
    casosEnCola: datos.casos.filter((caso) => caso.estado === 'en_cola'),
    alertas: sesion.panel.alertasActivas,
  };
}
