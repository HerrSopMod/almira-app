import { colors, radius, sizes, typography } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Tabs } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

// Pestañas del prototipo (pantallas 04 a 06).
const PESTANAS = [
  { name: 'inicio', title: 'Inicio', icono: 'home-outline' },
  { name: 'cuenta', title: 'Mi cuenta', icono: 'wallet-outline' },
  { name: 'asistente', title: 'Asistente', icono: 'robot-outline' },
  { name: 'reclamos', title: 'Reclamos', icono: 'camera-outline' },
  { name: 'obras', title: 'Obras', icono: 'hard-hat' },
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
          lineHeight: typography.tabLabel.lineHeight,
        },
        tabBarStyle: {
          height: sizes.tabBar + bottom,
          backgroundColor: colors.background,
          borderTopWidth: sizes.borderWidth,
          borderTopColor: colors.border,
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
            tabBarIcon: ({ color }) => {
              const imagen = <MaterialCommunityIcons name={icono} size={24} color={color as string} />;
              // En el prototipo, Asistente siempre lleva un fondo rosado.
              return name === 'asistente' ? <View style={estilos.resalte}>{imagen}</View> : imagen;
            },
          }}
        />
      ))}
    </Tabs>
  );
}

const estilos = StyleSheet.create({
  resalte: {
    width: sizes.tabPillWidth,
    height: sizes.tabPillHeight,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.md,
    backgroundColor: colors.backgroundPink,
  },
});
