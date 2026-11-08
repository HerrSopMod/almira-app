import { colors } from '@almira/shared';
import { Stack } from 'expo-router';

// Inicio, Recordatorios y Mi perfil comparten la pestaña (pantallas 04, 09 y 21).
export default function LayoutInicio() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: colors.background },
      }}
    />
  );
}
