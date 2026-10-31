// Tokens de docs/design/.../civic_clarity/DESIGN.md.
// Cuando el front matter y el texto de DESIGN.md difieren, manda el texto:
// fondo y superficies blancos (#FFFFFF) y color principal #0B7F86.

const paletaFrontMatter = {
  surfaceDim: '#C3DFE4',
  surfaceContainerLowest: '#FFFFFF',
  surfaceContainerLow: '#DCF9FE',
  surfaceContainer: '#D7F3F8',
  surfaceContainerHigh: '#D1EDF2',
  surfaceContainerHighest: '#CBE8ED',
  surfaceVariant: '#CBE8ED',
  surfaceTint: '#00696F',
  onSurface: '#031F23',
  onSurfaceVariant: '#3E494A',
  inverseSurface: '#1A3438',
  inverseOnSurface: '#D9F6FB',
  outline: '#6E797A',
  outlineVariant: '#BDC9C9',
  onBackground: '#031F23',
  onPrimary: '#FFFFFF',
  primaryContainer: '#0B7F86',
  onPrimaryContainer: '#E8FDFF',
  inversePrimary: '#79D5DC',
  primaryFixed: '#96F1F9',
  primaryFixedDim: '#79D5DC',
  onPrimaryFixed: '#002022',
  onPrimaryFixedVariant: '#004F54',
  secondary: '#006A67',
  onSecondary: '#FFFFFF',
  secondaryContainer: '#6EF7F1',
  onSecondaryContainer: '#00706D',
  secondaryFixed: '#6EF7F1',
  secondaryFixedDim: '#4CDAD5',
  onSecondaryFixed: '#00201F',
  onSecondaryFixedVariant: '#00504D',
  tertiary: '#4C5D5D',
  onTertiary: '#FFFFFF',
  tertiaryContainer: '#647675',
  onTertiaryContainer: '#EAFDFC',
  tertiaryFixed: '#D3E6E5',
  tertiaryFixedDim: '#B8CAC9',
  onTertiaryFixed: '#0D1E1E',
  onTertiaryFixedVariant: '#394A4A',
  error: '#BA1A1A',
  onError: '#FFFFFF',
  errorContainer: '#FFDAD6',
  onErrorContainer: '#93000A',
} as const;

export const colors = {
  ...paletaFrontMatter,

  primary: '#0B7F86',
  background: '#FFFFFF',
  surface: '#FFFFFF',
  surfaceBright: '#FFFFFF',

  accent: '#2CC5C0',
  highlight: '#E3F6F5',
  text: '#0F2A2E',
  textSecondary: '#5B6B70',
  border: '#D6E3E4',

  success: '#2E9E6B',
  successSoft: '#EAF6F0',
  warning: '#C98A00',
  warningSoft: '#FBF5E6',
  danger: '#D64545',
  dangerSoft: '#FAEAEA',

  scrim: 'rgba(15, 42, 46, 0.4)',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 20,
  xl: 24,
  gutter: 16,
  margin: 20,
} as const;

export const radius = {
  badge: 6,
  sm: 4,
  default: 8,
  md: 12,
  lg: 16,
  xl: 24,
  full: 9999,
} as const;

export const sizes = {
  button: 52,
  buttonTertiary: 48,
  input: 52,
  tabBar: 64,
  badge: 24,
  progress: 6,
  borderWidth: 1,
  focusBorderWidth: 1.5,
} as const;

export const fontFamily = 'Inter';

export type EstiloTexto = {
  fontSize: number;
  fontWeight: '400' | '500' | '600' | '700';
  lineHeight: number;
  letterSpacing?: number;
};

export const typography = {
  displayCurrency: { fontSize: 32, fontWeight: '700', lineHeight: 38, letterSpacing: -0.64 },
  headlineLg: { fontSize: 24, fontWeight: '700', lineHeight: 32, letterSpacing: -0.24 },
  headlineMd: { fontSize: 20, fontWeight: '600', lineHeight: 28 },
  headlineSm: { fontSize: 18, fontWeight: '600', lineHeight: 24 },
  bodyLg: { fontSize: 16, fontWeight: '400', lineHeight: 24 },
  bodyLgMedium: { fontSize: 16, fontWeight: '500', lineHeight: 24 },
  bodyMd: { fontSize: 14, fontWeight: '400', lineHeight: 20 },
  bodyMdMedium: { fontSize: 14, fontWeight: '500', lineHeight: 20 },
  button: { fontSize: 16, fontWeight: '600', lineHeight: 20 },
  labelSm: { fontSize: 12, fontWeight: '600', lineHeight: 16, letterSpacing: 0.24 },
  tabLabel: { fontSize: 11, fontWeight: '500', lineHeight: 14 },
} as const satisfies Record<string, EstiloTexto>;

export const tokens = { colors, spacing, radius, sizes, fontFamily, typography } as const;
