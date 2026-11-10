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
import {
  Destacado,
  FilaDato,
  Nota,
  Separador,
  Tarjeta,
  Vacio,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Deslizador } from '@/components/Deslizador';
import { Pantalla } from '@/components/Pantalla';
import { Segmentado } from '@/components/Segmentado';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

const ALCANCES: { valor: AlcanceSimulacion; titulo: string }[] = [
  { valor: 'mora', titulo: 'Solo en mora' },
  { valor: 'toda', titulo: 'Toda mi deuda' },
];

// Pantalla 13 (maqueta 13-simulacion-de-cuotas). La cuota es informativa: usa la tasa ilustrativa del
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
      encabezado={<BarraSuperior titulo="Simulación de cuotas" />}
    >
      <Segmentado opciones={ALCANCES} elegida={alcance} onElegir={setAlcance} />

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
          <Destacado icono={null}>
            <View style={estilos.cuota}>
              <Texto color={colors.textSecondary}>Tu cuota mensual sería de</Texto>
              <Texto variante="displayCurrency" tabular>
                {formatearSoles(simulacion.cuotaMensual)}
              </Texto>
              <Texto variante="bodyMd" color={colors.textSecondary}>
                durante {cuotas} meses
              </Texto>
            </View>
          </Destacado>

          <View>
            <View style={estilos.fila}>
              <Texto variante="bodyLgMedium" style={estilos.flexible}>
                Número de cuotas
              </Texto>
              <Texto variante="headlineSm" tabular>
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

          <Tarjeta>
            <FilaDato etiqueta="Deuda a fraccionar" valor={formatearSoles(simulacion.deuda)} />
            <Separador />
            <FilaDato etiqueta="Interés estimado" valor={formatearSoles(simulacion.interes)} />
            <Separador />
            <FilaDato etiqueta="Total a pagar" valor={formatearSoles(simulacion.total)} total />
          </Tarjeta>

          <Nota texto="Simulación informativa con tasa ilustrativa de 1 % mensual. El fraccionamiento lo aprueba Rentas según la ordenanza vigente." />

          <View style={estilos.botones}>
            <Boton
              titulo={pedido ? 'Pedido enviado' : 'Pedir evaluación a Rentas'}
              deshabilitado={pedido}
              onPress={() => setPedido(true)}
            />
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
          </View>
        </>
      )}
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  cuota: { gap: spacing.xs },
  fila: { flexDirection: 'row', alignItems: 'center' },
  flexible: { flex: 1 },
  botones: { gap: spacing.sm },
});
