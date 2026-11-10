import { createClient } from '@supabase/supabase-js';
import { Platform } from 'react-native';
import { almacenSesion } from './almacen-sesion';

const url = process.env.EXPO_PUBLIC_SUPABASE_URL;
const claveAnon = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

// Sin estas dos variables (apps/mobile/.env.local) la app sigue con datos de ejemplo.
export const supabaseConfigurado = Boolean(url && claveAnon);

// Solo va la clave anon (pública). La protección real son las políticas RLS.
export const supabase = createClient(url ?? 'http://localhost', claveAnon ?? 'sin-configurar', {
  auth: {
    storage: almacenSesion,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: Platform.OS === 'web',
  },
});
