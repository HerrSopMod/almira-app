import {
  colors,
  deudasPendientes,
  deudasSeleccionadas,
  formatearFechaCorta,
  formatearSoles,
  HOY_EJEMPLO,
  sizes,
  spacing,
  textoVencimiento,
  totalDeuda,
  totalSeleccionado,
  type Deuda,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Fragment, useEffect, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import {
  CajaIcono,
  ChipEstadoDeuda,
  FilaDato,
  Nota,
  Separador,
  Tarjeta,
  TituloPantalla,
  Vacio,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Casilla } from '@/components/Casilla';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// La casilla dibuja 22 px; su zona de toque llega a 48.
const HOLGURA_CASILLA = (sizes.buttonTertiary - sizes.checkbox) / 2;

// Pantalla 05, pestaña Pagar (Stitch 7, parte superior).
export default function Pagar() {
  const { municipalidad, deudas, pagos } = useDatosMunicipales();
  const pendientes = deudasPendientes(deudas);
  const idsPendientes = pendientes.map((deuda) => deuda.id).join(',');
  // Todas las deudas pendientes empiezan marcadas.
  const [marcadas, setMarcadas] = useState<string[]>(() => pendientes.map((deuda) => deuda.id));
  // Si cambian las pendientes (por ejemplo, tras un pago), se vuelven a marcar todas.
  useEffect(() => setMarcadas(idsPendientes ? idsPendientes.split(',') : []), [idsPendientes]);

  const elegidas = deudasSeleccionadas(deudas, marcadas);
  const total = totalSeleccionado(deudas, marcadas);

  const alternar = (id: string) =>
    setMarcadas((actual) =>
      actual.includes(id) ? actual.filter((otra) => otra !== id) : [...actual, id],
    );

  const pagar = () =>
    router.push({
      pathname: '/pago/confirmar',
      params: { deudas: elegidas.map((deuda) => deuda.id).join(',') },
    });

  const pie =
    pendientes.length > 0 ? (
      <>
        <FilaDato
          total
          etiqueta={`Total seleccionado (${elegidas.length})`}
          valor={formatearSoles(total)}
        />
        <Boton
          icono="lock-outline"
          titulo={`Pagar ${formatearSoles(total)}`}
          deshabilitado={elegidas.length === 0}
          onPress={pagar}
        />
      </>
    ) : undefined;

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      encabezado={<BarraSuperior variante="raiz" titulo="Pagar" />}
      pie={pie}
    >
      <TituloPantalla titulo="Mi cuenta municipal" texto={municipalidad.nombre} />

      <View style={estilos.grupo}>
        <View style={estilos.fila}>
          <Texto variante="headlineSm" accessibilityRole="header" style={estilos.flexible}>
            Tributos pendientes
          </Texto>
          {pendientes.length > 0 ? (
            <Texto variante="bodyMd" color={colors.textSecondary}>
              {pendientes.length} {pendientes.length === 1 ? 'pendiente' : 'pendientes'}
            </Texto>
          ) : null}
        </View>
        {pendientes.length > 0 ? (
          <Tarjeta>
            {pendientes.map((deuda, indice) => (
              <Fragment key={deuda.id}>
                {indice > 0 ? <Separador /> : null}
                <FilaDeuda
                  deuda={deuda}
                  marcada={marcadas.includes(deuda.id)}
                  onAlternar={() => alternar(deuda.id)}
                />
              </Fragment>
            ))}
          </Tarjeta>
        ) : (
          <Vacio texto="No tienes deudas pendientes." />
        )}
      </View>

      {pagos.length > 0 ? (
        <View style={estilos.grupo}>
          <Texto variante="headlineSm" accessibilityRole="header">
            Pagos y constancias
          </Texto>
          <Tarjeta>
            {pagos.map((pago, indice) => {
              const deuda = deudas.find((fila) => fila.id === pago.deudaId);
              return (
                <Fragment key={pago.id}>
                  {indice > 0 ? <Separador /> : null}
                  <View style={estilos.fila}>
                    <CajaIcono icono="check" tono="exito" />
                    <View style={estilos.flexible}>
                      <Texto variante="bodyLgMedium">
                        {deuda ? `${deuda.concepto} · ${deuda.periodo}` : pago.referencia}
                      </Texto>
                      <Texto variante="bodyMd" color={colors.textSecondary} tabular>
                        {formatearFechaCorta(pago.creadoEn)} · {pago.referencia}
                      </Texto>
                    </View>
                    <Texto variante="bodyLgMedium" alineacion="right" tabular>
                      {formatearSoles(pago.monto)}
                    </Texto>
                  </View>
                </Fragment>
              );
            })}
          </Tarjeta>
        </View>
      ) : null}

    </Pantalla>
  );
}

// Casilla para marcar la deuda y, al tocar el resto de la fila, su detalle.
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
        accessibilityLabel={`Pagar ${deuda.concepto}, ${formatearSoles(totalDeuda(deuda))}`}
        hitSlop={HOLGURA_CASILLA}
        onPress={onAlternar}
      >
        <Casilla marcada={marcada} />
      </Pressable>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`Ver detalle de ${deuda.concepto}`}
        onPress={() => router.push(`/cuenta/deuda/${deuda.id}`)}
        style={[estilos.fila, estilos.flexible]}
      >
        <View style={[estilos.flexible, estilos.textosDeuda]}>
          <Texto variante="bodyLgMedium">{deuda.concepto}</Texto>
          <View style={estilos.fila}>
            <MaterialIcons name="event" size={sizes.iconXs} color={colors.textSecondary} />
            <Texto variante="bodyMd" color={colors.textSecondary} tabular>
              {textoVencimiento(deuda.vencimiento, HOY_EJEMPLO)}
            </Texto>
          </View>
          <ChipEstadoDeuda estado={deuda.estado} />
        </View>
        <Texto variante="bodyLgMedium" alineacion="right" tabular>
          {formatearSoles(totalDeuda(deuda))}
        </Texto>
        <MaterialIcons name="chevron-right" size={sizes.icon} color={colors.textSecondary} />
      </Pressable>
    </View>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.blockDense },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  flexible: { flex: 1 },
  textosDeuda: { gap: spacing.xs },
});
