import { municipalidades, spacing, type Zona } from '@almira/shared';
import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Nota, Rotulo, TituloPantalla } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Chips } from '@/components/Chips';
import { Opcion } from '@/components/Opcion';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useSesion } from '@/sesion';

// Con más municipalidades que esto aparecen el buscador y los chips de zona.
const MAXIMO_SIN_FILTROS = 5;

type FiltroZona = Zona | 'todas';

// Sin tildes ni mayúsculas: "jesus" encuentra "Jesús".
const normalizar = (texto: string) =>
  texto
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();

// Pantalla 02d (Stitch 4). La lista sale de los datos: nunca se escribe una
// municipalidad en la interfaz.
export default function ElegirMunicipalidad() {
  const { municipalidadId, elegirMunicipalidad } = useSesion();
  const activas = municipalidades.filter((m) => m.activa);
  const conFiltros = activas.length > MAXIMO_SIN_FILTROS;
  const [elegida, setElegida] = useState(
    activas.some((m) => m.id === municipalidadId) ? municipalidadId : activas[0]?.id,
  );
  const [busqueda, setBusqueda] = useState('');
  const [zona, setZona] = useState<FiltroZona>('todas');

  const zonas = [...new Set(activas.map((m) => m.zona))];
  const visibles = conFiltros
    ? activas.filter(
        (m) =>
          (zona === 'todas' || m.zona === zona) &&
          normalizar(m.nombre).includes(normalizar(busqueda.trim())),
      )
    : activas;

  const continuar = () => {
    if (!elegida) return;
    elegirMunicipalidad(elegida);
    router.push('/consentimiento');
  };

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo="Paso 2 de 3" />}
      pie={<Boton titulo="Continuar" deshabilitado={!elegida} onPress={continuar} />}
    >
      <TituloPantalla
        titulo="Elige tu municipalidad"
        texto="Es la del distrito donde está tu predio."
      />

      {conFiltros ? (
        <>
          <Campo
            accessibilityLabel="Buscar municipalidad"
            placeholder="Buscar municipalidad"
            autoComplete="off"
            value={busqueda}
            onChangeText={setBusqueda}
          />
          <Chips<FiltroZona>
            opciones={[
              { valor: 'todas', titulo: 'Todas' },
              ...zonas.map((valor) => ({ valor, titulo: valor })),
            ]}
            elegida={zona}
            onElegir={setZona}
          />
        </>
      ) : null}

      <View style={estilos.lista}>
        <Rotulo texto={`Municipalidades disponibles (${activas.length})`} />
        <View accessibilityRole="radiogroup" style={estilos.opciones}>
          {visibles.map((municipalidad) => (
            <Opcion
              key={municipalidad.id}
              icono="account-balance"
              titulo={municipalidad.nombre}
              detalle={municipalidad.zona}
              seleccionada={municipalidad.id === elegida}
              onPress={() => setElegida(municipalidad.id)}
            />
          ))}
          {visibles.length === 0 ? (
            <Texto variante="bodyMd" alineacion="center">
              No encontramos esa municipalidad.
            </Texto>
          ) : null}
        </View>
      </View>

      <Nota texto="Podrás cambiarla desde Mi perfil." />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  lista: { gap: spacing.blockDense },
  opciones: { gap: spacing.sm },
});
