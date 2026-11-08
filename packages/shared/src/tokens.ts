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
  // Sombra de la tarjeta de ingreso del panel web (web-01).
  shadow: 'rgba(43, 43, 43, 0.12)',

  // Borde punteado de "Agregar foto" (pantalla 16).
  photoDashed: '#B9C6D4',
  // Dibujos de las fotos simuladas (pantallas 17 y 18): bache de día y poste de noche.
  drawingSky: '#C0D6EE',
  drawingCurb: '#CFCFCF',
  drawingRoad: '#8E99A6',
  drawingHoleOuter: '#4A5462',
  drawingHoleInner: '#2E3540',
  drawingNight: '#22314A',
  drawingNightGround: '#3A4A60',
  drawingPole: '#7F8B9B',
  drawingLamp: '#B9C3CD',
  // Mapa ilustrativo de obras (pantalla 19): manzanas, parque y avenida.
  drawingBlock: '#F5F5F5',
  drawingPark: '#CDE8D5',
  drawingAvenue: '#F3D3D5',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  // Separación entre bloques medida en las pantallas del prototipo.
  block: 12,
  // Separación entre los pasos de la escalera de avisos (pantalla 09).
  ladder: 6,
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
  // Botones bajos del asistente (pantalla 12).
  buttonCompact: 36,
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
  // Chips de canal de la pantalla 11.
  chip: 35,
  // Preguntas sugeridas, campo y botón de enviar del asistente (pantalla 12).
  suggestionChip: 32,
  chatInput: 40,
  // Círculo del ícono de Atención humana (pantalla 14).
  attentionIcon: 56,
  // Perilla del deslizador de cuotas (pantalla 13).
  sliderThumb: 22,
  sliderThumbBorder: 3,
  // Zona de toque del deslizador, más alta que el riel para agarrarlo fácil.
  sliderTouch: 44,
  // Pasos de la escalera de avisos (pantallas 09 y 10): alto mínimo y columna del número.
  noticeStep: 56,
  noticeNumber: 20,
  // Ancho de las burbujas de mensaje de la pantalla 11 (298 de 354 px).
  bubbleWidth: '84%',
  // Foto simulada y caja de "Agregar foto" (pantallas 16 a 18).
  evidencePhoto: 150,
  // Campo "Describe el problema" (pantalla 16).
  textArea: 84,
  // Línea de seguimiento (pantalla 18): punto, trazo y alto de cada paso.
  timelineDot: 22,
  timelineLine: 2,
  timelineStep: 48,
  // Mapa de obras (pantalla 19): alto del dibujo, marcador y cruce de calles.
  mapHeight: 274,
  mapMarker: 28,
  mapMarkerBorder: 2,
  mapStreet: 9,
  mapAvenue: 10,
  // Foto de la obra y barra de financiamiento (pantalla 20).
  workPhoto: 170,
  fundingBar: 12,
  legendDot: 10,
  // Iniciales del vecino en Mi perfil (pantalla 21).
  avatar: 40,
  progress: 6,
  // Barra de avance de la pantalla 04 (el panel web sigue usando progress).
  progressMobile: 8,
  borderWidth: 1,
  focusBorderWidth: 1.5,
} as const;

// "Texto más grande" de Mi perfil (pantalla 21) multiplica letra e interlineado.
export const largeTextScale = 1.2;

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

// Medidas del panel web, tomadas de docs/design/prototipo/web (1440 px de ancho).
export const panelSizes = {
  // Barra lateral: ancho, distancia del menú a los bordes y alto de cada módulo.
  sidebar: 248,
  sidebarInset: 12,
  sidebarBrandX: 22,
  sidebarBrandY: 22,
  navItem: 40,
  navGap: 3,
  navIcon: 16,
  navBadge: 20,
  // Contenido: márgenes, separación entre tarjetas y relleno interior.
  contentX: 26,
  contentY: 22,
  gap: 14,
  cardPadding: 18,
  // Columna de "Requiere tu decisión" junto al gráfico (web-02).
  decisionColumn: 478,
  // Tarjeta de cifra y fila de tabla.
  kpiHeight: 113,
  tableRow: 46,
  tableRowTall: 59,
  // Gráfico de barras verticales: alto de la barra más alta.
  barChart: 112,
  // Barras horizontales: columna de etiqueta, de cifra, grosor y paso entre filas.
  hBarLabel: 138,
  hBarValue: 94,
  hBar: 12,
  hBarRow: 31,
  // "Requiere tu decisión": cuadro del ícono y paso entre filas.
  decisionIcon: 40,
  decisionRow: 63,
  // Número de la escalera de avisos (web-04).
  ladderNumber: 24,
  // Interruptor de "Publicada" (web-06) y del simulador (web-08).
  toggleWidth: 42,
  toggleHeight: 24,
  toggleKnob: 18,
  // Chips de estado y botones de fila.
  chip: 24,
  rowButton: 37,
  rowButtonWide: 184,
  progressWide: 148,
  // Ingreso (web-01).
  loginCard: 400,
  loginHeader: 56,
  loginTop: 258,
} as const;

export type EstiloTextoPanel = EstiloTexto & { familia: 'display' | 'text' };

// Textos del panel web: Poppins para marca, títulos y cifras; Inter para el resto.
export const panelTypography = {
  brand: { familia: 'display', fontSize: 16, fontWeight: '600', lineHeight: 22 },
  title: { familia: 'display', fontSize: 24, fontWeight: '600', lineHeight: 30 },
  cardTitle: { familia: 'display', fontSize: 16, fontWeight: '600', lineHeight: 22 },
  kpi: { familia: 'display', fontSize: 28, fontWeight: '700', lineHeight: 34 },
  loginTitle: { familia: 'display', fontSize: 18, fontWeight: '600', lineHeight: 24 },
  nav: { familia: 'text', fontSize: 14, fontWeight: '600', lineHeight: 20 },
  subtitle: { familia: 'text', fontSize: 14, fontWeight: '400', lineHeight: 20 },
  body: { familia: 'text', fontSize: 13, fontWeight: '400', lineHeight: 18 },
  bodyStrong: { familia: 'text', fontSize: 13, fontWeight: '600', lineHeight: 18 },
  button: { familia: 'text', fontSize: 14, fontWeight: '600', lineHeight: 20 },
  small: { familia: 'text', fontSize: 12, fontWeight: '400', lineHeight: 16 },
  smallStrong: { familia: 'text', fontSize: 12, fontWeight: '600', lineHeight: 16 },
  tableHead: { familia: 'text', fontSize: 11, fontWeight: '600', lineHeight: 16 },
} as const satisfies Record<string, EstiloTextoPanel>;

export const tokens = {
  colors,
  spacing,
  radius,
  sizes,
  fontFamily,
  displayFontFamily,
  typography,
  panelSizes,
  panelTypography,
} as const;
