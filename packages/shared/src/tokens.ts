// Paleta turquesa de Stitch (docs/design/stitch_*/civic_clarity/DESIGN.md):
// fondo blanco (#FFFFFF) y color principal #0B7F86. Las medidas y la tipografía
// siguen el prototipo de Figma. Los tonos notice1 a notice3 solo van en la escalera de avisos.

export const colors = {
  primary: '#0B7F86',
  onPrimary: '#FFFFFF',
  header: '#0A6D72',
  background: '#FFFFFF',
  surface: '#FFFFFF',
  surfaceBright: '#FFFFFF',
  backgroundPink: '#E3F6F5',
  neutral: '#D6E3E4',
  chartSecondary: '#79D5DC',

  accent: '#2CC5C0',
  highlight: '#E3F6F5',
  text: '#0F2A2E',
  textSecondary: '#5B6B70',
  border: '#D6E3E4',
  lines: '#6E797A',

  pendingDebt: '#FFFFCC',
  paid: '#2E9E6B',
  paidSoft: '#EAF6F0',
  // Texto sobre Pagado claro, medido en la pantalla 03 del prototipo.
  paidText: '#14563B',

  success: '#2E9E6B',
  successSoft: '#EAF6F0',
  warning: '#C98A00',
  warningSoft: '#FBF5E6',
  danger: '#D64545',
  dangerSoft: '#FAEAEA',

  notice1: '#C3DFE4',
  notice2: '#2A7A80',
  notice3: '#004F54',

  scrim: 'rgba(15, 42, 46, 0.4)',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  // Separación entre bloques medida en las pantallas del prototipo.
  block: 12,
  md: 16,
  lg: 20,
  xl: 24,
  gutter: 16,
  // Márgenes laterales medidos en las pantallas móviles del prototipo.
  margin: 18,
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

// Medidas tomadas de las imágenes del prototipo (docs/design/prototipo/movil).
export const sizes = {
  button: 48,
  buttonTertiary: 48,
  input: 46,
  selector: 48,
  headerBar: 56,
  hero: 280,
  brandIcon: 58,
  featureIcon: 40,
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
  brand: { fontSize: 36, fontWeight: '700', lineHeight: 44 },
  displayCurrency: { fontSize: 32, fontWeight: '700', lineHeight: 38, letterSpacing: -0.64 },
  headlineLg: { fontSize: 24, fontWeight: '700', lineHeight: 32, letterSpacing: -0.24 },
  headlineMd: { fontSize: 20, fontWeight: '600', lineHeight: 28 },
  headlineSm: { fontSize: 18, fontWeight: '600', lineHeight: 24 },
  bodyLg: { fontSize: 16, fontWeight: '400', lineHeight: 24 },
  bodyLgMedium: { fontSize: 16, fontWeight: '500', lineHeight: 24 },
  bodyMd: { fontSize: 14, fontWeight: '400', lineHeight: 20 },
  bodyMdMedium: { fontSize: 14, fontWeight: '500', lineHeight: 20 },
  label: { fontSize: 14, fontWeight: '600', lineHeight: 20 },
  labelLg: { fontSize: 16, fontWeight: '600', lineHeight: 22 },
  caption: { fontSize: 12, fontWeight: '400', lineHeight: 16 },
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
