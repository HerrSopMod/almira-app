import type { Session } from '@supabase/supabase-js';
import * as Linking from 'expo-linking';
import * as WebBrowser from 'expo-web-browser';
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { Platform } from 'react-native';
import { supabase, supabaseConfigurado } from './supabase';

WebBrowser.maybeCompleteAuthSession();

type Autenticacion = {
  sesion: Session | null;
  cargando: boolean;
  iniciarConGoogle: () => Promise<string | null>;
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
