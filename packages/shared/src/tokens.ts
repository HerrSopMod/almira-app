// Colores de la guía de estilos del prototipo de Figma
// (docs/design/prototipo/general/00-guia-de-estilos.png y LEEME.md).
// Los tonos vino (notice1 a notice3) solo van en la escalera de avisos.

export const colors = {
  primary: '#C00000',
  onPrimary: '#FFFFFF',
  header: '#800404',
  background: '#FFFFFF',
  surface: '#FFFFFF',
  surfaceBright: '#FFFFFF',
  backgroundPink: '#F7ECEC',
  neutral: '#E8E8E8',
  chartSecondary: '#F4A6A6',

  accent: '#F4A6A6',
  highlight: '#F7ECEC',
  text: '#2B2B2B',
  textSecondary: '#595959',
  border: '#E8E8E8',
  lines: '#808080',

  pendingDebt: '#FFFFCC',
  paid: '#2E8B57',
  paidSoft: '#E2F3E8',

  success: '#2E8B57',
  successSoft: '#E2F3E8',
  warning: '#2B2B2B',
  warningSoft: '#FFFFCC',
  danger: '#C00000',
  dangerSoft: '#F7ECEC',

  notice1: '#E9C1C6',
  notice2: '#9A5563',
  notice3: '#5B1428',

  scrim: 'rgba(43, 43, 43, 0.4)',
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
export const displayFontFamily = 'Poppins';

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

export const tokens = {
  colors,
  spacing,
  radius,
  sizes,
  fontFamily,
  displayFontFamily,
  typography,
} as const;
