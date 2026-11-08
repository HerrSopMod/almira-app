import {
  colors,
  CUOTAS_INICIALES,
  CUOTAS_MAXIMAS,
  CUOTAS_MINIMAS,
  deudasASimular,
  formatearSoles,
  simularCuotas,
  spacing,
  type AlcanceSimulacion,
} from '@almira/shared';
import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, FilaDato, PiePrototipo, Separador, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Chips } from '@/components/Chips';
import { Deslizador } from '@/components/Deslizador';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

const ALCANCES: { valor: AlcanceSimulacion; titulo: string }[] = [
  { valor: 'mora', titulo: 'Solo en mora' },
  { valor: 'toda', titulo: 'Toda mi deuda' },
];

// Pantalla 13 del prototipo. La cuota es informativa: usa la tasa ilustrativa del
// prototipo y no envía nada a Rentas, que es quien evalúa y decide.
export default function SimulacionCuotas() {
  const { deudas } = useDatosMunicipales();
  const [alcance, setAlcance] = useState<AlcanceSimulacion>('toda');
  const [cuotas, setCuotas] = useState(CUOTAS_INICIALES);
  const [pedido, setPedido] = useState(false);

  const elegidas = deudasASimular(deudas, alcance);
  const simulacion = simularCuotas(elegidas, cuotas);

  return (
    <Pantalla
      encabezadoHastaArriba
      separacion="block"
      encabezado={<BarraSuperior titulo="Simulación de cuotas" />}
    >
      <Chips opciones={ALCANCES} elegida={alcance} onElegir={setAlcance} />

      {elegidas.length === 0 ? (
        <Vacio
          texto={
            alcance === 'mora'
              ? 'No tienes deudas en mora.'
              : 'No tienes deudas pendientes para simular.'
          }
        />
      ) : (
        <>
          <Tarjeta>
            <View>
              <Texto variante="bodyMd" color={colors.textSecondary}>
                Tu cuota mensual sería de
              </Texto>
              <Texto variante="displayCurrency" fuente="poppins" tabular>
                {formatearSoles(simulacion.cuotaMensual)}
              </Texto>
            </View>
            <View>
              <View style={estilos.fila}>
                <Texto variante="labelLg" style={estilos.flexible}>
                  Número de cuotas
                </Texto>
                <Texto variante="labelLg" tabular>
                  {cuotas}
                </Texto>
              </View>
              <Deslizador
                etiqueta="Número de cuotas"
                minimo={CUOTAS_MINIMAS}
                maximo={CUOTAS_MAXIMAS}
                valor={cuotas}
                onCambiar={setCuotas}
              />
              <View style={estilos.fila}>
                <Texto variante="bodyMd" color={colors.textSecondary} style={estilos.flexible}>
                  {CUOTAS_MINIMAS} cuotas
                </Texto>
                <Texto variante="bodyMd" color={colors.textSecondary}>
                  {CUOTAS_MAXIMAS} cuotas
                </Texto>
              </View>
            </View>
            <Separador />
            <View style={estilos.filas}>
              <FilaDato etiqueta="Deuda a fraccionar" valor={<Valor monto={simulacion.deuda} />} />
              <FilaDato etiqueta="Interés estimado" valor={<Valor monto={simulacion.interes} />} />
              <FilaDato etiqueta="Total a pagar" valor={<Valor monto={simulacion.total} />} />
            </View>
          </Tarjeta>

          <Destacado
            tono="aviso"
            texto="Simulación informativa con tasa ilustrativa de 1 % mensual. El fraccionamiento lo aprueba Rentas según la ordenanza vigente."
          />
          <Boton
            titulo="Pedir evaluación a Rentas"
            deshabilitado={pedido}
            onPress={() => setPedido(true)}
          />
          {pedido ? (
            <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
              Pedido simulado: en este prototipo no se envía nada a Rentas. Rentas evalúa y decide.
            </Texto>
          ) : null}
          <Boton
            tipo="secundario"
            titulo="Mejor pago ahora"
            onPress={() =>
              router.push({
                pathname: '/pago/confirmar',
                params: { deudas: elegidas.map((deuda) => deuda.id).join(',') },
              })
            }
          />
        </>
      )}
      <PiePrototipo />
    </Pantalla>
  );
}

function Valor({ monto }: { monto: number }) {
  return (
    <Texto variante="labelLg" alineacion="right" tabular>
      {formatearSoles(monto)}
    </Texto>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center' },
  flexible: { flex: 1 },
  filas: { gap: spacing.sm },
});
