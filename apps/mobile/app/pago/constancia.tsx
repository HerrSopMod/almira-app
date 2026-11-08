import {
  colors,
  formatearFechaCorta,
  formatearHora,
  formatearSoles,
  HOY_EJEMPLO,
  radius,
  sizes,
  spacing,
} from '@almira/shared';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { Redirect, router, useLocalSearchParams, type Href } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, PiePrototipo, Tarjeta } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { QrSimulado } from '@/components/QrSimulado';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Cierra el flujo de pago y abre una pestaña.
function irA(destino: Href) {
  if (router.canDismiss()) router.dismissAll();
  router.navigate(destino);
}

// Pantalla 08 del prototipo. Constancia de un pago simulado, guardada solo en memoria.
export default function Constancia() {
  const { operacion } = useLocalSearchParams<{ operacion?: string }>();
  const { pagos } = useDatosMunicipales();
  const [descargaTocada, setDescargaTocada] = useState(false);
  const delPago = pagos.filter((pago) => pago.referencia === operacion);
  const primero = delPago[0];

  if (!primero) return <Redirect href="/inicio" />;

  const total = delPago.reduce((suma, pago) => suma + pago.monto, 0);
  const dia = primero.creadoEn.slice(0, 10) === HOY_EJEMPLO ? 'Hoy, ' : '';

  return (
    <Pantalla
      encabezadoHastaArriba
      separacion="block"
      encabezado={<BarraSuperior titulo="Constancia de pago" conVolver={false} />}
    >
      <View style={estilos.resumen}>
        <View style={estilos.circulo}>
          <MaterialCommunityIcons name="check" size={32} color={colors.paidIcon} />
        </View>
        <Texto variante="headlineMd" fuente="poppins" alineacion="center" accessibilityRole="header">
          Pago registrado
        </Texto>
        <Texto variante="displayCurrency" fuente="poppins" alineacion="center" tabular>
          {formatearSoles(total)}
        </Texto>
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
          {dia}
          {formatearFechaCorta(primero.creadoEn)} · {formatearHora(primero.creadoEn)} · {operacion}
        </Texto>
      </View>

      <Tarjeta>
        <Texto variante="labelLg" alineacion="center">
          Constancia digital
        </Texto>
        <QrSimulado />
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
          QR simulado · válido en Rentas y Depósito
        </Texto>
      </Tarjeta>

      <Destacado
        tono="exito"
        icono="check"
        texto="Lleva este QR, tu DNI y tu tarjeta de propiedad al depósito. No tienes que volver a hacer cola en caja."
      />
      <Destacado
        tono="informacion"
        icono="notifications-none"
        texto="Avisos de estas deudas detenidos. Rentas concilia tu pago en el día."
      />

      <Boton titulo="Mira en qué se usa tu pago" onPress={() => irA('/obras')} />
      <Boton
        tipo="secundario"
        icono="download"
        titulo="Descargar constancia"
        onPress={() => setDescargaTocada(true)}
      />
      {descargaTocada ? (
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
          Descarga simulada: en este prototipo no se genera ningún archivo.
        </Texto>
      ) : null}
      <Boton tipo="terciario" titulo="Volver al inicio" onPress={() => irA('/inicio')} />
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  resumen: { alignItems: 'center', gap: spacing.xs },
  circulo: {
    width: sizes.successCircle,
    height: sizes.successCircle,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.full,
    backgroundColor: colors.paidSoft,
    marginBottom: spacing.sm,
  },
});
