import {
  colors,
  deudasPendientes,
  formatearFechaCorta,
  formatearSoles,
  radius,
  sizes,
  spacing,
  sumarDeudas,
  totalDeuda,
  type Deuda,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChipEstadoDeuda, CajaIcono, PiePrototipo, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 05 del prototipo.
export default function MiCuenta() {
  const { deudas, pagos } = useDatosMunicipales();
  const pendientes = deudasPendientes(deudas);
  // Todas las deudas pendientes empiezan marcadas; se guardan las que el vecino desmarca.
  const [desmarcadas, setDesmarcadas] = useState<string[]>([]);
  const elegidas = pendientes.filter((deuda) => !desmarcadas.includes(deuda.id));

  const alternar = (id: string) =>
    setDesmarcadas((actual) =>
      actual.includes(id) ? actual.filter((otra) => otra !== id) : [...actual, id],
    );

  const pagar = () =>
    router.push({
      pathname: '/pago/confirmar',
      params: { deudas: elegidas.map((deuda) => deuda.id).join(',') },
    });

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      separacion="md"
      encabezado={<BarraSuperior variante="raiz" titulo="Pagar" />}
    >
      <Texto variante="headlineSm" color={colors.primary} accessibilityRole="header">
        Detalle de la deuda
      </Texto>

      <View style={estilos.lista}>
        {pendientes.map((deuda) => (
          <FilaDeuda
            key={deuda.id}
            deuda={deuda}
            marcada={!desmarcadas.includes(deuda.id)}
            onAlternar={() => alternar(deuda.id)}
          />
        ))}
      </View>

      <View style={estilos.total}>
        <Texto variante="headlineSm" style={estilos.flexible}>
          Total
        </Texto>
        <Texto variante="headlineSm" alineacion="right" tabular>
          {formatearSoles(sumarDeudas(elegidas))}
        </Texto>
      </View>

      <View style={estilos.beneficio}>
        <Texto alineacion="center">Beneficio vigente: consulta con el asistente</Texto>
      </View>

      <View style={estilos.pago}>
        <Boton titulo="Pagar en la app" deshabilitado={elegidas.length === 0} onPress={pagar} />
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
          Al pagar, la constancia queda en la app.
        </Texto>
      </View>

      <Texto variante="headlineSm" accessibilityRole="header" style={estilos.seccion}>
        Pagos y constancias
      </Texto>
      {pagos.map((pago) => {
        const deuda = deudas.find((fila) => fila.id === pago.deudaId);
        return (
          <Tarjeta key={pago.id}>
            <View style={estilos.fila}>
              <CajaIcono icono="check" tono="exito" />
              <View style={estilos.flexible}>
                <Texto variante="bodyLgMedium">
                  {deuda ? `${deuda.concepto} · ${deuda.periodo}` : pago.referencia}
                </Texto>
                <Texto variante="bodyMd" color={colors.textSecondary}>
                  {formatearFechaCorta(pago.creadoEn)} · {pago.referencia}
                </Texto>
              </View>
              <Texto variante="bodyLgMedium" alineacion="right" tabular>
                {formatearSoles(pago.monto)}
              </Texto>
            </View>
          </Tarjeta>
        );
      })}

      <PiePrototipo />
    </Pantalla>
  );
}

function FilaDeuda({
  deuda,
  marcada,
  onAlternar,
}: {
  deuda: Deuda;
  marcada: boolean;
  onAlternar: () => void;
}) {
  return (
    <View style={estilos.fila}>
      <Pressable
        accessibilityRole="checkbox"
        accessibilityState={{ checked: marcada }}
        accessibilityLabel={`Pagar ${deuda.concepto}`}
        hitSlop={12}
        onPress={onAlternar}
        style={[estilos.casilla, marcada && estilos.casillaMarcada]}
      >
        {marcada ? (
          <MaterialIcons name="check" size={16} color={colors.onPrimary} />
        ) : null}
      </Pressable>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`Ver detalle de ${deuda.concepto}`}
        onPress={() => router.push(`/cuenta/deuda/${deuda.id}`)}
        style={[estilos.fila, estilos.flexible]}
      >
        <View style={[estilos.flexible, estilos.textosDeuda]}>
          <Texto>{deuda.concepto}</Texto>
          <ChipEstadoDeuda estado={deuda.estado} />
        </View>
        <Texto variante="bodyLgMedium" alineacion="right" tabular>
          {formatearSoles(totalDeuda(deuda))}
        </Texto>
        <MaterialIcons name="chevron-right" size={24} color={colors.text} />
      </Pressable>
    </View>
  );
}

const estilos = StyleSheet.create({
  lista: { gap: spacing.lg },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  flexible: { flex: 1 },
  textosDeuda: { gap: spacing.xs },
  casilla: {
    width: sizes.checkbox,
    height: sizes.checkbox,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.badge,
    borderWidth: sizes.controlBorder,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  casillaMarcada: { borderColor: colors.primary, backgroundColor: colors.primary },
  total: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingTop: spacing.md,
    borderTopWidth: sizes.borderWidth,
    borderTopColor: colors.border,
  },
  beneficio: {
    padding: spacing.blockDense,
    borderRadius: radius.md,
    backgroundColor: colors.subtle,
  },
  pago: { gap: spacing.blockDense },
  seccion: { marginTop: spacing.sm },
});
