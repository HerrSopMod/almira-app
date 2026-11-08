import {
  colors,
  deudasPendientes,
  ETIQUETA_ESTADO_RECLAMO,
  formatearSoles,
  HOY_EJEMPLO,
  plazoReclamo,
  radius,
  sizes,
  spacing,
  sumarDeudas,
} from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router, type Href } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChipPlazo, IconoCuadro, PiePrototipo, Progreso, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

type Acceso = {
  titulo: string;
  icono: keyof typeof MaterialCommunityIcons.glyphMap;
  destino: Href;
};

const ACCESOS: Acceso[][] = [
  [
    { titulo: 'Mi cuenta', icono: 'wallet-outline', destino: '/cuenta' },
    { titulo: 'Avisos', icono: 'bell-outline', destino: '/inicio/recordatorios' },
  ],
  [
    { titulo: 'Asistente', icono: 'robot-outline', destino: '/asistente' },
    { titulo: 'Reclamos', icono: 'camera-outline', destino: '/reclamos' },
  ],
  [
    { titulo: 'Obras', icono: 'hard-hat', destino: '/obras' },
    { titulo: 'Mi perfil', icono: 'account-outline', destino: '/inicio/perfil' },
  ],
];

// Pantalla 04 del prototipo.
export default function Inicio() {
  const { deudas, obras, reclamos } = useDatosMunicipales();
  const pendientes = deudasPendientes(deudas);
  const total = sumarDeudas(pendientes);
  const arbitrioPorVencer = pendientes.some(
    (deuda) => deuda.tipo === 'arbitrios' && deuda.estado === 'vigente',
  );
  const obra = obras.find((fila) => fila.estado === 'en_ejecucion');
  const reclamo = reclamos.find((fila) => fila.estado !== 'resuelto');
  const plazo = reclamo ? plazoReclamo(reclamo, HOY_EJEMPLO)?.etiqueta : null;

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      separacion="block"
      encabezado={
        <BarraSuperior
          titulo="Almira · Inicio"
          conVolver={false}
          accion={
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Mi perfil"
              hitSlop={8}
              onPress={() => router.push('/inicio/perfil')}
            >
              <MaterialCommunityIcons name="account-outline" size={28} color={colors.onPrimary} />
            </Pressable>
          }
        />
      }
    >
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Ver detalle y pagar"
        onPress={() => router.navigate('/cuenta')}
        style={estilos.deuda}
      >
        <Texto>Deuda pendiente</Texto>
        <Texto variante="displayCurrency" fuente="poppins" color={colors.primary} tabular>
          {formatearSoles(total)}
        </Texto>
        <Texto variante="labelLg" color={colors.header}>
          Ver detalle y pagar ›
        </Texto>
      </Pressable>

      {arbitrioPorVencer ? (
        <Pressable
          accessibilityRole="button"
          onPress={() => router.push('/inicio/recordatorios')}
          style={estilos.aviso}
        >
          <MaterialCommunityIcons name="bell-outline" size={20} color={colors.header} />
          <Texto variante="labelLg" color={colors.header} style={estilos.flexible}>
            Aviso: tu arbitrio vence pronto
          </Texto>
        </Pressable>
      ) : null}

      <View style={estilos.accesos}>
        {ACCESOS.map((fila, indice) => (
          <View key={indice} style={estilos.filaAccesos}>
            {fila.map(({ titulo, icono, destino }) => (
              <Pressable
                key={titulo}
                accessibilityRole="button"
                onPress={() => router.navigate(destino)}
                style={estilos.acceso}
              >
                <MaterialCommunityIcons name={icono} size={26} color={colors.primary} />
                <Texto variante="label">{titulo}</Texto>
              </Pressable>
            ))}
          </View>
        ))}
      </View>

      {obra ? (
        <Pressable
          accessibilityRole="button"
          onPress={() => router.navigate({ pathname: '/obras/[id]', params: { id: obra.id } })}
        >
          <Tarjeta>
            <View style={estilos.obraTextos}>
              <Texto variante="bodyMd" color={colors.textSecondary}>
                En tu distrito
              </Texto>
              <View style={estilos.fila}>
                <Texto variante="labelLg" style={estilos.flexible}>
                  {obra.nombre}
                </Texto>
                <Texto variante="labelLg" alineacion="right" tabular>
                  {obra.avancePct} %
                </Texto>
              </View>
            </View>
            <Progreso porcentaje={obra.avancePct} />
          </Tarjeta>
        </Pressable>
      ) : null}

      {reclamo ? (
        <Pressable
          accessibilityRole="button"
          onPress={() =>
            router.navigate({ pathname: '/reclamos/[id]', params: { id: reclamo.id } })
          }
        >
          <Tarjeta>
            <View style={estilos.fila}>
              <IconoCuadro icono="camera-outline" />
              <View style={estilos.flexible}>
                <Texto variante="labelLg">{reclamo.titulo}</Texto>
                <Texto variante="bodyMd" color={colors.textSecondary}>
                  {ETIQUETA_ESTADO_RECLAMO[reclamo.estado]}
                  {reclamo.area ? ` · ${reclamo.area}` : ''}
                </Texto>
              </View>
              {plazo ? <ChipPlazo texto={plazo} /> : null}
            </View>
          </Tarjeta>
        </Pressable>
      ) : null}

      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  deuda: {
    gap: spacing.xs,
    padding: spacing.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.pendingDebtBorder,
    borderRadius: radius.lg,
    backgroundColor: colors.pendingDebt,
  },
  aviso: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.block,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.block,
    borderWidth: sizes.borderWidth,
    borderColor: colors.primary,
    borderRadius: radius.md,
    backgroundColor: colors.backgroundPink,
  },
  accesos: { gap: spacing.block },
  filaAccesos: { flexDirection: 'row', gap: spacing.block },
  acceso: {
    flex: 1,
    height: sizes.shortcut,
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.xs,
    borderWidth: sizes.borderWidth,
    borderColor: colors.primary,
    borderRadius: radius.md,
    backgroundColor: colors.surface,
  },
  obraTextos: { gap: spacing.xs },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.block },
  flexible: { flex: 1 },
});
