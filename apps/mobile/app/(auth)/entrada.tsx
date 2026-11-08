import { colors, sizes, spacing } from '@almira/shared';
import { router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { Fragment } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  CajaIcono,
  PiePrototipo,
  Separador,
  Tarjeta,
  type NombreIcono,
} from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Logo } from '@/components/Logo';
import { Texto } from '@/components/Texto';

const FUNCIONES: { titulo: string; detalle: string; icono: NombreIcono }[] = [
  { titulo: 'Recuerda', detalle: 'Te avisamos antes de que venza.', icono: 'notifications-none' },
  { titulo: 'Paga', detalle: 'Desde la app, con constancia al instante.', icono: 'payments' },
  { titulo: 'Ve la obra', detalle: 'En qué se usa lo que pagas.', icono: 'construction' },
  { titulo: 'Reclama', detalle: 'Con foto y ubicación, y sigue el plazo.', icono: 'photo-camera' },
];

// Pantalla 01 (maqueta 01-entrada). La municipalidad se elige después, en la pantalla 02d.
export default function Entrada() {
  const { top, bottom } = useSafeAreaInsets();

  return (
    <View style={estilos.raiz}>
      <StatusBar style="dark" />
      <ScrollView
        contentContainerStyle={[
          estilos.contenido,
          { paddingTop: top + sizes.entryTop, paddingBottom: spacing.lg + bottom },
        ]}
      >
        <View style={estilos.portada}>
          <Logo grande />
          <Texto variante="brand" alineacion="center" accessibilityRole="header">
            Almira
          </Texto>
          <Texto color={colors.textSecondary} alineacion="center">
            {'Paga con claridad.\nReclama con evidencia.'}
          </Texto>
        </View>

        <Tarjeta style={estilos.funciones}>
          {FUNCIONES.map(({ titulo, detalle, icono }, indice) => (
            <Fragment key={titulo}>
              {indice > 0 ? <Separador /> : null}
              <View style={estilos.funcion}>
                <CajaIcono icono={icono} />
                <View style={estilos.flexible}>
                  <Texto variante="bodyLgMedium">{titulo}</Texto>
                  <Texto variante="bodyMd" color={colors.textSecondary}>
                    {detalle}
                  </Texto>
                </View>
              </View>
            </Fragment>
          ))}
        </Tarjeta>

        <View style={estilos.botones}>
          <Boton titulo="Empezar" onPress={() => router.push('/ingreso')} />
          <Boton
            tipo="terciario"
            titulo="No tengo cuenta ni smartphone propio"
            onPress={() => router.push('/sin-smartphone')}
          />
          <PiePrototipo />
        </View>
      </ScrollView>
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: { flex: 1, backgroundColor: colors.background },
  contenido: { flexGrow: 1, paddingHorizontal: spacing.margin },
  portada: { alignItems: 'center', gap: spacing.sm },
  funciones: { marginTop: spacing.xxxl },
  funcion: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  flexible: { flex: 1 },
  // Los botones bajan hasta el pie cuando sobra alto.
  botones: { marginTop: 'auto', paddingTop: spacing.xxl, gap: spacing.sm },
});
