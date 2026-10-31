import { colors, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

type Props = {
  titulo?: string;
  conVolver?: boolean;
  conAvisos?: boolean;
};

export function Encabezado({ titulo, conVolver, conAvisos }: Props) {
  return (
    <View style={estilos.fila}>
      {conVolver ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Volver"
          hitSlop={8}
          onPress={() => router.back()}
          style={estilos.accion}
        >
          <MaterialIcons name="arrow-back" size={24} color={colors.text} />
        </Pressable>
      ) : null}
      <View style={estilos.titulos}>
        <Texto variante="labelSm" color={colors.primary}>
          Almira
        </Texto>
        {titulo ? <Texto variante="headlineSm">{titulo}</Texto> : null}
      </View>
      {conAvisos ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Recordatorios y avisos"
          hitSlop={8}
          onPress={() => router.push('/recordatorios')}
          style={estilos.accion}
        >
          <MaterialIcons name="notifications-none" size={24} color={colors.text} />
        </Pressable>
      ) : null}
    </View>
  );
}

const estilos = StyleSheet.create({
  fila: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    minHeight: 56,
    paddingHorizontal: spacing.margin,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  titulos: { flex: 1 },
  accion: { minWidth: 48, minHeight: 48, alignItems: 'center', justifyContent: 'center' },
});
