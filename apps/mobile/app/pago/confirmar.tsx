import {
  colors,
  deudasPendientes,
  DETALLE_MEDIO_PAGO,
  ETIQUETA_MEDIO_PAGO,
  formatearSoles,
  sizes,
  spacing,
  sumarDeudas,
  totalDeuda,
  type MedioPago,
} from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { router, useLocalSearchParams } from 'expo-router';
import { Fragment, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Destacado, FilaDato, IconoCuadro, Separador, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';

const MEDIOS: { medio: MedioPago; icono: keyof typeof MaterialCommunityIcons.glyphMap }[] = [
  { medio: 'yape', icono: 'cellphone' },
  { medio: 'plin', icono: 'cellphone' },
  { medio: 'tarjeta', icono: 'credit-card-outline' },
  { medio: 'banca_movil', icono: 'bank-outline' },
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
    <Pantalla encabezadoHastaArriba separacion="block" encabezado={encabezado}>
      <Tarjeta>
        {elegidas.map((deuda) => (
          <FilaDato
            key={deuda.id}
            etiqueta={deuda.concepto}
            valor={
              <Texto variante="labelLg" alineacion="right" tabular>
                {formatearSoles(totalDeuda(deuda))}
              </Texto>
            }
          />
        ))}
        <Separador />
        <View style={estilos.fila}>
          <Texto variante="labelLg" style={estilos.flexible}>
            Total a pagar
          </Texto>
          <Texto variante="headlineMd" alineacion="right" tabular>
            {formatearSoles(total)}
          </Texto>
        </View>
      </Tarjeta>

      <Texto variante="headlineSm" fuente="poppins" accessibilityRole="header" style={estilos.seccion}>
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
                <IconoCuadro icono={icono} />
                <View style={estilos.flexible}>
                  <Texto variante="labelLg">{ETIQUETA_MEDIO_PAGO[opcion]}</Texto>
                  <Texto variante="bodyMd" color={colors.textSecondary}>
                    {DETALLE_MEDIO_PAGO[opcion]}
                  </Texto>
                </View>
                <View style={[estilos.radio, medio === opcion && estilos.radioMarcado]}>
                  {medio === opcion ? <View style={estilos.radioPunto} /> : null}
                </View>
              </Pressable>
            </Fragment>
          ))}
        </Tarjeta>
      </View>

      <Destacado
        tono="informacion"
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
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.block },
  flexible: { flex: 1 },
  seccion: { marginTop: spacing.sm },
  radio: {
    width: sizes.radio,
    height: sizes.radio,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: sizes.radio / 2,
    borderWidth: sizes.focusBorderWidth,
    borderColor: colors.radioOff,
  },
  radioMarcado: { borderColor: colors.primary },
  radioPunto: {
    width: sizes.radio / 2,
    height: sizes.radio / 2,
    borderRadius: sizes.radio / 4,
    backgroundColor: colors.primary,
  },
});
