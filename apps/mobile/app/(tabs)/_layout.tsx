import { colors, radius, sizes, typography } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { familiaInter, useEscalaTexto } from '@/components/Texto';

// Pestañas de LEEME.md → Barra inferior, en este orden. "Pagar" conserva la ruta cuenta.
// MaterialIcons no trae versión de contorno de estos íconos: la activa solo cambia de color.
const PESTANAS = [
  { name: 'inicio', title: 'Inicio', icono: 'home' },
  { name: 'cuenta', title: 'Pagar', icono: 'payments' },
  { name: 'reclamos', title: 'Reclamos', icono: 'report' },
  { name: 'obras', title: 'Obras', icono: 'construction' },
  { name: 'asistente', title: 'Asistente', icono: 'support-agent' },
] as const satisfies readonly { name: string; title: string; icono: keyof typeof MaterialIcons.glyphMap }[];

export default function LayoutPestanas() {
  const { bottom } = useSafeAreaInsets();
  const escala = useEscalaTexto();
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textSecondary,
        tabBarLabelStyle: {
          fontFamily: familiaInter(typography.tabLabel.fontWeight),
          fontSize: typography.tabLabel.fontSize * escala,
          lineHeight: typography.tabLabel.lineHeight * escala,
        },
        tabBarStyle: {
          height: sizes.tabBar + bottom,
          backgroundColor: colors.surface,
          borderTopWidth: sizes.borderWidth,
          borderTopColor: colors.border,
          borderTopLeftRadius: radius.lg,
          borderTopRightRadius: radius.lg,
          elevation: 0,
          shadowOpacity: 0,
        },
      }}
    >
      {PESTANAS.map(({ name, title, icono }) => (
        <Tabs.Screen
          key={name}
          name={name}
          options={{
            title,
            tabBarIcon: ({ color }) => (
              <MaterialIcons name={icono} size={sizes.icon} color={color as string} />
            ),
          }}
        />
      ))}
    </Tabs>
  );
}
