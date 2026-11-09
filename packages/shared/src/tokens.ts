// Tokens del estilo turquesa (docs/design/turquesa/LEEME.md).
// Los nombres siguen las tablas de esa guía.

export const colors = {
  primary: '#0B7F86',
  primaryPressed: '#00646A',
  primaryDisabled: '#A9D2D4',
  onPrimary: '#FFFFFF',
  // Solo barras de avance y plazos: no es interactivo.
  accent: '#2CC5C0',
  // Fondo del bloque Destacado (máximo uno por pantalla) y del módulo activo del panel.
  highlight: '#E3F6F5',
  // Cajas de ícono, controles segmentados y burbujas recibidas.
  subtle: '#F2F8F8',
  background: '#FFFFFF',
  surface: '#FFFFFF',
  panelBackground: '#F7FAFA',
  text: '#0F2A2E',
  textSecondary: '#5B6B70',
  border: '#D6E3E4',
  track: '#E6EFF0',

  // En las insignias el texto usa la variante …Text (contraste AA); el color base va
  // en el punto, los marcadores del mapa y el borde de la alerta activa.
  success: '#2E9E6B',
  successSoft: '#EAF6F0',
  successText: '#1F7A50',
  warning: '#C98A00',
  warningSoft: '#FBF5E6',
  warningText: '#8A5E00',
  danger: '#D64545',
  dangerSoft: '#FAEAEA',
  dangerText: '#B42F2F',

  // Gráficos: serie resaltada y serie de apoyo (toda barra lleva su cifra escrita).
  chart1: '#0B7F86',
  chart2: '#7CC4C8',

  scrim: 'rgba(15, 42, 46, 0.4)',
  // Sombra suave del marcador del mapa, la única sombra del sistema.
  markerShadow: 'rgba(15, 42, 46, 0.35)',

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
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  // Separación en listas densas.
  blockDense: 12,
  // Separación entre bloques.
  block: 16,
  // Separación entre los pasos de la escalera de avisos.
  ladder: 6,
  md: 16,
  lg: 20,
  xl: 24,
  // Entrada: sobre los botones y sobre la tarjeta de funciones.
  xxl: 32,
  xxxl: 40,
  // Márgenes laterales de toda pantalla móvil.
  margin: 20,
} as const;

export const radius = {
  // Muestra de color de la leyenda de los gráficos del panel.
  legend: 2,
  // Esquina de las barras de gráficos y de la burbuja junto a quien la envía.
  sm: 4,
  badge: 6,
  navItem: 8,
  iconBox: 10,
  // Botones, campos y tarjetas.
  md: 12,
  iconBoxLg: 14,
  // Tarjetas grandes, mapa y borde superior de la barra inferior.
  lg: 16,
  // Chips y avatar.
  full: 9999,
  // Logo de 32 px y de 64 px.
  logo: 9,
  logoLg: 18,
} as const;

export const sizes = {
  button: 52,
  buttonTertiary: 48,
  input: 52,
  textArea: 96,
  headerBar: 56,
  tabBar: 64,
  logo: 32,
  logoLg: 64,
  iconBox: 40,
  iconBoxLg: 56,
  avatar: 36,
  avatarLg: 56,
  badge: 24,
  badgeDot: 6,
  chip: 36,
  // Alto de cada opción del control segmentado.
  segment: 40,
  progress: 6,
  switchWidth: 44,
  switchHeight: 26,
  switchKnob: 20,
  checkbox: 22,
  radio: 22,
  // Borde de la casilla, del radio y de los puntos pendientes de la línea de tiempo.
  controlBorder: 2,
  // Anillo del radio marcado y del paso actual de la línea de tiempo.
  ring: 6,
  // Línea de tiempo: punto, trazo y alto mínimo de cada paso.
  timelineDot: 22,
  timelineLine: 2,
  timelineStep: 52,
  ladderNumber: 28,
  icon: 24,
  iconSm: 20,
  iconXs: 16,
  // Burbujas de mensaje: ancho máximo.
  bubbleWidth: '84%',
  borderWidth: 1,
  focusBorderWidth: 1.5,
  // Medidas de pantallas que se rehacen en las etapas 2 a 4.
  // Entrada: espacio sobre el logo, debajo del área segura.
  entryTop: 56,
  qr: 168,
  suggestionChip: 32,
  chatInput: 40,
  sliderThumb: 22,
  sliderThumbBorder: 3,
  sliderTouch: 44,
  evidencePhoto: 150,
  // Miniaturas de la foto simulada: tarjetas de reclamo y envío (64) y seguimiento (72).
  photoThumb: 64,
  photoThumbLg: 72,
  workPhoto: 170,
  fundingBar: 12,
  legendDot: 10,
  noticeStep: 56,
  // Mapa móvil y marcador del mapa (MAPA.md).
  mapHeight: 300,
  // Minimapa de Nuevo reclamo (pantalla 16).
  miniMap: 120,
  mapMarker: 28,
  mapMarkerBorder: 2,
} as const;

// "Texto más grande" de Mi perfil (pantalla 21) multiplica letra e interlineado.
export const largeTextScale = 1.2;

// Solo Inter. Los montos y tablas usan cifras tabulares.
export const fontFamily = 'Inter';

export type EstiloTexto = {
  fontSize: number;
  fontWeight: '400' | '500' | '600' | '700';
  lineHeight: number;
  letterSpacing?: number;
  textTransform?: 'uppercase';
};

export const typography = {
  displayCurrency: { fontSize: 32, fontWeight: '700', lineHeight: 38, letterSpacing: -0.64 },
  brand: { fontSize: 36, fontWeight: '700', lineHeight: 44, letterSpacing: -0.72 },
  headlineLg: { fontSize: 24, fontWeight: '700', lineHeight: 32, letterSpacing: -0.24 },
  headlineMd: { fontSize: 20, fontWeight: '600', lineHeight: 28 },
  headlineSm: { fontSize: 18, fontWeight: '600', lineHeight: 24 },
  bodyLg: { fontSize: 16, fontWeight: '400', lineHeight: 24 },
  bodyLgMedium: { fontSize: 16, fontWeight: '500', lineHeight: 24 },
  bodyMd: { fontSize: 14, fontWeight: '400', lineHeight: 20 },
  bodyMdMedium: { fontSize: 14, fontWeight: '500', lineHeight: 20 },
  button: { fontSize: 16, fontWeight: '600', lineHeight: 20 },
  labelSm: { fontSize: 12, fontWeight: '600', lineHeight: 16, letterSpacing: 0.24 },
  overline: {
    fontSize: 12,
    fontWeight: '600',
    lineHeight: 16,
    letterSpacing: 0.72,
    textTransform: 'uppercase',
  },
  caption: { fontSize: 12, fontWeight: '400', lineHeight: 16 },
  tabLabel: { fontSize: 11, fontWeight: '500', lineHeight: 14 },
  // Complementos de LEEME.md → Componentes: título del Destacado y fila "Total",
  // monto de la fila "Total" y rótulo "ALMIRA" de la barra superior.
  titleSm: { fontSize: 16, fontWeight: '600', lineHeight: 22 },
  totalAmount: { fontSize: 18, fontWeight: '700', lineHeight: 24 },
  brandOverline: {
    fontSize: 11,
    fontWeight: '600',
    lineHeight: 14,
    letterSpacing: 0.88,
    textTransform: 'uppercase',
  },
} as const satisfies Record<string, EstiloTexto>;

// Medidas del panel web (LEEME.md → Panel web). Los radios, insignias, interruptor y
// escalera son los mismos de la app (radius y sizes).
export const panelSizes = {
  // Barra lateral blanca: ancho, relleno y alto de cada módulo.
  sidebar: 248,
  sidebarX: 12,
  sidebarY: 20,
  // Relleno extra de la marca y del usuario respecto de los módulos.
  sidebarBrandX: 10,
  navItem: 40,
  navGap: 4,
  navIcon: 20,
  navBadge: 20,
  // Contenido: márgenes, separación entre tarjetas y relleno interior.
  contentX: 28,
  contentY: 24,
  gap: 16,
  cardPaddingX: 20,
  cardPaddingY: 18,
  // Botones de 40 px (pequeños, 32) y chips de filtro de 32.
  button: 40,
  buttonSm: 32,
  chip: 32,
  // Medidas de páginas que se rehacen en la etapa 5.
  decisionColumn: 460,
  kpiHeight: 113,
  tableRow: 46,
  tableRowTall: 59,
  barChart: 112,
  hBarLabel: 138,
  hBarValue: 94,
  hBar: 12,
  hBarRow: 31,
  decisionIcon: 40,
  decisionRow: 63,
  rowButtonWide: 184,
  progressWide: 148,
  loginCard: 400,
  loginHeader: 56,
  loginTop: 258,
  // Mapa "Vista del vecino" de Obras publicadas (web-06).
  neighborMapWidth: 380,
  neighborMapHeight: 320,
  // Marca y usuario de la barra lateral: relleno arriba y abajo de la marca, y sobre el usuario.
  sidebarBrandTop: 2,
  sidebarBrandBottom: 18,
  sidebarFooterTop: 14,
  // Columna del detalle del reclamo (web-05) y de la columna de avance de obras (web-06).
  detailColumn: 400,
  progressColumn: 170,
  // Tablas: celdas, encabezado y relleno de la tarjeta que solo lleva una tabla.
  tableCellX: 12,
  tableCellY: 12,
  tableHeadY: 10,
  tableCardX: 8,
  tableCardY: 6,
  // Barras verticales: alto total, espacio para la cifra, separación y ancho máximo.
  barChartHeight: 170,
  barChartTop: 22,
  barGap: 14,
  barMaxWidth: 72,
  // Barras horizontales: riel, alto de fila, ancho del nombre y de la cifra.
  hBarTrack: 10,
  hBarRowSm: 30,
  hBarRowMd: 36,
  hBarRowLg: 38,
  hBarLabelSm: 120,
  hBarLabelMd: 140,
  hBarLabelLg: 160,
  hBarLabelXl: 170,
  hBarValueSm: 48,
  hBarValueMd: 56,
  hBarValueLg: 70,
  hBarValueXl: 80,
  // Ingreso (web-01): relleno y separación de la tarjeta, y separación de cada campo.
  loginCardPadding: 28,
  loginCardGap: 18,
  fieldGap: 6,
  // Separaciones internas: ícono y texto de notas, escalones y pasos del incidente (10);
  // celdas del ciclo, descripción del reclamo y alerta activa (14).
  innerGap: 10,
  cellX: 14,
  // Ícono dentro de textos (origen de un caso) y separación entre título y fecha del reclamo.
  inlineIcon: 18,
  tightGap: 2,
} as const;

// Textos del panel web, todos en Inter.
export const panelTypography = {
  brand: { fontSize: 16, fontWeight: '700', lineHeight: 20 },
  title: { fontSize: 24, fontWeight: '700', lineHeight: 30, letterSpacing: -0.24 },
  cardTitle: { fontSize: 16, fontWeight: '600', lineHeight: 22 },
  kpi: { fontSize: 28, fontWeight: '700', lineHeight: 34, letterSpacing: -0.28 },
  loginTitle: { fontSize: 18, fontWeight: '600', lineHeight: 24 },
  nav: { fontSize: 14, fontWeight: '500', lineHeight: 20 },
  navActive: { fontSize: 14, fontWeight: '600', lineHeight: 20 },
  subtitle: { fontSize: 14, fontWeight: '400', lineHeight: 20 },
  body: { fontSize: 13, fontWeight: '400', lineHeight: 18 },
  bodyMedium: { fontSize: 13, fontWeight: '500', lineHeight: 18 },
  bodyStrong: { fontSize: 13, fontWeight: '600', lineHeight: 18 },
  button: { fontSize: 14, fontWeight: '600', lineHeight: 20 },
  buttonSm: { fontSize: 13, fontWeight: '600', lineHeight: 18 },
  small: { fontSize: 12, fontWeight: '400', lineHeight: 16 },
  smallStrong: { fontSize: 12, fontWeight: '600', lineHeight: 16 },
  tableHead: {
    fontSize: 11,
    fontWeight: '600',
    lineHeight: 16,
    letterSpacing: 0.66,
    textTransform: 'uppercase',
  },
  // "Almira" en el ingreso, títulos de 18 px (ingreso y detalle del reclamo) y filas de 14 px 500.
  loginBrand: { fontSize: 22, fontWeight: '700', lineHeight: 28, letterSpacing: -0.22 },
  heading: { fontSize: 18, fontWeight: '600', lineHeight: 24 },
  rowTitle: { fontSize: 14, fontWeight: '500', lineHeight: 20 },
  // Título de los principios de Datos y accesos (web-09).
  principleTitle: { fontSize: 16, fontWeight: '500', lineHeight: 24 },
  // Rótulos "1 · RECUERDA" del ciclo y de la ruta del incidente.
  label: { fontSize: 12, fontWeight: '600', lineHeight: 16, letterSpacing: 0.24 },
  // Campo y botón del ingreso, con las medidas de la app.
  input: { fontSize: 16, fontWeight: '400', lineHeight: 24 },
  buttonLg: { fontSize: 16, fontWeight: '600', lineHeight: 20 },
} as const satisfies Record<string, EstiloTexto>;

export const tokens = {
  colors,
  spacing,
  radius,
  sizes,
  fontFamily,
  typography,
  panelSizes,
  panelTypography,
} as const;
