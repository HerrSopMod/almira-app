import { colors, municipalidades, radius, sizes, spacing } from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Modal, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useDatosMunicipales, useSesion } from '@/sesion';
import { Opcion } from './Opcion';
import { Texto } from './Texto';

// Fila "Tu municipalidad" de la pantalla 01: muestra la municipalidad elegida y abre la lista.
export function FilaMunicipalidad({ onPress }: { onPress: () => void }) {
  const { municipalidad } = useDatosMunicipales();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`Tu municipalidad: ${municipalidad.nombre}. Cambiar`}
      onPress={onPress}
      style={estilos.fila}
    >
      <MaterialCommunityIcons name="bank-outline" size={22} color={colors.text} />
      <Texto variante="label" style={estilos.flexible} numberOfLines={1}>
        {municipalidad.nombre}
      </Texto>
      <MaterialCommunityIcons name="chevron-right" size={24} color={colors.text} />
    </Pressable>
  );
}

// Lista de municipalidades activas (salen de los datos, nunca del código de la interfaz).
export function SelectorMunicipalidad({
  visible,
  onCerrar,
}: {
  visible: boolean;
  onCerrar: () => void;
}) {
  const { municipalidadId, elegirMunicipalidad } = useSesion();
  const { bottom } = useSafeAreaInsets();
  const activas = municipalidades.filter((m) => m.activa);

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onCerrar}>
      <View style={estilos.fondo}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Cerrar"
          onPress={onCerrar}
          style={StyleSheet.absoluteFill}
        />
        <View style={[estilos.hoja, { paddingBottom: spacing.lg + bottom }]}>
          <Texto variante="headlineSm" fuente="poppins" accessibilityRole="header">
            Tu municipalidad
          </Texto>
          <ScrollView contentContainerStyle={estilos.lista}>
            {activas.map((municipalidad) => (
              <Opcion
                key={municipalidad.id}
                titulo={municipalidad.nombre}
                detalle={municipalidad.zona}
                seleccionada={municipalidad.id === municipalidadId}
                onPress={() => {
                  elegirMunicipalidad(municipalidad.id);
                  onCerrar();
                }}
              />
            ))}
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

const estilos = StyleSheet.create({
  fila: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    height: sizes.selector,
    paddingHorizontal: spacing.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
    backgroundColor: colors.surface,
  },
  flexible: { flex: 1 },
  fondo: { flex: 1, justifyContent: 'flex-end', backgroundColor: colors.scrim },
  hoja: {
    maxHeight: '80%',
    gap: spacing.md,
    paddingTop: spacing.xl,
    paddingHorizontal: spacing.margin,
    backgroundColor: colors.surface,
    borderTopLeftRadius: radius.lg,
    borderTopRightRadius: radius.lg,
  },
  lista: { gap: spacing.sm },
});
