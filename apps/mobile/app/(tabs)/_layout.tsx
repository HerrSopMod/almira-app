import { colors, radius, sizes, typography } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

const PESTANAS = [
  { name: 'inicio', title: 'Inicio', icono: 'home' },
  { name: 'pagar', title: 'Pagar', icono: 'payments' },
  { name: 'reclamos', title: 'Reclamos', icono: 'report-problem' },
  { name: 'obras', title: 'Obras', icono: 'construction' },
  { name: 'asistente', title: 'Asistente', icono: 'support-agent' },
] as const;

export default function LayoutPestanas() {
  const { bottom } = useSafeAreaInsets();
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textSecondary,
        tabBarLabelStyle: {
          fontFamily: 'Inter_500Medium',
          fontSize: typography.tabLabel.fontSize,
        },
        tabBarStyle: {
          height: sizes.tabBar + bottom,
          backgroundColor: colors.background,
          borderTopWidth: 1,
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
              <MaterialIcons name={icono} size={24} color={color as string} />
            ),
          }}
        />
      ))}
    </Tabs>
  );
}
