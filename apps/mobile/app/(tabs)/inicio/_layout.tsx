import { colors } from '@almira/shared';
import { Stack } from 'expo-router';

// Inicio y Recordatorios comparten la pestaña (pantallas 04 y 09).
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
