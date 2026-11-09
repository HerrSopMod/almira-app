import { colors } from '@almira/shared';
import {
  Inter_400Regular,
  Inter_500Medium,
  Inter_600SemiBold,
  Inter_700Bold,
  useFonts,
} from '@expo-google-fonts/inter';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthProvider } from '@/auth';
import { SesionProvider, useSesion } from '@/sesion';
import { useAuth } from '@/auth';
import { TextoGrandeProvider } from '@/textoGrande';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [fuentesListas] = useFonts({
    Inter_400Regular,
    Inter_500Medium,
    Inter_600SemiBold,
    Inter_700Bold,
  });

  useEffect(() => {
    if (fuentesListas) SplashScreen.hideAsync();
  }, [fuentesListas]);

  if (!fuentesListas) return null;

  return (
    <SafeAreaProvider>
      <AuthProvider>
        <SesionProvider>
          <TextoGrandeProvider>
            <StatusBar style="dark" />
            <Navegacion />
          </TextoGrandeProvider>
        </SesionProvider>
      </AuthProvider>
    </SafeAreaProvider>
  );
}

// Inicio y las demás pantallas de la app solo se abren después de aceptar el
// consentimiento (Ley N.° 29733). El ingreso, Privacidad y Sin smartphone quedan abiertos.
function Navegacion() {
  const { cargando } = useAuth();
  const { consentimientoAceptado } = useSesion();
  // Mientras Supabase recupera la sesión guardada no se decide nada.
  if (cargando) return null;
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: colors.background },
      }}
    >
      <Stack.Protected guard={consentimientoAceptado}>
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="avisos/[id]" />
        <Stack.Screen name="avisos/como-llegan" />
        <Stack.Screen name="pago/confirmar" />
        <Stack.Screen name="pago/constancia" />
        <Stack.Screen name="reclamo/nuevo" />
        <Stack.Screen name="reclamo/envio" />
        <Stack.Screen name="atencion-humana" />
        <Stack.Screen name="simulacion-cuotas" />
      </Stack.Protected>
    </Stack>
  );
}
