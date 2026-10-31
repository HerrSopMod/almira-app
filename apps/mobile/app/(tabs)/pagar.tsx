import {
  colors,
  deudasPendientes,
  ETIQUETA_MEDIO_PAGO,
  formatearFechaCorta,
  formatearSoles,
  spacing,
  sumarDeudas,
  totalDeuda,
  type MedioPago,
} from '@almira/shared';
import { useLocalSearchParams } from 'expo-router';
import { useEffect, useMemo, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { FilaDato, Monto, Vacio } from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Encabezado } from '@/components/Encabezado';
import { Opcion } from '@/components/Opcion';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

const DETALLE_MEDIO: Record<MedioPago, string> = {
  billetera: 'Yape / Plin con código QR',
  tarjeta: 'Visa, Mastercard, Amex',
  pagoefectivo: 'Código CIP para banca móvil o agentes',
};

export default function Pagar() {
  const { deudaId } = useLocalSearchParams<{ deudaId?: string }>();
  const { municipalidad, deudas } = useDatosMunicipales();
  const pendientes = useMemo(() => deudasPendientes(deudas), [deudas]);

  const [seleccion, setSeleccion] = useState<string[]>([]);
  const [medio, setMedio] = useState<MedioPago>('billetera');
  const [enviado, setEnviado] = useState(false);

  useEffect(() => {
    setSeleccion(deudaId ? [deudaId] : pendientes.map((deuda) => deuda.id));
    setEnviado(false);
  }, [deudaId, pendientes]);

  const elegidas = pendientes.filter((deuda) => seleccion.includes(deuda.id));
  const total = sumarDeudas(elegidas);

  const alternar = (id: string) =>
    setSeleccion((actual) =>
      actual.includes(id) ? actual.filter((otro) => otro !== id) : [...actual, id],
    );

  return (
    <Pantalla
      conPestanas
      encabezado={<Encabezado titulo="Pagar" conAvisos />}
      pie={
        pendientes.length > 0 ? (
          <>
            {enviado ? (
              <Texto variante="bodyMd" color={colors.primary} alineacion="center">
                Redirigiendo a pasarela segura de recaudación...
              </Texto>
            ) : null}
            <FilaDato
              etiqueta={`Total seleccionado (${elegidas.length} ${elegidas.length === 1 ? 'tributo' : 'tributos'})`}
              valor={<Monto valor={total} />}
            />
            <Boton
              icono="lock"
              titulo={`Pagar ${formatearSoles(total)}`}
              deshabilitado={elegidas.length === 0}
              onPress={() => setEnviado(true)}
            />
          </>
        ) : undefined
      }
    >
      <View style={estilos.grupo}>
        <Texto variante="headlineLg">Pagar tributos</Texto>
        <Texto color={colors.textSecondary}>{municipalidad.nombre}</Texto>
      </View>

      <View style={estilos.grupo}>
        <Texto variante="headlineMd">Tributos pendientes</Texto>
        {pendientes.length === 0 ? (
          <Vacio texto="No tienes tributos pendientes en esta municipalidad." />
        ) : null}
        {pendientes.map((deuda) => (
          <Opcion
            key={deuda.id}
            multiple
            titulo={deuda.concepto}
            detalle={`Vence: ${formatearFechaCorta(deuda.vencimiento)}`}
            seleccionada={seleccion.includes(deuda.id)}
            onPress={() => alternar(deuda.id)}
            extra={<Monto valor={totalDeuda(deuda)} />}
          />
        ))}
      </View>

      {pendientes.length > 0 ? (
        <View style={estilos.grupo}>
          <Texto variante="headlineMd">Medio de pago</Texto>
          {(Object.keys(ETIQUETA_MEDIO_PAGO) as MedioPago[]).map((opcion) => (
            <Opcion
              key={opcion}
              titulo={ETIQUETA_MEDIO_PAGO[opcion]}
              detalle={DETALLE_MEDIO[opcion]}
              seleccionada={medio === opcion}
              onPress={() => setMedio(opcion)}
            />
          ))}
        </View>
      ) : null}
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.sm },
});
