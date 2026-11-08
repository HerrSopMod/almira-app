import { colors, radius, sizes, spacing, typography } from '@almira/shared';
import { useState } from 'react';
import { StyleSheet, TextInput, View, type TextInputProps } from 'react-native';
import { familiaInter, Texto, useEscalaTexto } from './Texto';

type Props = TextInputProps & { etiqueta?: string; ayuda?: string };

// Campo de 52 px con la etiqueta arriba (LEEME.md → Campo). Con foco, borde primario.
export function Campo({ etiqueta, ayuda, style, multiline, ...resto }: Props) {
  const [enfocado, setEnfocado] = useState(false);
  const escala = useEscalaTexto();
  return (
    <View style={estilos.grupo}>
      {etiqueta ? <Texto variante="bodyMdMedium">{etiqueta}</Texto> : null}
      <TextInput
        accessibilityLabel={etiqueta}
        placeholderTextColor={colors.textSecondary}
        onFocus={() => setEnfocado(true)}
        onBlur={() => setEnfocado(false)}
        multiline={multiline}
        textAlignVertical={multiline ? 'top' : 'center'}
        style={[
          estilos.campo,
          multiline && estilos.multilinea,
          { fontSize: typography.bodyLg.fontSize * escala },
          multiline && { lineHeight: typography.bodyLg.lineHeight * escala },
          enfocado && estilos.enfocado,
          style,
        ]}
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
    minHeight: sizes.input,
    paddingHorizontal: spacing.md,
    backgroundColor: colors.surface,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
    color: colors.text,
    fontFamily: familiaInter('400'),
  },
  multilinea: { minHeight: sizes.textArea, paddingVertical: spacing.blockDense },
  enfocado: { borderWidth: sizes.focusBorderWidth, borderColor: colors.primary },
});
