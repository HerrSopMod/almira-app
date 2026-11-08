import {
  colors,
  deudasPendientes,
  DETALLE_MEDIO_PAGO,
  ETIQUETA_MEDIO_PAGO,
  formatearSoles,
  spacing,
  sumarDeudas,
  totalDeuda,
  type MedioPago,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router, useLocalSearchParams } from 'expo-router';
import { Fragment, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Destacado, FilaDato, CajaIcono, Separador, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Radio } from '@/components/Radio';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';

const MEDIOS: { medio: MedioPago; icono: keyof typeof MaterialIcons.glyphMap }[] = [
  { medio: 'yape', icono: 'smartphone' },
  { medio: 'plin', icono: 'smartphone' },
  { medio: 'tarjeta', icono: 'credit-card' },
  { medio: 'banca_movil', icono: 'account-balance' },
];

// Pantalla 07 del prototipo. El pago es simulado: no se conecta a ninguna pasarela.
export default function ConfirmarPago() {
  const { deudas: ids } = useLocalSearchParams<{ deudas?: string }>();
  const { deudas } = useDatosMunicipales();
  const { registrarPagoSimulado } = useSesion();
  const [medio, setMedio] = useState<MedioPago>('yape');
  // Tras pagar, las deudas ya figuran como pagadas: no se vuelve a dibujar mientras se navega.
  const [pagado, setPagado] = useState(false);

  const elegidas = deudasPendientes(deudas).filter((deuda) =>
    (ids ?? '').split(',').includes(deuda.id),
  );
  const total = sumarDeudas(elegidas);
  const encabezado = <BarraSuperior titulo="Confirma tu pago" />;

  if (pagado) return null;

  if (elegidas.length === 0) {
    return (
      <Pantalla encabezadoHastaArriba encabezado={encabezado}>
        <Vacio texto="No tienes deudas pendientes por pagar." />
      </Pantalla>
    );
  }

  const pagar = () => {
    const operacion = registrarPagoSimulado(elegidas, medio);
    setPagado(true);
    router.replace({ pathname: '/pago/constancia', params: { operacion } });
  };

  return (
    <Pantalla encabezadoHastaArriba separacion="blockDense" encabezado={encabezado}>
      <Tarjeta>
        {elegidas.map((deuda) => (
          <FilaDato
            key={deuda.id}
            etiqueta={deuda.concepto}
            valor={
              <Texto variante="bodyLgMedium" alineacion="right" tabular>
                {formatearSoles(totalDeuda(deuda))}
              </Texto>
            }
          />
        ))}
        <Separador />
        <View style={estilos.fila}>
          <Texto variante="bodyLgMedium" style={estilos.flexible}>
            Total a pagar
          </Texto>
          <Texto variante="headlineMd" alineacion="right" tabular>
            {formatearSoles(total)}
          </Texto>
        </View>
      </Tarjeta>

      <Texto variante="headlineSm" accessibilityRole="header" style={estilos.seccion}>
        ¿Cómo quieres pagar?
      </Texto>
      <View accessibilityRole="radiogroup">
        <Tarjeta>
          {MEDIOS.map(({ medio: opcion, icono }, indice) => (
            <Fragment key={opcion}>
              {indice > 0 ? <Separador /> : null}
              <Pressable
                accessibilityRole="radio"
                accessibilityState={{ checked: medio === opcion }}
                accessibilityLabel={`${ETIQUETA_MEDIO_PAGO[opcion]}. ${DETALLE_MEDIO_PAGO[opcion]}`}
                onPress={() => setMedio(opcion)}
                style={estilos.fila}
              >
                <CajaIcono icono={icono} />
                <View style={estilos.flexible}>
                  <Texto variante="bodyLgMedium">{ETIQUETA_MEDIO_PAGO[opcion]}</Texto>
                  <Texto variante="bodyMd" color={colors.textSecondary}>
                    {DETALLE_MEDIO_PAGO[opcion]}
                  </Texto>
                </View>
                <Radio marcado={medio === opcion} />
              </Pressable>
            </Fragment>
          ))}
        </Tarjeta>
      </View>

      <Destacado
        texto="Al confirmar, los avisos de estas deudas se detienen y no te contactaremos por 48 horas."
      />
      <Boton icono="lock-outline" titulo={`Pagar ${formatearSoles(total)}`} onPress={pagar} />
      <Texto variante="caption" color={colors.textSecondary} alineacion="center">
        Pago simulado. La pasarela real está por definir en la capa de integración.
      </Texto>
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  flexible: { flex: 1 },
  seccion: { marginTop: spacing.sm },
});
