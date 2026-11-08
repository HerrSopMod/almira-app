import { colors } from '@almira/shared';
import { Stack } from 'expo-router';

// Mi cuenta y el detalle de cada deuda comparten la pestaña (pantallas 05 y 06).
export default function LayoutCuenta() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: colors.background },
      }}
    />
  );
}
