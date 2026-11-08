import {
  colors,
  ETIQUETA_ESTADO_DEUDA,
  formatearFecha,
  formatearSoles,
  spacing,
  totalDeuda,
  type TipoDeuda,
} from '@almira/shared';
import { router, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import {
  Destacado,
  FilaDato,
  Insignia,
  Monto,
  Separador,
  Tarjeta,
  Vacio,
} from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Encabezado } from '@/components/Encabezado';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

const EXPLICACION: Record<TipoDeuda, string> = {
  predial:
    'El impuesto predial se calcula aplicando la escala progresiva acumulativa sobre el autovalúo total de tu predio registrado ante la municipalidad. Los intereses corresponden a la Tasa de Interés Moratorio legal vigente.',
  arbitrios:
    'Los arbitrios cubren los servicios de limpieza pública, parques y serenazgo que presta tu municipalidad. Los intereses corresponden a la Tasa de Interés Moratorio legal vigente.',
  multa: 'Es una sanción que registró tu municipalidad. Si crees que es incorrecta, puedes reclamarla.',
};

export default function DetalleDeuda() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { municipalidad, deudas, predios } = useDatosMunicipales();
  const deuda = deudas.find((fila) => fila.id === id);
  const predio = predios.find((fila) => fila.id === deuda?.predioId);

  if (!deuda) {
    return (
      <Pantalla encabezado={<Encabezado titulo="Detalle de deuda" conVolver />}>
        <Vacio texto="No encontramos este tributo en tu municipalidad." />
      </Pantalla>
    );
  }

  const total = totalDeuda(deuda);

  return (
    <Pantalla
      encabezado={<Encabezado titulo="Detalle de deuda" conVolver />}
      pie={
        deuda.estado === 'pagada' ? undefined : (
          <Boton
            icono="credit-card"
            titulo={`Pagar este tributo (${formatearSoles(total)})`}
            onPress={() => router.navigate({ pathname: '/pagar', params: { deudaId: deuda.id } })}
          />
        )
      }
    >
      <Texto color={colors.textSecondary}>{municipalidad.nombre}</Texto>
      <Tarjeta>
        <View style={estilos.grupo}>
          <Texto variante="bodyMd" color={colors.textSecondary}>
            Concepto
          </Texto>
          <Texto variante="bodyLgMedium">
            {deuda.concepto}
            {predio ? ` · Código predio ${predio.codigo}` : ''}
          </Texto>
        </View>
        <View style={estilos.grupo}>
          <Texto variante="bodyMd" color={colors.textSecondary}>
            Periodo
          </Texto>
          <Texto variante="bodyLgMedium">{deuda.periodo}</Texto>
        </View>
        <Separador />
        <FilaDato etiqueta="Monto insoluto" valor={<Monto valor={deuda.montoInsoluto} />} />
        <FilaDato
          etiqueta="Intereses moratorios (TIM)"
          valor={<Monto valor={deuda.interesMoratorio} />}
        />
        <Separador />
        <FilaDato etiqueta="Total a pagar" valor={<Monto valor={total} />} />
        <FilaDato etiqueta="Fecha límite de vencimiento" valor={formatearFecha(deuda.vencimiento)} />
        <Insignia
          texto={ETIQUETA_ESTADO_DEUDA[deuda.estado]}
          tono={deuda.estado === 'vencida' ? 'critico' : 'exito'}
        />
      </Tarjeta>
      <Destacado
        icono="calculate"
        titulo="Explicación simple de cálculo"
        texto={EXPLICACION[deuda.tipo]}
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.xs },
});
