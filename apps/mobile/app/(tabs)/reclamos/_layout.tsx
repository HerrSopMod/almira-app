import { colors } from '@almira/shared';
import { Stack } from 'expo-router';

// Si se abre el seguimiento directo (por ejemplo, al confirmar un reclamo nuevo),
// "volver" lleva a la lista.
export const unstable_settings = { initialRouteName: 'index' };

// Reclamos y su seguimiento comparten la pestaña (pantallas 15 y 18).
export default function LayoutReclamos() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: colors.background },
      }}
    />
  );
}
