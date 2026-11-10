import {
  colors,
  ETIQUETA_ESTADO_RECLAMO,
  ETIQUETA_TIPO_RECLAMO,
  HOY_EJEMPLO,
  plazoReclamo,
  sizes,
  spacing,
  type Reclamo,
} from '@almira/shared';
import { MaterialIcons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import {
  ChipPlazo,
  Nota,
  Rotulo,
  Tarjeta,
  Vacio,
  type NombreIcono,
} from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { MiniaturaFoto } from '@/components/FotoSimulada';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales } from '@/sesion';

// Pantalla 15 (Stitch 10). Los reclamos nuevos se guardan en memoria y salen primero.
// La ayuda lleva a Atención humana: no se muestra ningún teléfono.
export default function Reclamos() {
  const { vecino, reclamos } = useDatosMunicipales();

  return (
    <Pantalla
      conPestanas
      encabezadoHastaArriba
      encabezado={<BarraSuperior variante="raiz" titulo="Reclamos" />}
    >
      <Boton
        icono="add-a-photo"
        titulo="Nuevo reclamo con foto"
        deshabilitado={!vecino}
        onPress={() => router.push('/reclamo/nuevo')}
      />

      <View style={estilos.lista}>
        <Rotulo texto="Tus reclamos" />
        {reclamos.length === 0 ? (
          <Vacio texto="No tienes reclamos en esta municipalidad." />
        ) : (
          reclamos.map((reclamo) => <TarjetaReclamo key={reclamo.id} reclamo={reclamo} />)
        )}
      </View>


      <View style={estilos.ayuda}>
        <Texto variante="bodyLgMedium" alineacion="center">
          ¿Necesitas ayuda?
        </Texto>
        <Boton
          tipo="secundario"
          icono="support-agent"
          titulo="Hablar con una persona"
          onPress={() => router.push('/atencion-humana')}
        />
      </View>
    </Pantalla>
  );
}

function TarjetaReclamo({ reclamo }: { reclamo: Reclamo }) {
  const resuelto = reclamo.estado === 'resuelto';
  const plazo = plazoReclamo(reclamo, HOY_EJEMPLO);

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${reclamo.codigo}, ${reclamo.titulo}. ${ETIQUETA_ESTADO_RECLAMO[reclamo.estado]}`}
      onPress={() => router.push({ pathname: '/reclamos/[id]', params: { id: reclamo.id } })}
    >
      <Tarjeta>
        <View style={estilos.cabecera}>
          <Texto variante="labelSm" color={colors.primary} tabular style={estilos.flexible}>
            {reclamo.codigo}
          </Texto>
          {resuelto ? (
            <ChipPlazo texto="Resuelto" tono="resuelto" />
          ) : plazo ? (
            <ChipPlazo texto={plazo.etiqueta} />
          ) : null}
        </View>
        <Texto variante="headlineSm">{reclamo.titulo}</Texto>
        <View style={estilos.detalle}>
          <MiniaturaFoto tipo={reclamo.tipo} />
          <View style={estilos.datos}>
            <Dato icono="category" texto={ETIQUETA_TIPO_RECLAMO[reclamo.tipo]} />
            {reclamo.area ? <Dato icono="account-balance" texto={reclamo.area} /> : null}
            <Dato icono="schedule" texto={ETIQUETA_ESTADO_RECLAMO[reclamo.estado]} />
          </View>
        </View>
      </Tarjeta>
    </Pressable>
  );
}

function Dato({ icono, texto }: { icono: NombreIcono; texto: string }) {
  return (
    <View style={estilos.dato}>
      <MaterialIcons name={icono} size={sizes.iconXs} color={colors.textSecondary} />
      <Texto variante="bodyMd" color={colors.textSecondary} style={estilos.flexible}>
        {texto}
      </Texto>
    </View>
  );
}

const estilos = StyleSheet.create({
  lista: { gap: spacing.blockDense },
  cabecera: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  flexible: { flex: 1 },
  detalle: { flexDirection: 'row', alignItems: 'center', gap: spacing.blockDense },
  datos: { flex: 1, gap: spacing.xs },
  dato: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  ayuda: { gap: spacing.sm, marginTop: spacing.sm },
});
