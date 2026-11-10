import {
  colors,
  formatearFecha,
  formatearSoles,
  spacing,
  totalDeuda,
  type TipoDeuda,
} from '@almira/shared';
import { router, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import {
  ChipEstadoDeuda,
  Destacado,
  FilaDato,
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

// Pantalla 06 (Stitch 6, con los textos del prototipo).
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
    <Pantalla conPestanas encabezadoHastaArriba encabezado={encabezado}>
      <Tarjeta>
        <DatoApilado etiqueta="Concepto" valor={deuda.concepto} />
        <Separador />
        <DatoApilado etiqueta="Periodo" valor={deuda.periodo} />
        <Separador />
        <FilaDato etiqueta="Monto" valor={formatearSoles(deuda.montoInsoluto)} />
        <FilaDato etiqueta="Interés" valor={formatearSoles(deuda.interesMoratorio)} />
        <Separador />
        <FilaDato total etiqueta="Total a pagar" valor={formatearSoles(total)} />
        <Separador />
        <View style={estilos.fila}>
          <DatoApilado etiqueta="Vencimiento" valor={formatearFecha(deuda.vencimiento)} />
          <ChipEstadoDeuda estado={deuda.estado} />
        </View>
      </Tarjeta>

      <Destacado
        icono="lightbulb-outline"
        titulo="En palabras simples"
        texto={EN_PALABRAS_SIMPLES[deuda.tipo]}
      >
        <Texto variante="bodyMd">Beneficio vigente: consulta con el asistente.</Texto>
      </Destacado>

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
        tipo="terciario"
        titulo="Preguntar al asistente"
        onPress={() => router.navigate('/asistente')}
      />
      <Boton
        tipo="terciario"
        titulo="¿Crees que este cobro es incorrecto? Reclámalo"
        onPress={() => router.navigate('/reclamos')}
      />
    </Pantalla>
  );
}

// Rótulo en mayúsculas con su valor debajo (Concepto, Periodo, Vencimiento).
function DatoApilado({ etiqueta, valor }: { etiqueta: string; valor: string }) {
  return (
    <View style={estilos.dato}>
      <Texto variante="overline" color={colors.textSecondary}>
        {etiqueta}
      </Texto>
      <Texto variante="bodyLgMedium">{valor}</Texto>
    </View>
  );
}

const estilos = StyleSheet.create({
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  dato: { flex: 1, gap: spacing.xs },
});
