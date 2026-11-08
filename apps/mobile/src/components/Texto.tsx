import { colors, largeTextScale, typography } from '@almira/shared';
import { Text, type TextProps } from 'react-native';
import { useTextoGrande } from '@/textoGrande';

const FAMILIA_POR_PESO = {
  '400': 'Inter_400Regular',
  '500': 'Inter_500Medium',
  '600': 'Inter_600SemiBold',
  '700': 'Inter_700Bold',
} as const;

// Solo se cargan Poppins SemiBold y Bold (app/_layout.tsx).
const POPPINS_POR_PESO = {
  '400': 'Poppins_600SemiBold',
  '500': 'Poppins_600SemiBold',
  '600': 'Poppins_600SemiBold',
  '700': 'Poppins_700Bold',
} as const;

type Props = TextProps & {
  variante?: keyof typeof typography;
  color?: string;
  alineacion?: 'left' | 'right' | 'center';
  tabular?: boolean;
  // Poppins: montos, marca y títulos. Inter: el resto.
  fuente?: 'inter' | 'poppins';
};

export function Texto({
  variante = 'bodyLg',
  color = colors.text,
  alineacion,
  tabular,
  fuente = 'inter',
  style,
  ...resto
}: Props) {
  const { fontWeight, ...estilo } = typography[variante];
  const escala = useTextoGrande().activo ? largeTextScale : 1;
  return (
    <Text
      style={[
        estilo,
        {
          fontSize: estilo.fontSize * escala,
          lineHeight: estilo.lineHeight * escala,
          color,
          fontFamily: (fuente === 'poppins' ? POPPINS_POR_PESO : FAMILIA_POR_PESO)[fontWeight],
          textAlign: alineacion,
          fontVariant: tabular ? ['tabular-nums'] : undefined,
        },
        style,
      ]}
      {...resto}
    />
  );
}
