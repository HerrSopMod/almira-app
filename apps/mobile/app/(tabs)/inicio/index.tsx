import {
  colors,
  deudasPendientes,
  ETIQUETA_ESTADO_RECLAMO,
  ETIQUETA_TIPO_RECORDATORIO,
  formatearFecha,
  formatearPorcentaje,
  formatearSoles,
  HOY_EJEMPLO,
  momentoAviso,
  plazoReclamo,
  proximoVencimiento,
  radius,
  repartoDeuda,
  sizes,
  spacing,
  textoVencimiento,
  totalDeuda,
  USUARIO_EJEMPLO,
  type Deuda,
  type Recordatorio,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Fragment } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import {
  Avance,
  CajaIcono,
  ChipEstadoDeuda,
  ChipPlazo,
  Destacado,
  Separador,
  Tarjeta,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 04 (Stitch 5, con los textos y datos del prototipo).
export default function Inicio() {
  const { municipalidad, vecino, deudas, recordatorios, obras, reclamos } = useDatosMunicipales();
  const pendientes = deudasPendientes(deudas);
  const arbitrioPorVencer = pendientes.find(
    (deuda) => deuda.tipo === 'arbitrios' && deuda.estado === 'vigente',
  );
  const obra = obras.find((fila) => fila.estado === 'en_ejecucion');
  const reclamo = reclamos.find((fila) => fila.estado !== 'resuelto');
  const plazo = reclamo ? plazoReclamo(reclamo, HOY_EJEMPLO)?.etiqueta : null;
  const nombre = vecino?.nombre.split(' ')[0] ?? USUARIO_EJEMPLO.nombre;

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      encabezado={<BarraSuperior variante="raiz" titulo="Inicio" />}
    >
      <View style={estilos.saludo}>
        <Texto variante="headlineLg" accessibilityRole="header">
          Hola, {nombre}
        </Texto>
        <View style={estilos.fila}>
          <MaterialIcons name="account-balance" size={sizes.iconSm} color={colors.primary} />
          <Texto variante="bodyMd" color={colors.textSecondary} style={estilos.flexible}>
            {municipalidad.nombre}
          </Texto>
        </View>
      </View>

      <View style={estilos.grupo}>
        <ResumenDeuda deudas={deudas} />
        {pendientes.length > 0 ? (
          <Boton titulo="Ver detalle y pagar" onPress={() => router.navigate('/cuenta')} />
        ) : null}
      </View>

      {arbitrioPorVencer ? (
        <Pressable
          accessibilityRole="button"
          onPress={() => router.push('/inicio/recordatorios')}
        >
          <Tarjeta>
            <View style={estilos.fila}>
              <CajaIcono icono="notifications-none" />
              <View style={estilos.flexible}>
                <Texto variante="bodyLgMedium">Tu arbitrio vence pronto</Texto>
                <Texto variante="bodyMd" color={colors.textSecondary}>
                  {textoVencimiento(arbitrioPorVencer.vencimiento, HOY_EJEMPLO)}
                </Texto>
              </View>
              <MaterialIcons name="chevron-right" size={sizes.icon} color={colors.textSecondary} />
            </View>
          </Tarjeta>
        </Pressable>
      ) : null}

      {pendientes.length > 0 ? (
        <View style={estilos.grupo}>
          <Texto variante="headlineSm" accessibilityRole="header">
            Tributos registrados
          </Texto>
          <Tarjeta>
            {pendientes.map((deuda, indice) => (
              <Fragment key={deuda.id}>
                {indice > 0 ? <Separador /> : null}
                <FilaTributo deuda={deuda} recordatorios={recordatorios} />
              </Fragment>
            ))}
          </Tarjeta>
        </View>
      ) : null}

      {obra || reclamo ? (
        <View style={estilos.grupo}>
          <Texto variante="headlineSm" accessibilityRole="header">
            En tu distrito
          </Texto>
          {obra ? (
            <Pressable
              accessibilityRole="button"
              onPress={() =>
                router.navigate({ pathname: '/obras/[id]', params: { id: obra.id } })
              }
            >
              <Tarjeta>
                <View style={estilos.fila}>
                  <CajaIcono icono="construction" />
                  <Texto variante="bodyLgMedium" style={estilos.flexible}>
                    {obra.nombre}
                  </Texto>
                  <Texto variante="bodyLgMedium" alineacion="right" tabular>
                    {formatearPorcentaje(obra.avancePct)}
                  </Texto>
                </View>
                <Avance porcentaje={obra.avancePct} />
              </Tarjeta>
            </Pressable>
          ) : null}
          {reclamo ? (
            <Pressable
              accessibilityRole="button"
              onPress={() =>
                router.navigate({ pathname: '/reclamos/[id]', params: { id: reclamo.id } })
              }
            >
              <Tarjeta>
                <View style={estilos.fila}>
                  <CajaIcono icono="photo-camera" />
                  <View style={estilos.flexible}>
                    <Texto variante="bodyLgMedium">{reclamo.titulo}</Texto>
                    <Texto variante="bodyMd" color={colors.textSecondary}>
                      {ETIQUETA_ESTADO_RECLAMO[reclamo.estado]}
                      {reclamo.area ? ` · ${reclamo.area}` : ''}
                    </Texto>
                  </View>
                  {plazo ? <ChipPlazo texto={plazo} /> : null}
                </View>
              </Tarjeta>
            </Pressable>
          ) : null}
        </View>
      ) : null}

    </Pantalla>
  );
}

// El Destacado de la pantalla: deuda total, próximo vencimiento y reparto entre
// lo que está en mora y lo que está por vencer.
function ResumenDeuda({ deudas }: { deudas: Deuda[] }) {
  const reparto = repartoDeuda(deudas);
  const vence = proximoVencimiento(deudas, HOY_EJEMPLO);

  if (reparto.cantidad === 0) {
    return <Destacado icono="check" titulo="No tienes deudas pendientes" />;
  }

  return (
    <Destacado icono={null}>
      <View style={estilos.fila}>
        <Texto variante="titleSm" color={colors.primaryPressed} style={estilos.flexible}>
          Deuda total pendiente
        </Texto>
        <Texto variante="bodyMd" color={colors.textSecondary}>
          {reparto.cantidad} {reparto.cantidad === 1 ? 'tributo' : 'tributos'}
        </Texto>
      </View>
      <Texto variante="displayCurrency" tabular>
        {formatearSoles(reparto.total)}
      </Texto>
      {vence ? (
        <View style={estilos.fila}>
          <MaterialIcons name="event" size={sizes.iconXs} color={colors.textSecondary} />
          <Texto variante="bodyMd" color={colors.textSecondary} style={estilos.flexible}>
            Próximo vencimiento: {formatearFecha(vence)}
          </Texto>
        </View>
      ) : null}
      <View
        accessible
        accessibilityLabel={`En mora ${formatearSoles(reparto.enMora)}, por vencer ${formatearSoles(reparto.porVencer)}`}
        style={estilos.reparto}
      >
        <View style={estilos.barra}>
          {reparto.enMora > 0 ? (
            <View style={[estilos.tramo, { flex: reparto.enMora, backgroundColor: colors.danger }]} />
          ) : null}
          {reparto.porVencer > 0 ? (
            <View
              style={[estilos.tramo, { flex: reparto.porVencer, backgroundColor: colors.warning }]}
            />
          ) : null}
        </View>
        <View style={estilos.leyenda}>
          <ItemLeyenda
            color={colors.danger}
            texto={`En mora (${formatearPorcentaje(reparto.porcentajeEnMora)})`}
          />
          <ItemLeyenda
            color={colors.warning}
            texto={`Por vencer (${formatearPorcentaje(reparto.porcentajePorVencer)})`}
          />
        </View>
      </View>
    </Destacado>
  );
}

function ItemLeyenda({ color, texto }: { color: string; texto: string }) {
  return (
    <View style={estilos.itemLeyenda}>
      <View style={[estilos.punto, { backgroundColor: color }]} />
      <Texto variante="caption" tabular>
        {texto}
      </Texto>
    </View>
  );
}

// Fila de "Tributos registrados": concepto, último aviso, monto y estado.
function FilaTributo({ deuda, recordatorios }: { deuda: Deuda; recordatorios: Recordatorio[] }) {
  const ultimoAviso = recordatorios
    .filter((aviso) => aviso.deudaId === deuda.id)
    .sort((a, b) => b.programadoPara.localeCompare(a.programadoPara))[0];
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityHint="Abre el detalle de la deuda"
      onPress={() => router.navigate(`/cuenta/deuda/${deuda.id}`)}
      style={estilos.tributo}
    >
      <View style={[estilos.flexible, estilos.textosTributo]}>
        <Texto variante="bodyLgMedium">{deuda.concepto}</Texto>
        <Texto variante="bodyMd" color={colors.textSecondary}>
          {deuda.periodo}
        </Texto>
        {ultimoAviso ? (
          <View style={estilos.fila}>
            <MaterialIcons name="sms" size={sizes.iconXs} color={colors.textSecondary} />
            <Texto variante="caption" color={colors.textSecondary} style={estilos.flexible}>
              Último aviso: {ETIQUETA_TIPO_RECORDATORIO[ultimoAviso.tipo]} ·{' '}
              {momentoAviso(ultimoAviso.entregadoEn ?? ultimoAviso.programadoPara, HOY_EJEMPLO)}
            </Texto>
          </View>
        ) : null}
      </View>
      <View style={estilos.montoTributo}>
        <Texto variante="bodyLgMedium" alineacion="right" tabular>
          {formatearSoles(totalDeuda(deuda))}
        </Texto>
        {/* La insignia se pega a la izquierda de su contenedor: este la lleva a la derecha. */}
        <View>
          <ChipEstadoDeuda estado={deuda.estado} />
        </View>
      </View>
    </Pressable>
  );
}

const estilos = StyleSheet.create({
  saludo: { gap: spacing.xs },
  grupo: { gap: spacing.blockDense },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  flexible: { flex: 1 },
  reparto: { gap: spacing.sm, marginTop: spacing.xs },
  barra: {
    flexDirection: 'row',
    height: sizes.progress,
    borderRadius: radius.full,
    overflow: 'hidden',
    backgroundColor: colors.track,
  },
  tramo: { height: '100%' },
  leyenda: { flexDirection: 'row', flexWrap: 'wrap', columnGap: spacing.md, rowGap: spacing.xs },
  itemLeyenda: { flexDirection: 'row', alignItems: 'center', gap: spacing.xs },
  punto: { width: sizes.badgeDot, height: sizes.badgeDot, borderRadius: sizes.badgeDot / 2 },
  tributo: { flexDirection: 'row', gap: spacing.blockDense },
  textosTributo: { gap: spacing.xs },
  montoTributo: { alignItems: 'flex-end', gap: spacing.xs },
});
