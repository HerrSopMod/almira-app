import { colors, spacing } from '@almira/shared';
import { StyleSheet, Switch, View } from 'react-native';
import { Texto } from './Texto';

type Props = {
  titulo: string;
  detalle: string;
  activo: boolean;
  onCambiar: (activo: boolean) => void;
};

// Fila con título, detalle e interruptor (pantalla 03 del prototipo).
export function Interruptor({ titulo, detalle, activo, onCambiar }: Props) {
  return (
    <View style={estilos.fila}>
      <View style={estilos.textos}>
        <Texto variante="labelLg">{titulo}</Texto>
        <Texto variante="bodyMd" color={colors.textSecondary}>
          {detalle}
        </Texto>
      </View>
      <Switch
        accessibilityLabel={titulo}
        accessibilityHint={detalle}
        value={activo}
        onValueChange={onCambiar}
        trackColor={{ true: colors.primary, false: colors.lines }}
        thumbColor={colors.onPrimary}
        ios_backgroundColor={colors.lines}
      />
    </View>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  textos: { flex: 1, gap: spacing.xs },
});
