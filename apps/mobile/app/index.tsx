import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { Texto } from '@/components/Texto';

const DURACION_CARGA_MS = 1800;

// Pantalla de carga: muestra la marca un momento y pasa al login. No carga datos reales.
export default function Carga() {
  useEffect(() => {
    const espera = setTimeout(() => router.replace('/login'), DURACION_CARGA_MS);
    return () => clearTimeout(espera);
  }, []);

  return (
    <View style={estilos.raiz} accessibilityLabel="Cargando Almira">
      <StatusBar style="light" />
      <View style={estilos.marca}>
        <View style={estilos.icono}>
          <MaterialCommunityIcons name="bank" size={32} color={colors.primary} />
        </View>
        <Texto variante="brand" fuente="poppins" color={colors.onPrimary} accessibilityRole="header">
          Almira
        </Texto>
        <Texto color={colors.onPrimary} alineacion="center">
          Paga con claridad. Reclama con evidencia.
        </Texto>
      </View>
      <ActivityIndicator color={colors.onPrimary} size="small" style={estilos.indicador} />
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.margin,
    backgroundColor: colors.header,
  },
  marca: { alignItems: 'center', gap: spacing.block },
  icono: {
    width: sizes.brandIcon,
    height: sizes.brandIcon,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.md,
    backgroundColor: colors.surface,
  },
  indicador: { position: 'absolute', bottom: spacing.xl * 2 },
});
