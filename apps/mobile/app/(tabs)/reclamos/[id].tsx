import {
  colors,
  ETIQUETA_TIPO_RECLAMO,
  formatearFechaCorta,
  HOY_EJEMPLO,
  momentoAviso,
  pasosSeguimiento,
  plazoReclamo,
  sizes,
  spacing,
  type PasoSeguimiento,
} from '@almira/shared';
import { router, useLocalSearchParams } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { Avance, ChipPlazo, Rotulo, Tarjeta, Vacio } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { MiniaturaFoto } from '@/components/FotoSimulada';
import { LineaTiempo } from '@/components/LineaTiempo';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 18 (maqueta 18-seguimiento). El estado del reclamo lo cambia la municipalidad.
export default function Seguimiento() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { reclamos } = useDatosMunicipales();
  const reclamo = reclamos.find((fila) => fila.id === id);
  const encabezado = <BarraSuperior titulo="Seguimiento" />;

  if (!reclamo) {
    return (
      <Pantalla conPestanas encabezadoHastaArriba encabezado={encabezado}>
        <Vacio texto="No encontramos este reclamo en tu municipalidad." />
      </Pantalla>
    );
  }

  const resuelto = reclamo.estado === 'resuelto';
  const plazo = plazoReclamo(reclamo, HOY_EJEMPLO);
  const lugarYFecha = [reclamo.direccion, formatearFechaCorta(reclamo.creadoEn)]
    .filter(Boolean)
    .join(' · ');

  const detallePaso = (titulo: string, estado: PasoSeguimiento['estado']) => {
    if (estado === 'actual') return 'Estás aquí';
    if (estado !== 'hecho') return null;
    if (titulo === 'Recibido') {
      // Los reclamos de ejemplo solo traen la fecha; los nuevos, también la hora.
      return reclamo.creadoEn.includes('T')
        ? momentoAviso(reclamo.creadoEn, HOY_EJEMPLO)
        : formatearFechaCorta(reclamo.creadoEn);
    }
    if (titulo === 'Clasificado') return ETIQUETA_TIPO_RECLAMO[reclamo.tipo];
    if (titulo === 'Derivado al área' && reclamo.area) return `Área: ${reclamo.area}`;
    return null;
  };

  return (
    <Pantalla conPestanas encabezadoHastaArriba encabezado={encabezado}>
      <View style={estilos.cabecera}>
        <View style={estilos.fila}>
          <Texto variante="labelSm" color={colors.textSecondary} tabular style={estilos.flexible}>
            {reclamo.codigo}
          </Texto>
          {resuelto ? (
            <ChipPlazo texto="Resuelto" tono="resuelto" />
          ) : plazo ? (
            <ChipPlazo texto={plazo.etiqueta} />
          ) : null}
        </View>
        <Texto variante="headlineLg" accessibilityRole="header">
          {reclamo.titulo}
        </Texto>
        <Texto color={colors.textSecondary}>{lugarYFecha}</Texto>
      </View>

      <Tarjeta>
        <View style={estilos.resumen}>
          <MiniaturaFoto tipo={reclamo.tipo} lado={sizes.photoThumbLg} />
          <Texto style={estilos.flexible}>{reclamo.descripcion ?? reclamo.titulo}</Texto>
        </View>
      </Tarjeta>

      {plazo?.total && plazo.quedan !== null ? (
        <View style={estilos.plazo}>
          <View style={estilos.fila}>
            <Texto variante="bodyLgMedium" style={estilos.flexible}>
              Plazo de {reclamo.area ?? 'la municipalidad'}
            </Texto>
            <Texto variante="bodyLgMedium" tabular>
              Quedan {plazo.quedan} de {plazo.total} días
            </Texto>
          </View>
          {/* La barra muestra el tiempo que ya pasó: con 3 de 10 por delante, va en 7 de 10. */}
          <Avance porcentaje={((plazo.total - plazo.quedan) / plazo.total) * 100} />
        </View>
      ) : null}

      <View style={estilos.plazo}>
        <Rotulo texto="Seguimiento" />
        <LineaTiempo
          pasos={pasosSeguimiento(reclamo.estado).map((paso) => ({
            ...paso,
            detalle: detallePaso(paso.titulo, paso.estado),
          }))}
        />
      </View>

      <Boton
        tipo="secundario"
        titulo="Hablar con una persona"
        onPress={() => router.push('/atencion-humana')}
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  cabecera: { gap: spacing.sm },
  fila: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  flexible: { flex: 1 },
  resumen: { flexDirection: 'row', alignItems: 'center', gap: spacing.md },
  plazo: { gap: spacing.blockDense },
});
