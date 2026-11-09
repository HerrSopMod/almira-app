import {
  deudas,
  HOY_EJEMPLO,
  municipalidades,
  buscarVecinoPorCodigo,
  obras,
  pagos,
  predios,
  reclamos as reclamosEjemplo,
  recordatorios,
  alternarCanal,
  AREA_TIPO_RECLAMO,
  PLAZO_DIAS_RECLAMO,
  siguienteCodigoReclamo,
  UBICACIONES_PREDIO_EJEMPLO,
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
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import {
  leerDatosIngreso,
  metodoDeSesion,
  nombreDeSesion,
  useAuth,
  type DatosIngreso,
  type Vinculo,
  type MetodoIngreso,
} from './auth';
import { supabaseConfigurado } from './supabase';

// Lo que el vecino autoriza en la pantalla 03 (Tus datos, tus reglas).
export type Consentimientos = {
  asistenteIa: boolean;
  avisosWhatsapp: boolean;
  avisosSms: boolean;
};

export type { MetodoIngreso };

// Como en la maqueta 03: el SMS, canal alterno, empieza apagado.
const CONSENTIMIENTOS_INICIALES: Consentimientos = {
  asistenteIa: true,
  avisosWhatsapp: true,
  avisosSms: false,
};

// Con Supabase, el método, el nombre y lo aceptado salen de la cuenta; sin Supabase, el
// ingreso es simulado y todo vive en memoria. Los datos que se ven siguen siendo de ejemplo.
type Sesion = {
  // null hasta que el vecino se autentica.
  metodoIngreso: MetodoIngreso | null;
  // Nombre de la cuenta de Google, para saludar en Vincula tu DNI.
  nombreCuenta: string | null;
  // Ingreso simulado, solo cuando Supabase no está configurado.
  ingresarSimulado: (metodo: MetodoIngreso) => void;
  // true cuando ya aceptó el consentimiento (pantalla 03): recién ahí entra a Inicio.
  consentimientoAceptado: boolean;
  aceptarConsentimientos: (consentimientos: Consentimientos) => void;
  cerrarSesion: () => Promise<void>;
  // Códigos de contribuyente vinculados (pantalla 02c). Hace falta al menos uno para seguir.
  vinculos: Vinculo[];
  // Devuelve un mensaje de error, o null si quedó vinculado.
  vincularCodigo: (codigo: string, dni: string) => Promise<string | null>;
  // Celular confirmado con código SMS (pantalla 02e), requisito de los avisos por WhatsApp.
  celularConfirmado: boolean;
  confirmarCelular: () => void;
  municipalidadId: string;
  elegirMunicipalidad: (id: string) => void;
  consentimientos: Consentimientos;
  // Cambia los permisos desde Privacidad y mis datos.
  guardarConsentimientos: (consentimientos: Consentimientos) => void;
  // Canales de aviso prendidos en Recordatorios, por municipalidad. Sin elección,
  // solo el canal preferido del vecino. Siempre queda al menos uno.
  canalesAviso: Record<string, CanalAviso[]>;
  alternarCanalAviso: (canal: CanalAviso) => void;
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

// Canal preferido del vecino en esa municipalidad, o WhatsApp si no está registrado.
function canalInicial(municipalidadId: string): CanalAviso {
  const vecino = vecinos.find(
    (v) => v.municipalidadId === municipalidadId && v.userId === USUARIO_EJEMPLO.id,
  );
  return vecino?.canalPreferido ?? 'whatsapp';
}

// La municipalidad guardada, si sigue activa; si no, la primera de los datos.
function municipalidadValida(id: string | null | undefined): string {
  return municipalidades.find((m) => m.id === id && m.activa)?.id ?? municipalidades[0]!.id;
}

export function SesionProvider({ children }: { children: ReactNode }) {
  const auth = useAuth();
  const cuenta = supabaseConfigurado ? auth.sesion : null;
  const guardado = useMemo(() => leerDatosIngreso(cuenta), [cuenta]);
  // Lo elegido en esta sesión manda sobre lo guardado en la cuenta.
  const [metodoSimulado, setMetodoSimulado] = useState<MetodoIngreso | null>(null);
  const [aceptadoAhora, setAceptadoAhora] = useState(false);
  const [municipalidadElegida, setMunicipalidadElegida] = useState<string | null>(null);
  const [consentimientosElegidos, setConsentimientosElegidos] = useState<Consentimientos | null>(
    null,
  );
  const [vinculosSesion, setVinculosSesion] = useState<Vinculo[]>([]);
  const [vinculosCuenta, setVinculosCuenta] = useState<Vinculo[]>([]);
  const [celularAhora, setCelularAhora] = useState(false);
  const [canalesAviso, setCanalesAviso] = useState<Record<string, CanalAviso[]>>({});
  const [reclamosNuevos, setReclamosNuevos] = useState<Reclamo[]>([]);
  const [pagosSimulados, setPagosSimulados] = useState<Pago[]>([]);

  // Si entra otra cuenta, no hereda lo elegido por la anterior.
  const usuarioId = cuenta?.user.id ?? null;
  useEffect(() => {
    setAceptadoAhora(false);
    setMunicipalidadElegida(null);
    setConsentimientosElegidos(null);
    setVinculosSesion([]);
    setCelularAhora(false);
  }, [usuarioId]);

  // Con Supabase, los códigos ya vinculados vuelven desde el servidor.
  const { listarVinculos } = auth;
  useEffect(() => {
    if (!usuarioId) return setVinculosCuenta([]);
    void listarVinculos().then(setVinculosCuenta);
  }, [usuarioId, listarVinculos]);

  const metodoIngreso = cuenta ? metodoDeSesion(cuenta) : metodoSimulado;
  const nombreCuenta = cuenta
    ? nombreDeSesion(cuenta)
    : metodoSimulado === 'google'
      ? USUARIO_EJEMPLO.nombre
      : null;
  const consentimientoAceptado = aceptadoAhora || guardado !== null;
  const municipalidadId = municipalidadValida(municipalidadElegida ?? guardado?.municipalidadId);
  const consentimientos =
    consentimientosElegidos ?? guardado?.consentimientos ?? CONSENTIMIENTOS_INICIALES;
  const { guardarDatosIngreso, cerrarSesion: cerrarSesionAuth, vincularContribuyente } = auth;
  const vinculos = useMemo(
    () =>
      [...vinculosCuenta, ...vinculosSesion].filter(
        (v, i, todos) =>
          todos.findIndex((o) => o.municipalidadId === v.municipalidadId && o.codigo === v.codigo) === i,
      ),
    [vinculosCuenta, vinculosSesion],
  );
  // El celular del ingreso por SMS ya viene confirmado.
  const celularConfirmado = celularAhora || metodoIngreso === 'celular' || guardado?.celularConfirmado === true;

  const valor = useMemo<Sesion>(() => {
    const guardar = (cambios: Partial<DatosIngreso>) =>
      void guardarDatosIngreso({
        municipalidadId,
        consentimientos,
        consentimientoAceptadoEn: guardado?.consentimientoAceptadoEn ?? new Date().toISOString(),
        celularConfirmado,
        ...cambios,
      });
    return {
      metodoIngreso,
      nombreCuenta,
      ingresarSimulado: setMetodoSimulado,
      consentimientoAceptado,
      aceptarConsentimientos: (elegidos) => {
        setConsentimientosElegidos(elegidos);
        setAceptadoAhora(true);
        guardar({ consentimientos: elegidos, consentimientoAceptadoEn: new Date().toISOString() });
      },
      cerrarSesion: async () => {
        await cerrarSesionAuth();
        setMetodoSimulado(null);
        setVinculosSesion([]);
        setCelularAhora(false);
        setAceptadoAhora(false);
        setMunicipalidadElegida(null);
        setConsentimientosElegidos(null);
      },
      vinculos,
      vincularCodigo: async (codigo, dni) => {
        const nuevo = { municipalidadId, codigo: codigo.trim().toUpperCase() };
        if (supabaseConfigurado) {
          const error = await vincularContribuyente(municipalidadId, codigo, dni);
          if (error) return error;
        } else if (!buscarVecinoPorCodigo(vecinos, predios, municipalidadId, codigo, dni)) {
          return 'No encontramos ese código con ese DNI en el padrón.';
        }
        setVinculosSesion((previos) => [...previos, nuevo]);
        return null;
      },
      celularConfirmado,
      confirmarCelular: () => setCelularAhora(true),
      municipalidadId,
      elegirMunicipalidad: (id) => {
        setMunicipalidadElegida(id);
        if (consentimientoAceptado) guardar({ municipalidadId: id });
      },
      consentimientos,
      guardarConsentimientos: (elegidos) => {
        setConsentimientosElegidos(elegidos);
        if (consentimientoAceptado) guardar({ consentimientos: elegidos });
      },
      canalesAviso,
      alternarCanalAviso: (canal) =>
        setCanalesAviso((previos) => ({
          ...previos,
          [municipalidadId]: alternarCanal(
            previos[municipalidadId] ?? [canalInicial(municipalidadId)],
            canal,
          ),
        })),
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
        // La foto y el punto del GPS de Nuevo reclamo no llegan aquí: no se sube ningún
        // archivo. El punto guardado es el de ejemplo del predio; si el vecino cambió la
        // dirección, no hay punto.
        const predio = predios.find(
          (p) => p.vecinoId === vecino.id && p.direccion === direccion,
        );
        const punto = predio ? UBICACIONES_PREDIO_EJEMPLO[predio.id] : undefined;
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
          latitud: punto?.latitud ?? null,
          longitud: punto?.longitud ?? null,
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
    };
  }, [
    metodoIngreso,
    nombreCuenta,
    vinculos,
    vincularContribuyente,
    celularConfirmado,
    consentimientoAceptado,
    guardado,
    guardarDatosIngreso,
    cerrarSesionAuth,
    municipalidadId,
    canalesAviso,
    reclamosNuevos,
    consentimientos,
    pagosSimulados,
  ]);
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
      canalesAviso: canalesAviso[municipalidadId] ?? [canalInicial(municipalidadId)],
      reclamos: [
        ...reclamosNuevos.filter((r) => r.municipalidadId === municipalidadId),
        ...delVecino(reclamosEjemplo),
      ],
      obras: obras.filter((o) => o.municipalidadId === municipalidadId && o.publicada),
    };
  }, [municipalidadId, canalesAviso, reclamosNuevos, pagosSimulados]);
}

// DNI de ejemplo de Rosa: llena el campo del ingreso para recorrer el prototipo.
export const DOCUMENTO_EJEMPLO =
  vecinos.find((vecino) => vecino.userId === USUARIO_EJEMPLO.id)?.dni ?? '';

export function municipalidadesDelVecino() {
  const propias = vecinos.filter((v) => v.userId === USUARIO_EJEMPLO.id);
  return propias.map((vecino) => ({
    municipalidad: municipalidades.find((m) => m.id === vecino.municipalidadId)!,
    cantidadPredios: predios.filter((p) => p.vecinoId === vecino.id).length,
  }));
}
