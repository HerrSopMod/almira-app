import {
  colors,
  ETIQUETA_ESTADO_DEUDA,
  ETIQUETA_ESTADO_OBRA,
  formatearSoles,
  radius,
  sizes,
  spacing,
  type EstadoDeuda,
  type EstadoObra,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import type { ReactNode } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { Texto } from './Texto';

export type NombreIcono = keyof typeof MaterialIcons.glyphMap;

// Tarjeta blanca con borde (LEEME.md → Tarjeta). Para agrupar filas, usa una sola
// tarjeta con <Separador />; nunca tarjetas dentro de tarjetas.
export function Tarjeta({
  children,
  grande,
  style,
}: {
  children: ReactNode;
  grande?: boolean;
  style?: StyleProp<ViewStyle>;
}) {
  return <View style={[estilos.tarjeta, grande && estilos.tarjetaGrande, style]}>{children}</View>;
}

export function Separador() {
  return <View style={estilos.separador} />;
}

// Bloque Destacado: lo más importante de la pantalla. Máximo uno por pantalla.
export function Destacado({
  titulo,
  texto,
  icono = 'info-outline',
  children,
}: {
  titulo?: string;
  texto?: string;
  // null cuando el contenido trae su propio diseño, como la deuda de Inicio.
  icono?: NombreIcono | null;
  children?: ReactNode;
}) {
  return (
    <View style={estilos.destacado}>
      {icono ? <MaterialIcons name={icono} size={sizes.icon} color={colors.primary} /> : null}
      <View style={[estilos.flexible, estilos.textosDestacado]}>
        {titulo ? (
          <Texto variante="titleSm" color={colors.primaryPressed}>
            {titulo}
          </Texto>
        ) : null}
        {texto ? <Texto variante="bodyMd">{texto}</Texto> : null}
        {children}
      </View>
    </View>
  );
}

// Nota sin fondo para avisos legales, explicaciones y "Datos de ejemplo".
export function Nota({
  texto,
  icono = 'info-outline',
  conBorde,
}: {
  texto: string;
  icono?: NombreIcono;
  conBorde?: boolean;
}) {
  return (
    <View style={[estilos.nota, conBorde && estilos.notaConBorde]}>
      <MaterialIcons name={icono} size={sizes.iconSm} color={colors.textSecondary} />
      <Texto variante="bodyMd" color={colors.textSecondary} style={estilos.flexible}>
        {texto}
      </Texto>
    </View>
  );
}

export type TonoInsignia = 'ok' | 'warn' | 'bad' | 'info' | 'neutral';

// Fondo, texto (contraste AA) y punto de cada insignia. La neutral no lleva punto.
const COLORES_INSIGNIA: Record<TonoInsignia, { fondo: string; texto: string; punto?: string }> = {
  ok: { fondo: colors.successSoft, texto: colors.successText, punto: colors.success },
  warn: { fondo: colors.warningSoft, texto: colors.warningText, punto: colors.warning },
  bad: { fondo: colors.dangerSoft, texto: colors.dangerText, punto: colors.danger },
  info: { fondo: colors.highlight, texto: colors.primaryPressed, punto: colors.primary },
  neutral: { fondo: colors.subtle, texto: colors.textSecondary },
};

export function Insignia({
  texto,
  tono,
  centrada,
}: {
  texto: string;
  tono: TonoInsignia;
  // Por defecto se pega a la izquierda; centrada, en columnas centradas.
  centrada?: boolean;
}) {
  const { fondo, texto: color, punto } = COLORES_INSIGNIA[tono];
  return (
    <View
      style={[estilos.insignia, centrada && estilos.insigniaCentrada, { backgroundColor: fondo }]}
    >
      {punto ? <View style={[estilos.punto, { backgroundColor: punto }]} /> : null}
      <Texto variante="labelSm" color={color} numberOfLines={1}>
        {texto}
      </Texto>
    </View>
  );
}

const TONO_ESTADO_DEUDA: Record<EstadoDeuda, TonoInsignia> = {
  vencida: 'bad',
  vigente: 'warn',
  pagada: 'ok',
};

// «En mora», «Por vencer» y «Pagada».
export function ChipEstadoDeuda({ estado }: { estado: EstadoDeuda }) {
  return <Insignia texto={ETIQUETA_ESTADO_DEUDA[estado]} tono={TONO_ESTADO_DEUDA[estado]} />;
}

// «En ejecución» (info) o «Concluida» (ok), como en las maquetas 19 y 20.
export function ChipEstadoObra({ estado }: { estado: EstadoObra }) {
  return (
    <Insignia
      texto={ETIQUETA_ESTADO_OBRA[estado]}
      tono={estado === 'finalizada' ? 'ok' : 'info'}
    />
  );
}

// Plazo de un reclamo («Quedan 3 d») o «Resuelto».
export function ChipPlazo({ texto, tono = 'plazo' }: { texto: string; tono?: 'plazo' | 'resuelto' }) {
  return <Insignia texto={texto} tono={tono === 'resuelto' ? 'ok' : 'warn'} />;
}

// Caja de 40 px (56 la grande) con un ícono primario sobre fondo suave. La variante
// "exito" es para un estado logrado, como un pago confirmado.
export function CajaIcono({
  icono,
  grande,
  redonda,
  tono = 'normal',
}: {
  icono: NombreIcono;
  grande?: boolean;
  redonda?: boolean;
  tono?: 'normal' | 'exito';
}) {
  const lado = grande ? sizes.iconBoxLg : sizes.iconBox;
  return (
    <View
      style={[
        estilos.cajaIcono,
        {
          width: lado,
          height: lado,
          borderRadius: redonda ? lado / 2 : grande ? radius.iconBoxLg : radius.iconBox,
        },
        tono === 'exito' && estilos.cajaIconoExito,
      ]}
    >
      <MaterialIcons
        name={icono}
        size={sizes.icon}
        color={tono === 'exito' ? colors.successText : colors.primary}
      />
    </View>
  );
}

// Barra de avance: riel de 6 px con relleno acento, o verde si la obra está concluida.
export function Avance({
  porcentaje,
  tono = 'acento',
}: {
  porcentaje: number;
  tono?: 'acento' | 'concluida';
}) {
  return (
    <View
      accessibilityRole="progressbar"
      accessibilityValue={{ min: 0, max: 100, now: Math.round(porcentaje) }}
      style={estilos.avance}
    >
      <View
        style={[
          estilos.avanceRelleno,
          { width: `${porcentaje}%` },
          tono === 'concluida' && estilos.avanceConcluida,
        ]}
      />
    </View>
  );
}

export function Monto({ valor, grande }: { valor: number; grande?: boolean }) {
  return (
    <Texto variante={grande ? 'displayCurrency' : 'headlineSm'} alineacion="right" tabular>
      {formatearSoles(valor)}
    </Texto>
  );
}

// Fila clave–valor: etiqueta a la izquierda y valor a la derecha con cifras tabulares.
// La fila "Total" va en 16 px y su monto en 18 px 700.
export function FilaDato({
  etiqueta,
  valor,
  total,
}: {
  etiqueta: string;
  valor: ReactNode;
  total?: boolean;
}) {
  return (
    <View style={estilos.filaDato}>
      <Texto
        variante={total ? 'titleSm' : 'bodyMd'}
        color={total ? colors.text : colors.textSecondary}
        style={estilos.flexible}
      >
        {etiqueta}
      </Texto>
      {typeof valor === 'string' ? (
        <Texto
          variante={total ? 'totalAmount' : 'bodyMdMedium'}
          alineacion="right"
          tabular
          style={estilos.valor}
        >
          {valor}
        </Texto>
      ) : (
        valor
      )}
    </View>
  );
}

// Título de pantalla (24 px) con un texto de apoyo opcional, debajo de la barra superior.
export function TituloPantalla({ titulo, texto }: { titulo: string; texto?: string }) {
  return (
    <View style={estilos.titulo}>
      <Texto variante="headlineLg" accessibilityRole="header">
        {titulo}
      </Texto>
      {texto ? <Texto color={colors.textSecondary}>{texto}</Texto> : null}
    </View>
  );
}

// Encabezado de sección en mayúsculas ("AUTORIZA LO QUE QUIERAS USAR").
export function Rotulo({ texto }: { texto: string }) {
  return (
    <Texto variante="overline" color={colors.textSecondary} accessibilityRole="header">
      {texto}
    </Texto>
  );
}

// Ya no muestra el aviso de prototipo; queda como componente vacío para no tocar las 20 pantallas que lo usan.
export function PiePrototipo() {
  return null;
}

export function Vacio({ texto }: { texto: string }) {
  return (
    <Tarjeta>
      <Texto variante="bodyLg" color={colors.textSecondary} alineacion="center">
        {texto}
      </Texto>
    </Tarjeta>
  );
}

const estilos = StyleSheet.create({
  tarjeta: {
    backgroundColor: colors.surface,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
    padding: spacing.md,
    gap: spacing.md,
  },
  tarjetaGrande: { borderRadius: radius.lg, padding: spacing.lg },
  separador: { height: sizes.borderWidth, backgroundColor: colors.border },
  destacado: {
    flexDirection: 'row',
    gap: spacing.blockDense,
    padding: spacing.md,
    borderRadius: radius.md,
    backgroundColor: colors.highlight,
  },
  textosDestacado: { gap: spacing.xs },
  titulo: { gap: spacing.sm },
  flexible: { flex: 1 },
  nota: { flexDirection: 'row', gap: spacing.sm },
  notaConBorde: {
    padding: spacing.blockDense,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  insignia: {
    alignSelf: 'flex-start',
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    minHeight: sizes.badge,
    paddingHorizontal: spacing.sm,
    borderRadius: radius.badge,
  },
  insigniaCentrada: { alignSelf: 'center' },
  punto: { width: sizes.badgeDot, height: sizes.badgeDot, borderRadius: sizes.badgeDot / 2 },
  cajaIcono: { alignItems: 'center', justifyContent: 'center', backgroundColor: colors.subtle },
  cajaIconoExito: { backgroundColor: colors.successSoft },
  avance: {
    height: sizes.progress,
    borderRadius: radius.full,
    backgroundColor: colors.track,
    overflow: 'hidden',
  },
  avanceRelleno: { height: '100%', borderRadius: radius.full, backgroundColor: colors.accent },
  avanceConcluida: { backgroundColor: colors.success },
  filaDato: { flexDirection: 'row', alignItems: 'baseline', gap: spacing.blockDense },
  valor: { flexShrink: 1 },
});
