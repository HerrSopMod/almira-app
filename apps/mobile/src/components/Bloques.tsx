import { colors, formatearSoles, radius, sizes, spacing } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { Texto } from './Texto';

export function Tarjeta({ children }: { children: ReactNode }) {
  return <View style={estilos.tarjeta}>{children}</View>;
}

export function Separador() {
  return <View style={estilos.separador} />;
}

// Tonos de los avisos: "primario" es el de siempre; "informacion" y "exito"
// siguen las pantallas 02 y 03 del prototipo.
type TonoDestacado = 'primario' | 'informacion' | 'exito';

const COLORES_DESTACADO: Record<TonoDestacado, { texto: string; fondo: string }> = {
  primario: { texto: colors.primary, fondo: colors.highlight },
  informacion: { texto: colors.header, fondo: colors.backgroundPink },
  exito: { texto: colors.paidText, fondo: colors.paidSoft },
};

// DESIGN.md: como máximo uno por pantalla.
export function Destacado({
  titulo,
  texto,
  icono = 'info-outline',
  tono = 'primario',
}: {
  titulo?: string;
  texto: string;
  icono?: keyof typeof MaterialIcons.glyphMap;
  tono?: TonoDestacado;
}) {
  const { texto: color, fondo } = COLORES_DESTACADO[tono];
  return (
    <View style={[estilos.destacado, { backgroundColor: fondo }]}>
      <MaterialIcons name={icono} size={24} color={color} />
      <View style={estilos.flexible}>
        {titulo ? (
          <Texto variante="bodyLgMedium" color={color}>
            {titulo}
          </Texto>
        ) : null}
        <Texto variante="bodyMd" color={color}>
          {texto}
        </Texto>
      </View>
    </View>
  );
}

export type Tono = 'exito' | 'atencion' | 'critico';

const COLORES_TONO: Record<Tono, { texto: string; fondo: string }> = {
  exito: { texto: colors.success, fondo: colors.successSoft },
  atencion: { texto: colors.warning, fondo: colors.warningSoft },
  critico: { texto: colors.danger, fondo: colors.dangerSoft },
};

export function Insignia({ texto, tono }: { texto: string; tono: Tono }) {
  const { texto: color, fondo } = COLORES_TONO[tono];
  return (
    <View style={[estilos.insignia, { backgroundColor: fondo }]}>
      <Texto variante="labelSm" color={color}>
        {texto}
      </Texto>
    </View>
  );
}

export function Progreso({ porcentaje }: { porcentaje: number }) {
  return (
    <View
      accessibilityRole="progressbar"
      accessibilityValue={{ min: 0, max: 100, now: porcentaje }}
      style={estilos.progreso}
    >
      <View style={[estilos.progresoRelleno, { width: `${porcentaje}%` }]} />
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

export function FilaDato({ etiqueta, valor }: { etiqueta: string; valor: ReactNode }) {
  return (
    <View style={estilos.filaDato}>
      <Texto variante="bodyMd" color={colors.textSecondary} style={estilos.flexible}>
        {etiqueta}
      </Texto>
      {typeof valor === 'string' ? <Texto variante="bodyLgMedium">{valor}</Texto> : valor}
    </View>
  );
}

export function PiePrototipo() {
  return (
    <Texto variante="caption" color={colors.textSecondary} alineacion="center">
      Prototipo académico · Datos ficticios
    </Texto>
  );
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
  separador: { height: 1, backgroundColor: colors.border },
  destacado: {
    flexDirection: 'row',
    gap: spacing.md,
    padding: spacing.md,
    borderRadius: radius.md,
  },
  flexible: { flex: 1 },
  insignia: {
    alignSelf: 'flex-start',
    height: sizes.badge,
    paddingHorizontal: spacing.sm,
    borderRadius: radius.badge,
    justifyContent: 'center',
  },
  progreso: {
    height: sizes.progress,
    borderRadius: radius.full,
    backgroundColor: colors.border,
    overflow: 'hidden',
  },
  progresoRelleno: { height: '100%', borderRadius: radius.full, backgroundColor: colors.accent },
  filaDato: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
});
