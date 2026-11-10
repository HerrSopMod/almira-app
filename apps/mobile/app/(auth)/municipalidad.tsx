import { spacing, type Zona } from '@almira/shared';
import { Redirect, router, useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Nota, Rotulo, TituloPantalla } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Chips } from '@/components/Chips';
import { Opcion } from '@/components/Opcion';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useMunicipalidades, useSesion } from '@/sesion';

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
// municipalidad en la interfaz. Con ?modo=cambio se abre desde Mi perfil: solo
// cambia la municipalidad elegida (sin tocar la sesión ni los consentimientos) y vuelve.
export default function ElegirMunicipalidad() {
  const { modo } = useLocalSearchParams<{ modo?: string }>();
  const cambio = modo === 'cambio';
  const { metodoIngreso, municipalidadId, elegirMunicipalidad } = useSesion();
  const activas = useMunicipalidades();
  const conFiltros = activas.length > MAXIMO_SIN_FILTROS;
  const [elegida, setElegida] = useState(
    activas.some((m) => m.id === municipalidadId) ? municipalidadId : activas[0]?.id,
  );
  // Con Supabase la lista llega después de abrir la pantalla.
  useEffect(() => {
    if (!elegida && activas[0]) setElegida(activas[0].id);
  }, [elegida, activas]);
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

  // En el ingreso solo se llega después de autenticarse.
  if (!cambio && !metodoIngreso) return <Redirect href="/ingreso" />;

  const continuar = () => {
    if (!elegida) return;
    elegirMunicipalidad(elegida);
    if (!cambio) router.push('/vincular-codigos');
    else if (router.canGoBack()) router.back();
    else router.navigate('/inicio/perfil');
  };

  return (
    <Pantalla
      encabezadoHastaArriba
      encabezado={<BarraSuperior titulo={cambio ? 'Mi municipalidad' : ''} />}
      pie={
        <Boton
          titulo={cambio ? 'Guardar' : 'Continuar'}
          deshabilitado={!elegida}
          onPress={continuar}
        />
      }
    >
      <TituloPantalla titulo="Elige tu municipalidad" />

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

    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  lista: { gap: spacing.blockDense },
  opciones: { gap: spacing.sm },
});
