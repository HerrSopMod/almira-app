import {
  colors,
  deudasSeleccionadas,
  DETALLE_MEDIO_PAGO,
  ETIQUETA_MEDIO_PAGO,
  formatearSoles,
  spacing,
  sumarDeudas,
  totalDeuda,
  type MedioPago,
} from '@almira/shared';
import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import {
  FilaDato,
  Nota,
  Separador,
  Tarjeta,
  Vacio,
  type NombreIcono,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Opcion } from '@/components/Opcion';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';

const MEDIOS: { medio: MedioPago; icono: NombreIcono }[] = [
  { medio: 'yape', icono: 'smartphone' },
  { medio: 'plin', icono: 'smartphone' },
  { medio: 'tarjeta', icono: 'credit-card' },
  { medio: 'banca_movil', icono: 'account-balance' },
];

// Pantalla 07 (Stitch 7, parte inferior). El pago es simulado: no se conecta a
// ninguna pasarela y solo el servidor podría confirmarlo.
export default function ConfirmarPago() {
  const { deudas: ids } = useLocalSearchParams<{ deudas?: string }>();
  const { deudas } = useDatosMunicipales();
  const { registrarPagoSimulado } = useSesion();
  const [medio, setMedio] = useState<MedioPago>('yape');
  // Tras pagar, las deudas ya figuran como pagadas: no se vuelve a dibujar mientras se navega.
  const [pagado, setPagado] = useState(false);

  const elegidas = deudasSeleccionadas(deudas, (ids ?? '').split(','));
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
    <Pantalla
      encabezadoHastaArriba
      encabezado={encabezado}
      pie={<Boton icono="lock-outline" titulo={`Pagar ${formatearSoles(total)}`} onPress={pagar} />}
    >
      <Tarjeta>
        {elegidas.map((deuda) => (
          <FilaDato
            key={deuda.id}
            etiqueta={deuda.concepto}
            valor={formatearSoles(totalDeuda(deuda))}
          />
        ))}
        <Separador />
        <FilaDato total etiqueta="Total a pagar" valor={formatearSoles(total)} />
      </Tarjeta>

      <View style={estilos.grupo}>
        <Texto variante="headlineSm" accessibilityRole="header">
          ¿Cómo quieres pagar?
        </Texto>
        <View accessibilityRole="radiogroup" style={estilos.medios}>
          {MEDIOS.map(({ medio: opcion, icono }) => (
            <Opcion
              key={opcion}
              icono={icono}
              titulo={ETIQUETA_MEDIO_PAGO[opcion]}
              detalle={DETALLE_MEDIO_PAGO[opcion]}
              seleccionada={medio === opcion}
              onPress={() => setMedio(opcion)}
            />
          ))}
        </View>
      </View>

      <Nota
        icono="notifications-off"
        texto="Al confirmar, los avisos de estas deudas se detienen y no te contactaremos por 48 horas."
      />
      <Texto variante="caption" color={colors.textSecondary} alineacion="center">
        Pago simulado. La pasarela real está por definir en la capa de integración.
      </Texto>
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.blockDense },
  medios: { gap: spacing.sm },
});
