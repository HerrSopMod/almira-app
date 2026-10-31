import {
  colors,
  ETIQUETA_CANAL,
  ETIQUETA_TIPO_RECORDATORIO,
  formatearFechaCorta,
  spacing,
  type CanalAviso,
} from '@almira/shared';
import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, Separador, Tarjeta, Vacio } from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Encabezado } from '@/components/Encabezado';
import { Opcion } from '@/components/Opcion';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

const CANALES: { valor: CanalAviso; titulo: string; detalle: string }[] = [
  { valor: 'whatsapp', titulo: 'WhatsApp', detalle: 'Recomendado para avisos inmediatos' },
  { valor: 'sms', titulo: 'Mensaje de texto (SMS)', detalle: 'Directo a tu número registrado' },
  { valor: 'app', titulo: 'Notificaciones en la app', detalle: 'Alertas en la bandeja del dispositivo' },
];

export default function Recordatorios() {
  const { vecino, recordatorios } = useDatosMunicipales();
  const [canal, setCanal] = useState<CanalAviso>(vecino?.canalPreferido ?? 'whatsapp');
  const [guardado, setGuardado] = useState(false);

  useEffect(() => {
    setGuardado(false);
  }, [canal]);

  const historial = [...recordatorios].sort((a, b) =>
    a.programadoPara.localeCompare(b.programadoPara),
  );

  return (
    <Pantalla encabezado={<Encabezado titulo="Recordatorios" conVolver />}>
      <View style={estilos.grupo}>
        <Texto variante="headlineLg">Recordatorios de pago</Texto>
        <Texto color={colors.textSecondary}>
          Configura alertas y revisa las notificaciones enviadas a tu cuenta tributaria.
        </Texto>
      </View>

      <Destacado
        icono="shield"
        titulo="Almira te avisa; no ejecuta cobranzas coactivas."
        texto="Esta aplicación es un canal informativo y de facilitación de pagos de tu municipalidad para ayudarte a evitar recargos."
      />

      <View style={estilos.grupo}>
        <Texto variante="headlineMd">Canal preferido de aviso</Texto>
        {CANALES.map(({ valor, titulo, detalle }) => (
          <Opcion
            key={valor}
            titulo={titulo}
            detalle={detalle}
            seleccionada={canal === valor}
            onPress={() => setCanal(valor)}
          />
        ))}
        <Boton icono="check" titulo="Guardar canal preferido" onPress={() => setGuardado(true)} />
        {guardado ? (
          <Texto variante="bodyMd" color={colors.success} alineacion="center">
            Canal de notificación actualizado con éxito.
          </Texto>
        ) : null}
      </View>

      <View style={estilos.grupo}>
        <Texto variante="headlineMd">Historial de avisos oficiales</Texto>
        {historial.length === 0 ? (
          <Vacio texto="Aún no tienes avisos en esta municipalidad." />
        ) : (
          <Tarjeta>
            {historial.map((aviso, indice) => (
              <View key={aviso.id} style={estilos.grupo}>
                {indice > 0 ? <Separador /> : null}
                <Texto variante="bodyLgMedium">{ETIQUETA_TIPO_RECORDATORIO[aviso.tipo]}</Texto>
                <Texto variante="bodyMd" color={colors.textSecondary}>
                  {aviso.entregadoEn
                    ? `Entregado por ${ETIQUETA_CANAL[aviso.canal]} el ${formatearFechaCorta(aviso.entregadoEn)}`
                    : `Programado por ${ETIQUETA_CANAL[aviso.canal]} para el ${formatearFechaCorta(aviso.programadoPara)}`}
                </Texto>
                <Texto variante="bodyMd" color={colors.textSecondary}>
                  Código: {aviso.codigo}
                </Texto>
              </View>
            ))}
          </Tarjeta>
        )}
      </View>
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.sm },
});
