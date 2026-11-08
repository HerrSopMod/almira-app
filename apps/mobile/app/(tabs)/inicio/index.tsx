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
import { MaterialIcons } from '@expo/vector-icons';
import { router, type Href } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChipPlazo, CajaIcono, PiePrototipo, Avance, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

type Acceso = {
  titulo: string;
  icono: keyof typeof MaterialIcons.glyphMap;
  destino: Href;
};

const ACCESOS: Acceso[][] = [
  [
    { titulo: 'Mi cuenta', icono: 'payments', destino: '/cuenta' },
    { titulo: 'Avisos', icono: 'notifications-none', destino: '/inicio/recordatorios' },
  ],
  [
    { titulo: 'Asistente', icono: 'smart-toy', destino: '/asistente' },
    { titulo: 'Reclamos', icono: 'photo-camera', destino: '/reclamos' },
  ],
  [
    { titulo: 'Obras', icono: 'construction', destino: '/obras' },
    { titulo: 'Mi perfil', icono: 'person-outline', destino: '/inicio/perfil' },
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
      separacion="blockDense"
      encabezado={<BarraSuperior variante="raiz" titulo="Inicio" />}
    >
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Ver detalle y pagar"
        onPress={() => router.navigate('/cuenta')}
        style={estilos.deuda}
      >
        <Texto>Deuda pendiente</Texto>
        <Texto variante="displayCurrency" color={colors.primary} tabular>
          {formatearSoles(total)}
        </Texto>
        <Texto variante="bodyLgMedium" color={colors.header}>
          Ver detalle y pagar ›
        </Texto>
      </Pressable>

      {arbitrioPorVencer ? (
        <Pressable
          accessibilityRole="button"
          onPress={() => router.push('/inicio/recordatorios')}
          style={estilos.aviso}
        >
          <MaterialIcons name="notifications-none" size={20} color={colors.header} />
          <Texto variante="bodyLgMedium" color={colors.header} style={estilos.flexible}>
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
                <MaterialIcons name={icono} size={26} color={colors.primary} />
                <Texto variante="bodyMdMedium">{titulo}</Texto>
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
                <Texto variante="bodyLgMedium" style={estilos.flexible}>
                  {obra.nombre}
                </Texto>
                <Texto variante="bodyLgMedium" alineacion="right" tabular>
                  {obra.avancePct} %
                </Texto>
              </View>
            </View>
            <Avance porcentaje={obra.avancePct} />
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
              <CajaIcono icono="photo-camera" />
              <View style={estilos.flexible}>
                <Texto variante="bodyLgMedium">{reclamo.titulo}</Texto>
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
    gap: spacing.blockDense,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.blockDense,
    borderWidth: sizes.borderWidth,
    borderColor: colors.primary,
    borderRadius: radius.md,
    backgroundColor: colors.backgroundPink,
  },
  accesos: { gap: spacing.blockDense },
  filaAccesos: { flexDirection: 'row', gap: spacing.blockDense },
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
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  flexible: { flex: 1 },
});
