import { colors, radius, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { PiePrototipo } from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { FilaMunicipalidad, SelectorMunicipalidad } from '@/components/SelectorMunicipalidad';
import { Logo } from '@/components/Logo';
import { Texto } from '@/components/Texto';

const FUNCIONES = [
  { titulo: 'Recuerda', icono: 'notifications-none' },
  { titulo: 'Paga', icono: 'payments' },
  { titulo: 'Ve la obra', icono: 'construction' },
  { titulo: 'Reclama', icono: 'photo-camera' },
] as const;

// Pantalla 01 del prototipo.
export default function Entrada() {
  const { top, bottom } = useSafeAreaInsets();
  const [selectorAbierto, setSelectorAbierto] = useState(false);

  return (
    <View style={estilos.raiz}>
      <StatusBar style="dark" />
      <ScrollView contentContainerStyle={{ paddingBottom: spacing.lg + bottom }}>
        <View style={[estilos.portada, { paddingTop: top, minHeight: sizes.hero + top }]}>
          <Logo grande />
          <View>
            <Texto variante="brand" accessibilityRole="header">
              Almira
            </Texto>
            <Texto color={colors.textSecondary}>Paga con claridad. Reclama con evidencia.</Texto>
          </View>
        </View>

        <View style={estilos.contenido}>
          <View style={estilos.funciones}>
            {FUNCIONES.map(({ titulo, icono }) => (
              <View key={titulo} style={estilos.funcion}>
                <View style={estilos.funcionIcono}>
                  <MaterialIcons name={icono} size={22} color={colors.primary} />
                </View>
                <Texto variante="bodyMdMedium" alineacion="center" numberOfLines={1}>
                  {titulo}
                </Texto>
              </View>
            ))}
          </View>

          <View style={estilos.grupo}>
            <Texto variante="bodyMdMedium">Tu municipalidad</Texto>
            <FilaMunicipalidad onPress={() => setSelectorAbierto(true)} />
          </View>

          <Boton titulo="Empezar" onPress={() => router.push('/ingreso')} />
          <Boton
            tipo="secundario"
            titulo="No tengo cuenta ni smartphone propio"
            onPress={() => router.push('/sin-smartphone')}
          />
          <PiePrototipo />
        </View>
      </ScrollView>

      <SelectorMunicipalidad
        visible={selectorAbierto}
        onCerrar={() => setSelectorAbierto(false)}
      />
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: { flex: 1, backgroundColor: colors.background },
  portada: {
    justifyContent: 'flex-end',
    gap: spacing.blockDense,
    paddingHorizontal: spacing.margin,
    paddingBottom: spacing.lg,
  },
  contenido: {
    gap: spacing.blockDense,
    paddingHorizontal: spacing.margin,
    paddingTop: spacing.margin,
  },
  funciones: { flexDirection: 'row', gap: spacing.sm, marginBottom: spacing.sm },
  funcion: {
    flex: 1,
    alignItems: 'center',
    gap: spacing.xs,
    paddingVertical: spacing.blockDense,
    paddingHorizontal: spacing.xs,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  funcionIcono: {
    width: sizes.iconBox,
    height: sizes.iconBox,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.iconBox,
    backgroundColor: colors.subtle,
  },
  grupo: { gap: spacing.sm },
});
