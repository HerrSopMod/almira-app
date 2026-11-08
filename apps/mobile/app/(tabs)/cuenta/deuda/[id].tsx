import {
  colors,
  formatearSoles,
  HOY_EJEMPLO,
  spacing,
  textoVencimiento,
  totalDeuda,
  type TipoDeuda,
} from '@almira/shared';
import { router, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import {
  ChipEstadoDeuda,
  FilaDato,
  CajaIcono,
  PiePrototipo,
  Separador,
  Tarjeta,
  Vacio,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// El texto de arbitrios es el del prototipo; multa y predial no tienen pantalla propia.
const EN_PALABRAS_SIMPLES: Record<TipoDeuda, string> = {
  arbitrios:
    'Son los servicios que recibes en tu predio: limpieza pública, parques y serenazgo. Si pagas antes del vencimiento no se suma interés.',
  multa:
    'Es una sanción que registró tu municipalidad. Si crees que es incorrecta, puedes reclamarla.',
  predial:
    'Es el impuesto anual por tu predio. Se calcula sobre el valor de tu predio registrado en la municipalidad.',
};

// Pantalla 06 del prototipo.
export default function DetalleDeuda() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { deudas } = useDatosMunicipales();
  const deuda = deudas.find((fila) => fila.id === id);
  const encabezado = <BarraSuperior titulo="Detalle de la deuda" />;

  if (!deuda) {
    return (
      <Pantalla conPestanas encabezadoHastaArriba encabezado={encabezado}>
        <Vacio texto="No encontramos este tributo en tu municipalidad." />
      </Pantalla>
    );
  }

  const total = totalDeuda(deuda);

  return (
    <Pantalla conPestanas encabezadoHastaArriba separacion="blockDense" encabezado={encabezado}>
      <Tarjeta>
        <View style={estilos.encabezadoTarjeta}>
          <View style={estilos.fila}>
            <ChipEstadoDeuda estado={deuda.estado} />
            <Texto variante="bodyMd" color={colors.textSecondary}>
              {textoVencimiento(deuda.vencimiento, HOY_EJEMPLO)}
            </Texto>
          </View>
          <View>
            <Texto variante="headlineSm">{deuda.concepto}</Texto>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              {deuda.periodo}
            </Texto>
          </View>
          <Texto variante="displayCurrency" tabular>
            {formatearSoles(total)}
          </Texto>
        </View>
        <Separador />
        <FilaDato etiqueta="Monto" valor={<Valor monto={deuda.montoInsoluto} />} />
        <FilaDato etiqueta="Interés" valor={<Valor monto={deuda.interesMoratorio} />} />
      </Tarjeta>

      <Tarjeta>
        <View style={estilos.fila}>
          <CajaIcono icono="smart-toy" />
          <Texto variante="bodyLgMedium">En palabras simples</Texto>
        </View>
        <View style={estilos.explicacion}>
          <Texto color={colors.textSecondary}>{EN_PALABRAS_SIMPLES[deuda.tipo]}</Texto>
          <Texto color={colors.textSecondary}>Beneficio vigente: consulta con el asistente.</Texto>
        </View>
      </Tarjeta>

      {deuda.estado !== 'pagada' ? (
        <Boton
          titulo={`Pagar ${formatearSoles(total)}`}
          onPress={() =>
            router.push({ pathname: '/pago/confirmar', params: { deudas: deuda.id } })
          }
        />
      ) : null}
      <Boton
        tipo="secundario"
        titulo="Simular cuotas"
        onPress={() => router.push('/simulacion-cuotas')}
      />
      <Boton
        tipo="secundario"
        titulo="Preguntar al asistente"
        onPress={() => router.navigate('/asistente')}
      />
      <Boton
        tipo="terciario"
        titulo="¿Crees que este cobro es incorrecto? Reclámalo"
        onPress={() => router.navigate('/reclamos')}
      />
      <PiePrototipo />
    </Pantalla>
  );
}

function Valor({ monto }: { monto: number }) {
  return (
    <Texto variante="bodyLgMedium" alineacion="right" tabular>
      {formatearSoles(monto)}
    </Texto>
  );
}

const estilos = StyleSheet.create({
  encabezadoTarjeta: { gap: spacing.sm },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  explicacion: { gap: spacing.sm },
});
