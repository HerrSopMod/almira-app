import { colors, iniciales, sizes, spacing, USUARIO_EJEMPLO } from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useDatosMunicipales } from '@/sesion';
import { Logo } from './Logo';
import { Texto } from './Texto';

type Props =
  | {
      // Raíz de pestaña: logo, "ALMIRA" sobre el nombre de la pestaña, campana y avatar.
      variante: 'raiz';
      titulo: string;
    }
  | {
      // Detalle: flecha atrás y título a la izquierda.
      variante?: 'detalle';
      titulo: string;
      conVolver?: boolean;
      // Acción opcional a la derecha.
      accion?: ReactNode;
      // "Paso N de M", en lugar de la acción.
      paso?: string;
    };

// Si no hay a dónde volver (por ejemplo, una pantalla abierta directo), va a Inicio.
function volver() {
  if (router.canGoBack()) router.back();
  else router.navigate('/inicio');
}

// Barra superior blanca con línea inferior (LEEME.md → Barra superior).
// Úsala con <Pantalla encabezadoHastaArriba> para que también cubra el área de la hora.
export function BarraSuperior(props: Props) {
  const { top } = useSafeAreaInsets();
  return (
    <View style={[estilos.raiz, { paddingTop: top }]}>
      <StatusBar style="dark" />
      {props.variante === 'raiz' ? <FilaRaiz titulo={props.titulo} /> : <FilaDetalle {...props} />}
    </View>
  );
}

function FilaRaiz({ titulo }: { titulo: string }) {
  const { vecino } = useDatosMunicipales();
  return (
    <View style={[estilos.fila, estilos.filaRaiz]}>
      <Logo />
      <View style={estilos.flexible}>
        <Texto variante="brandOverline" color={colors.primary}>
          Almira
        </Texto>
        <Texto variante="headlineSm" accessibilityRole="header" numberOfLines={1}>
          {titulo}
        </Texto>
      </View>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Recordatorios"
        onPress={() => router.push('/inicio/recordatorios')}
        style={estilos.botonIcono}
      >
        <MaterialIcons name="notifications-none" size={sizes.icon} color={colors.text} />
      </Pressable>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Mi perfil"
        hitSlop={(sizes.buttonTertiary - sizes.avatar) / 2}
        onPress={() => router.push('/inicio/perfil')}
        style={estilos.avatar}
      >
        <Texto variante="bodyMdMedium" peso="600" color={colors.onPrimary}>
          {iniciales(vecino?.nombre ?? USUARIO_EJEMPLO.nombre)}
        </Texto>
      </Pressable>
    </View>
  );
}

function FilaDetalle({
  titulo,
  conVolver = true,
  accion,
  paso,
}: Extract<Props, { variante?: 'detalle' }>) {
  return (
    <View style={[estilos.fila, !conVolver && estilos.filaSinVolver]}>
      {conVolver ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Volver"
          onPress={volver}
          style={estilos.botonIcono}
        >
          <MaterialIcons name="arrow-back" size={sizes.icon} color={colors.text} />
        </Pressable>
      ) : null}
      <Texto
        variante="headlineSm"
        accessibilityRole="header"
        numberOfLines={1}
        style={estilos.flexible}
      >
        {titulo}
      </Texto>
      {accion ?? null}
      {!accion && paso ? (
        <Texto variante="caption" color={colors.textSecondary}>
          {paso}
        </Texto>
      ) : null}
    </View>
  );
}

const estilos = StyleSheet.create({
  raiz: {
    backgroundColor: colors.surface,
    borderBottomWidth: sizes.borderWidth,
    borderBottomColor: colors.border,
  },
  fila: {
    height: sizes.headerBar,
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    paddingLeft: spacing.xs,
    paddingRight: spacing.blockDense,
  },
  filaRaiz: { gap: spacing.sm, paddingLeft: spacing.margin },
  filaSinVolver: { paddingLeft: spacing.margin },
  flexible: { flex: 1 },
  botonIcono: {
    width: sizes.buttonTertiary,
    height: sizes.buttonTertiary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatar: {
    width: sizes.avatar,
    height: sizes.avatar,
    borderRadius: sizes.avatar / 2,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primary,
  },
});
