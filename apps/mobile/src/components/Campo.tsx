import { colors, radius, sizes, spacing, typography } from '@almira/shared';
import { useState } from 'react';
import { StyleSheet, TextInput, View, type TextInputProps } from 'react-native';
import { Texto } from './Texto';

type Props = TextInputProps & { etiqueta?: string; ayuda?: string };

export function Campo({ etiqueta, ayuda, style, ...resto }: Props) {
  const [enfocado, setEnfocado] = useState(false);
  return (
    <View style={estilos.grupo}>
      {etiqueta ? <Texto variante="label">{etiqueta}</Texto> : null}
      <TextInput
        accessibilityLabel={etiqueta}
        placeholderTextColor={colors.textSecondary}
        onFocus={() => setEnfocado(true)}
        onBlur={() => setEnfocado(false)}
        style={[estilos.campo, enfocado && estilos.enfocado, style]}
        {...resto}
      />
      {ayuda ? (
        <Texto variante="bodyMd" color={colors.textSecondary}>
          {ayuda}
        </Texto>
      ) : null}
    </View>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.sm },
  campo: {
    height: sizes.input,
    paddingHorizontal: spacing.md,
    backgroundColor: colors.background,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
    color: colors.text,
    fontFamily: 'Inter_400Regular',
    fontSize: typography.bodyLg.fontSize,
  },
  enfocado: { borderWidth: sizes.focusBorderWidth, borderColor: colors.primary },
});
