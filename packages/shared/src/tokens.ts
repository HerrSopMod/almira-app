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
  // Medidos en las pantallas 04 y 05: borde amarillo y texto del chip «Por vencer».
  pendingDebtBorder: '#E6DF8A',
  pendingDebtText: '#6B5200',
  paid: '#2E8B57',
  paidSoft: '#E2F3E8',
  // Texto sobre Pagado claro, medido en la pantalla 03 del prototipo.
  paidText: '#14563B',
  // Check sobre Pagado claro, medido en las pantallas 05 y 08.
  paidIcon: '#1E6B45',
  // Botón secundario y caja de información de las pantallas 06 a 08.
  backgroundPinkSoft: '#FAF5F5',
  // Radio sin marcar (pantalla 07) y QR simulado (pantalla 08).
  radioOff: '#B9C6D4',
  qr: '#12263F',

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
  // Fondo rosado del ícono de Asistente en la barra inferior.
  tabPillWidth: 40,
  tabPillHeight: 32,
  // Accesos de la pantalla 04.
  shortcut: 76,
  checkbox: 22,
  radio: 22,
  successCircle: 60,
  qr: 150,
  badge: 24,
  progress: 6,
  // Barra de avance de la pantalla 04 (el panel web sigue usando progress).
  progressMobile: 8,
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
  tabLabel: { fontSize: 12, fontWeight: '500', lineHeight: 16 },
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
