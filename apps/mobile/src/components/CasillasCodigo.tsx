import { colors, radius, sizes, spacing } from '@almira/shared';
import { useState } from 'react';
import { StyleSheet, TextInput, View } from 'react-native';
import { Texto } from './Texto';

type Props = {
  valor: string;
  onCambiar: (valor: string) => void;
  largo?: number;
};

// Casillas del código SMS (pantalla 02b). Las casillas solo dibujan: encima va un
// campo transparente con el teclado numérico del sistema, que recibe los toques,
// el pegado y el autocompletado del SMS.
export function CasillasCodigo({ valor, onCambiar, largo = 6 }: Props) {
  const [enfocado, setEnfocado] = useState(false);
  const actual = Math.min(valor.length, largo - 1);
  return (
    <View style={estilos.raiz}>
      <View
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
        style={estilos.casillas}
      >
        {Array.from({ length: largo }, (_, indice) => (
          <View
            key={indice}
            style={[estilos.casilla, enfocado && indice === actual && estilos.casillaActual]}
          >
            <Texto variante="headlineMd" tabular>
              {valor[indice] ?? ''}
            </Texto>
          </View>
        ))}
      </View>
      <TextInput
        accessibilityLabel={`Código de ${largo} dígitos`}
        value={valor}
        onChangeText={(texto) => onCambiar(texto.replace(/\D/g, '').slice(0, largo))}
        keyboardType="number-pad"
        inputMode="numeric"
        textContentType="oneTimeCode"
        autoComplete="sms-otp"
        maxLength={largo}
        caretHidden
        onFocus={() => setEnfocado(true)}
        onBlur={() => setEnfocado(false)}
        style={estilos.campo}
      />
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: { height: sizes.input },
  casillas: { flex: 1, flexDirection: 'row', gap: spacing.sm, pointerEvents: 'none' },
  casilla: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
    backgroundColor: colors.surface,
  },
  casillaActual: { borderWidth: sizes.focusBorderWidth, borderColor: colors.primary },
  campo: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    opacity: 0,
    color: 'transparent',
  },
});
