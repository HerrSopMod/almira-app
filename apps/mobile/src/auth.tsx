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
  cerrarSesion: () => Promise<void>;
};

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
