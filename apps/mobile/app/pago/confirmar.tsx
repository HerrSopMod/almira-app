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
import { Linking, StyleSheet, View } from 'react-native';
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
import { supabaseConfigurado } from '@/supabase';

const MEDIOS: { medio: MedioPago; icono: NombreIcono }[] = [
  { medio: 'yape', icono: 'smartphone' },
  { medio: 'plin', icono: 'smartphone' },
  { medio: 'tarjeta', icono: 'credit-card' },
  { medio: 'banca_movil', icono: 'account-balance' },
];

// Pantalla 07 (Stitch 7, parte inferior). Almira no procesa pagos: si la municipalidad tiene
// un portal de pago (dato `urlPago`), el botón lleva a ese portal y el vecino paga allí. Sin
// Supabase, y sin portal, el pago sigue simulado para recorrer el prototipo.
export default function ConfirmarPago() {
  const { deudas: ids } = useLocalSearchParams<{ deudas?: string }>();
  const { deudas, municipalidad } = useDatosMunicipales();
  const urlPago = municipalidad.urlPago;
  const sinPortal = supabaseConfigurado && !urlPago;
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

  const irAlPortal = () => {
    if (urlPago) void Linking.openURL(urlPago);
  };

  const pagar = () => {
    const operacion = registrarPagoSimulado(elegidas, medio);
    setPagado(true);
    router.replace({ pathname: '/pago/constancia', params: { operacion } });
  };

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={encabezado}
      pie={
        urlPago ? (
          <Boton icono="open-in-new" titulo="Ir al portal de pago" onPress={irAlPortal} />
        ) : (
          <Boton
            icono="lock-outline"
            titulo={`Pagar ${formatearSoles(total)}`}
            deshabilitado={sinPortal}
            onPress={pagar}
          />
        )
      }
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

      {urlPago ? (
        <Nota
          icono="open-in-new"
          texto="Te llevamos al portal de pago de tu municipalidad. Allí eliges cómo pagar y completas la operación. Almira no procesa el pago ni lo confirma."
        />
      ) : sinPortal ? (
        <Nota texto="Tu municipalidad todavía no tiene un portal de pago enlazado en Almira." />
      ) : (
        <>
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
        </>
      )}
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.blockDense },
  medios: { gap: spacing.sm },
});
