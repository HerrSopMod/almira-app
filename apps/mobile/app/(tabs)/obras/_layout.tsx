import { colors } from '@almira/shared';
import { Stack } from 'expo-router';

// Si se abre el detalle directo (por ejemplo, desde Inicio),
// "volver" lleva al mapa.
export const unstable_settings = { initialRouteName: 'index' };

// El mapa de obras y el detalle de cada obra comparten la pestaña (pantallas 19 y 20).
export default function LayoutObras() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: colors.background },
      }}
    />
  );
}
