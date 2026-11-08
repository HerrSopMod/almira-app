import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';

// "Texto más grande" de Mi perfil (pantalla 21). Vive aparte de la sesión para
// que Texto no se vuelva a dibujar con cada cambio de la sesión. Solo en memoria.
type TextoGrande = { activo: boolean; cambiar: (activo: boolean) => void };

const ContextoTextoGrande = createContext<TextoGrande>({ activo: false, cambiar: () => {} });

export function TextoGrandeProvider({ children }: { children: ReactNode }) {
  const [activo, cambiar] = useState(false);
  const valor = useMemo(() => ({ activo, cambiar }), [activo]);
  return <ContextoTextoGrande.Provider value={valor}>{children}</ContextoTextoGrande.Provider>;
}

export function useTextoGrande() {
  return useContext(ContextoTextoGrande);
}
