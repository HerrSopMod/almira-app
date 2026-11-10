import type { Session } from '@supabase/supabase-js';
import * as Linking from 'expo-linking';
import * as WebBrowser from 'expo-web-browser';
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { Platform } from 'react-native';
import { supabase, supabaseConfigurado } from './supabase';

WebBrowser.maybeCompleteAuthSession();

export type ResultadoVinculo = { ok: boolean; mensaje: string };

type Autenticacion = {
  sesion: Session | null;
  cargando: boolean;
  iniciarConGoogle: () => Promise<string | null>;
  iniciarConCorreo: (correo: string, clave: string) => Promise<string | null>;
  crearCuenta: (correo: string, clave: string) => Promise<string | null>;
  enviarCodigoSms: (celular: string) => Promise<string | null>;
  verificarCodigoSms: (celular: string, codigo: string) => Promise<string | null>;
  pedirCodigoVinculo: (celular: string) => Promise<string | null>;
  confirmarVinculo: (celular: string, codigo: string) => Promise<ResultadoVinculo>;
  // Vincula un código de contribuyente con el DNI en el servidor (padrón de la municipalidad).
  vincularContribuyente: (municipalidadId: string, codigo: string, dni: string) => Promise<string | null>;
  listarVinculos: () => Promise<Vinculo[]>;
  // Confirma el celular de una cuenta de Google o de correo, para los avisos por WhatsApp.
  enviarCodigoCelular: (celular: string) => Promise<string | null>;
  verificarCodigoCelular: (celular: string, codigo: string) => Promise<string | null>;
  // Guarda en la cuenta (user_metadata) lo que el vecino eligió al ingresar.
  guardarDatosIngreso: (datos: DatosIngreso) => Promise<void>;
  cerrarSesion: () => Promise<void>;
};

// Lo que se guarda en la cuenta al aceptar el consentimiento (pantalla 03), para no
// pedirlo cada vez que entra. No lleva teléfono, DNI ni otros datos personales.
export type Vinculo = { municipalidadId: string; codigo: string };

export type DatosIngreso = {
  celularConfirmado?: boolean;
  municipalidadId: string;
  consentimientos: { asistenteIa: boolean; avisosWhatsapp: boolean; avisosSms: boolean };
  consentimientoAceptadoEn: string;
};

export type MetodoIngreso = 'google' | 'correo' | 'celular';

const CLAVE_DATOS = 'almira';

// Lee los datos guardados en la cuenta, o null si todavía no aceptó el consentimiento.
export function leerDatosIngreso(sesion: Session | null): DatosIngreso | null {
  const datos: unknown = sesion?.user.user_metadata?.[CLAVE_DATOS];
  if (!datos || typeof datos !== 'object') return null;
  const { municipalidadId, consentimientos, consentimientoAceptadoEn } = datos as Partial<DatosIngreso>;
  if (typeof municipalidadId !== 'string' || typeof consentimientoAceptadoEn !== 'string') return null;
  if (!consentimientos || typeof consentimientos !== 'object') return null;
  return {
    municipalidadId,
    consentimientoAceptadoEn,
    consentimientos: {
      asistenteIa: consentimientos.asistenteIa === true,
      avisosWhatsapp: consentimientos.avisosWhatsapp === true,
      avisosSms: consentimientos.avisosSms === true,
    },
  };
}

// Cómo entró el vecino, según el proveedor de Supabase Auth.
export function metodoDeSesion(sesion: Session | null): MetodoIngreso | null {
  const proveedor = sesion?.user.app_metadata?.provider;
  if (proveedor === 'google') return 'google';
  if (proveedor === 'email') return 'correo';
  if (proveedor === 'phone') return 'celular';
  return null;
}

// Nombre que trae la cuenta de Google, si lo hay.
export function nombreDeSesion(sesion: Session | null): string | null {
  const metadatos = sesion?.user.user_metadata;
  const nombre: unknown = metadatos?.full_name ?? metadatos?.name;
  return typeof nombre === 'string' && nombre.trim() ? nombre.trim() : null;
}

const ContextoAuth = createContext<Autenticacion | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [sesion, setSesion] = useState<Session | null>(null);
  const [cargando, setCargando] = useState(supabaseConfigurado);

  useEffect(() => {
    if (!supabaseConfigurado) return;
    supabase.auth.getSession().then(({ data }) => {
      setSesion(data.session);
      setCargando(false);
    });
    const { data } = supabase.auth.onAuthStateChange((_evento, nueva) => setSesion(nueva));
    return () => data.subscription.unsubscribe();
  }, []);

  const valor = useMemo<Autenticacion>(
    () => ({
      sesion,
      cargando,
      // Devuelve un mensaje de error para mostrar, o null si todo salió bien.
      iniciarConGoogle: async () => {
        if (!supabaseConfigurado) return 'Falta conectar Almira con Supabase.';
        const redirectTo = Platform.OS === 'web' ? `${window.location.origin}/ingreso` : Linking.createURL('/ingreso');
        const { data, error } = await supabase.auth.signInWithOAuth({
          provider: 'google',
          options: { redirectTo, skipBrowserRedirect: Platform.OS !== 'web' },
        });
        if (error) return 'No pudimos iniciar con Google. Inténtalo de nuevo.';
        if (Platform.OS === 'web') return null;
        const resultado = await WebBrowser.openAuthSessionAsync(data.url, redirectTo);
        if (resultado.type !== 'success') return null;
        const parametros = new URLSearchParams(resultado.url.split('#')[1] ?? '');
        const accessToken = parametros.get('access_token');
        const refreshToken = parametros.get('refresh_token');
        if (!accessToken || !refreshToken) return 'No pudimos iniciar con Google. Inténtalo de nuevo.';
        const { error: errorSesion } = await supabase.auth.setSession({
          access_token: accessToken,
          refresh_token: refreshToken,
        });
        return errorSesion ? 'No pudimos iniciar con Google. Inténtalo de nuevo.' : null;
      },
      iniciarConCorreo: async (correo, clave) => {
        if (!supabaseConfigurado) return 'Falta conectar Almira con Supabase.';
        const { error } = await supabase.auth.signInWithPassword({ email: correo.trim(), password: clave });
        return error ? 'Correo o contraseña incorrectos.' : null;
      },
      // Si el proyecto exige confirmar el correo, no habrá sesión hasta que lo confirme.
      crearCuenta: async (correo, clave) => {
        if (!supabaseConfigurado) return 'Falta conectar Almira con Supabase.';
        const { data, error } = await supabase.auth.signUp({ email: correo.trim(), password: clave });
        if (error) return 'No pudimos crear la cuenta. Revisa el correo y usa al menos 8 caracteres.';
        return data.session ? null : 'Te enviamos un correo para confirmar tu cuenta. Confírmalo y vuelve a ingresar.';
      },
      // El SMS lo manda Supabase con el proveedor configurado (Twilio). Celular peruano de 9 dígitos.
      enviarCodigoSms: async (celular) => {
        if (!supabaseConfigurado) return 'Falta conectar Almira con Supabase.';
        const { error } = await supabase.auth.signInWithOtp({ phone: `+51${celular}` });
        return error ? 'No pudimos enviar el código. Revisa tu número e inténtalo de nuevo.' : null;
      },
      verificarCodigoSms: async (celular, codigo) => {
        if (!supabaseConfigurado) return 'Falta conectar Almira con Supabase.';
        const { error } = await supabase.auth.verifyOtp({ phone: `+51${celular}`, token: codigo, type: 'sms' });
        return error ? 'El código no es correcto o ya venció.' : null;
      },
      vincularContribuyente: async (municipalidadId, codigo, dni) => {
        if (!supabaseConfigurado) return 'Falta conectar Almira con Supabase.';
        const { data, error } = await supabase.rpc('vincular_contribuyente', {
          p_municipalidad: municipalidadId,
          p_codigo: codigo,
          p_dni: dni,
        });
        if (error) return 'No pudimos vincular el código. Inténtalo de nuevo.';
        return data === true ? null : 'No encontramos ese código con ese DNI en el padrón.';
      },
      listarVinculos: async () => {
        if (!supabaseConfigurado) return [];
        const { data } = await supabase
          .from('vinculos_contribuyente')
          .select('municipalidad_id, codigo')
          .order('creado_en');
        return (data ?? []).map((fila) => ({
          municipalidadId: String(fila.municipalidad_id),
          codigo: String(fila.codigo),
        }));
      },
      enviarCodigoCelular: async (celular) => {
        if (!supabaseConfigurado) return 'Falta conectar Almira con Supabase.';
        const { error } = await supabase.auth.updateUser({ phone: `+51${celular}` });
        return error ? 'No pudimos enviar el código. Revisa tu número e inténtalo de nuevo.' : null;
      },
      verificarCodigoCelular: async (celular, codigo) => {
        if (!supabaseConfigurado) return 'Falta conectar Almira con Supabase.';
        const { error } = await supabase.auth.verifyOtp({
          phone: `+51${celular}`,
          token: codigo,
          type: 'phone_change',
        });
        return error ? 'El código no es correcto o ya venció.' : null;
      },
      // Vincular WhatsApp: se confirma el celular de la cuenta ya ingresada con un código SMS
      // (no se crea otra sesión) y la función del servidor lo guarda y escribe por WhatsApp.
      pedirCodigoVinculo: async (celular) => {
        if (!supabaseConfigurado) return 'Falta conectar Almira con Supabase.';
        const { error } = await supabase.auth.updateUser({ phone: `+51${celular}` });
        return error ? 'No pudimos enviar el código. Revisa tu número e inténtalo de nuevo.' : null;
      },
      confirmarVinculo: async (celular, codigo) => {
        const { error } = await supabase.auth.verifyOtp({
          phone: `+51${celular}`,
          token: codigo,
          type: 'phone_change',
        });
        if (error) return { ok: false, mensaje: 'El código no es correcto o ya venció.' };
        const { data, error: errorFuncion } = await supabase.functions.invoke('vincular-whatsapp');
        if (errorFuncion) {
          return { ok: false, mensaje: 'Confirmamos tu celular, pero no pudimos vincularlo a tu cuenta.' };
        }
        return data?.enviado
          ? { ok: true, mensaje: 'Listo. Te escribimos por WhatsApp para confirmar.' }
          : {
              ok: true,
              mensaje:
                'Vinculamos tu celular, pero todavía no pudimos escribirte por WhatsApp. Lo intentaremos con tus próximos avisos.',
            };
      },
      // Si falla, el consentimiento sigue en memoria y se volverá a pedir al próximo ingreso.
      guardarDatosIngreso: async (datos) => {
        if (!supabaseConfigurado || !sesion) return;
        await supabase.auth.updateUser({ data: { [CLAVE_DATOS]: datos } });
      },
      cerrarSesion: async () => {
        if (supabaseConfigurado) await supabase.auth.signOut();
      },
    }),
    [sesion, cargando],
  );
  return <ContextoAuth.Provider value={valor}>{children}</ContextoAuth.Provider>;
}

export function useAuth() {
  const auth = useContext(ContextoAuth);
  if (!auth) throw new Error('useAuth debe usarse dentro de AuthProvider');
  return auth;
}
