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
import { MaterialIcons } from '@expo/vector-icons';
import { Redirect, router, useLocalSearchParams, type Href } from 'expo-router';
import { useState } from 'react';
import { Pressable, Share, StyleSheet, View } from 'react-native';
import {
  CajaIcono,
  Destacado,
  Insignia,
  Nota,
  PiePrototipo,
  Tarjeta,
} from '@/components/Bloques';
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

// Pantalla 08 (maqueta 08-constancia-de-pago). Constancia de un pago simulado,
// guardada solo en memoria.
export default function Constancia() {
  const { operacion } = useLocalSearchParams<{ operacion?: string }>();
  const { municipalidad, pagos } = useDatosMunicipales();
  const [descargaTocada, setDescargaTocada] = useState(false);
  const [falloCompartir, setFalloCompartir] = useState(false);
  const delPago = pagos.filter((pago) => pago.referencia === operacion);
  const primero = delPago[0];

  if (!primero) return <Redirect href="/inicio" />;

  const total = delPago.reduce((suma, pago) => suma + pago.monto, 0);
  const dia = primero.creadoEn.slice(0, 10) === HOY_EJEMPLO ? 'Hoy, ' : '';
  const momento = `${dia}${formatearFechaCorta(primero.creadoEn)} · ${formatearHora(primero.creadoEn)}`;

  // Comparte un resumen sin datos personales: monto, fecha y número de operación.
  const compartir = async () => {
    setFalloCompartir(false);
    try {
      await Share.share({
        title: 'Constancia de pago',
        message: [
          `Constancia de pago · ${municipalidad.nombre}`,
          `${formatearSoles(total)} · ${momento} · ${operacion}`,
          'Pago simulado en Almira. Prototipo académico · Datos ficticios.',
        ].join('\n'),
      });
    } catch {
      setFalloCompartir(true);
    }
  };

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={
        <BarraSuperior
          titulo="Constancia de pago"
          iconoVolver="cerrar"
          onVolver={() => irA('/inicio')}
          accion={
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Compartir constancia"
              onPress={compartir}
              style={estilos.botonIcono}
            >
              <MaterialIcons name="share" size={sizes.icon} color={colors.text} />
            </Pressable>
          }
        />
      }
    >
      <View style={estilos.resumen}>
        <CajaIcono icono="check" grande redonda tono="exito" />
        <Insignia texto="Pago registrado" tono="ok" />
        <Texto variante="displayCurrency" alineacion="center" tabular>
          {formatearSoles(total)}
        </Texto>
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center" tabular>
          {momento} · {operacion}
        </Texto>
      </View>
      {falloCompartir ? (
        <Nota texto="No pudimos abrir las opciones para compartir en este dispositivo." />
      ) : null}

      <Tarjeta grande style={estilos.constancia}>
        <View style={estilos.marcoQr}>
          <QrSimulado />
        </View>
        <View>
          <Texto variante="bodyLgMedium" alineacion="center">
            Constancia digital
          </Texto>
          <Texto variante="caption" color={colors.textSecondary} alineacion="center">
            QR simulado · válido en Rentas y Depósito
          </Texto>
        </View>
      </Tarjeta>

      <Destacado
        icono="directions-car"
        texto="Lleva este QR, tu DNI y tu tarjeta de propiedad al depósito. No tienes que volver a hacer cola en caja."
      />
      <Nota
        icono="notifications-off"
        texto="Avisos de estas deudas detenidos. Rentas concilia tu pago en el día."
      />

      <Boton icono="download" titulo="Descargar constancia" onPress={() => setDescargaTocada(true)} />
      {descargaTocada ? (
        <Texto variante="bodyMd" color={colors.textSecondary} alineacion="center">
          Descarga simulada: en este prototipo no se genera ningún archivo.
        </Texto>
      ) : null}
      <Boton tipo="secundario" titulo="Mira en qué se usa tu pago" onPress={() => irA('/obras')} />
      <Boton tipo="terciario" titulo="Volver al inicio" onPress={() => irA('/inicio')} />
      <PiePrototipo />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  botonIcono: {
    width: sizes.buttonTertiary,
    height: sizes.buttonTertiary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  resumen: { alignItems: 'center', gap: spacing.blockDense },
  constancia: { alignItems: 'center', gap: spacing.blockDense },
  marcoQr: {
    padding: spacing.md,
    borderWidth: sizes.borderWidth,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
});
