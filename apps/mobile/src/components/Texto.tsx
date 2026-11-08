import { colors, largeTextScale, typography, type EstiloTexto } from '@almira/shared';
import { Text, type TextProps } from 'react-native';
import { useTextoGrande } from '@/textoGrande';

type Peso = EstiloTexto['fontWeight'];

// Pesos de Inter que carga app/_layout.tsx.
const FAMILIA_POR_PESO: Record<Peso, string> = {
  '400': 'Inter_400Regular',
  '500': 'Inter_500Medium',
  '600': 'Inter_600SemiBold',
  '700': 'Inter_700Bold',
};

export const familiaInter = (peso: Peso) => FAMILIA_POR_PESO[peso];

// Multiplica medidas de texto cuando el vecino activa "Texto más grande".
export function useEscalaTexto() {
  return useTextoGrande().activo ? largeTextScale : 1;
}

type Props = TextProps & {
  variante?: keyof typeof typography;
  color?: string;
  alineacion?: 'left' | 'right' | 'center';
  // Cifras tabulares: montos, fechas y tablas.
  tabular?: boolean;
  // Cambia el peso de la variante, por ejemplo la opción activa de un segmentado.
  peso?: Peso;
};

export function Texto({
  variante = 'bodyLg',
  color = colors.text,
  alineacion,
  tabular,
  peso,
  style,
  ...resto
}: Props) {
  const { fontWeight, ...estilo } = typography[variante] as EstiloTexto;
  const escala = useEscalaTexto();
  return (
    <Text
      style={[
        estilo,
        {
          fontSize: estilo.fontSize * escala,
          lineHeight: estilo.lineHeight * escala,
          color,
          fontFamily: familiaInter(peso ?? fontWeight),
          textAlign: alineacion,
          fontVariant: tabular ? ['tabular-nums'] : undefined,
        },
        style,
      ]}
      {...resto}
    />
  );
}
