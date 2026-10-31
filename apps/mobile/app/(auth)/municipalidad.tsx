import { colors, municipalidades, radius, spacing, ZONAS, type Zona } from '@almira/shared';
import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Destacado, Vacio } from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Encabezado } from '@/components/Encabezado';
import { Opcion } from '@/components/Opcion';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useSesion } from '@/sesion';

export default function ElegirMunicipalidad() {
  const { municipalidadId, elegirMunicipalidad } = useSesion();
  const [seleccionada, setSeleccionada] = useState(municipalidadId);
  const [busqueda, setBusqueda] = useState('');
  const [zona, setZona] = useState<Zona | null>(null);

  const visibles = useMemo(() => {
    const termino = busqueda.trim().toLowerCase();
    return municipalidades.filter(
      (m) =>
        m.activa &&
        (zona === null || m.zona === zona) &&
        m.nombre.toLowerCase().includes(termino),
    );
  }, [busqueda, zona]);

  return (
    <Pantalla
      encabezado={<Encabezado conVolver={router.canGoBack()} />}
      pie={
        <Boton
          titulo="Continuar"
          icono="arrow-forward"
          onPress={() => {
            elegirMunicipalidad(seleccionada);
            router.replace('/inicio');
          }}
        />
      }
    >
      <View style={estilos.titulos}>
        <Texto variante="headlineLg">Elige tu municipalidad</Texto>
        <Texto color={colors.textSecondary}>
          Selecciona el distrito donde tienes registrado tu predio o negocio en Lima.
        </Texto>
      </View>
      <Destacado
        icono="location-city"
        titulo="Gestión Unificada Municipal"
        texto="Podrás consultar tus tributos, gestionar arbitrios y reportar incidencias en una sola plataforma."
      />
      <Campo
        placeholder="Buscar distrito o municipalidad..."
        accessibilityLabel="Buscar distrito o municipalidad"
        value={busqueda}
        onChangeText={setBusqueda}
      />
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View style={estilos.filtros}>
          {[null, ...ZONAS].map((opcion) => (
            <Pressable
              key={opcion ?? 'todas'}
              accessibilityRole="button"
              accessibilityState={{ selected: zona === opcion }}
              onPress={() => setZona(opcion)}
              style={[estilos.filtro, zona === opcion && estilos.filtroActivo]}
            >
              <Texto
                variante="bodyMdMedium"
                color={zona === opcion ? colors.onPrimary : colors.textSecondary}
              >
                {opcion ?? 'Todas'}
              </Texto>
            </Pressable>
          ))}
        </View>
      </ScrollView>
      <View style={estilos.lista}>
        <Texto variante="labelSm" color={colors.textSecondary}>
          Distritos habilitados ({visibles.length})
        </Texto>
        {visibles.map((municipalidad) => (
          <Opcion
            key={municipalidad.id}
            titulo={municipalidad.nombre}
            detalle={municipalidad.zona}
            seleccionada={seleccionada === municipalidad.id}
            onPress={() => setSeleccionada(municipalidad.id)}
          />
        ))}
        {visibles.length === 0 ? (
          <Vacio texto="Distrito no incorporado aún. Estamos integrando más municipalidades a Almira." />
        ) : null}
      </View>
      <Texto variante="bodyMd" color={colors.textSecondary}>
        Podrás cambiar de municipalidad en cualquier momento desde Inicio.
      </Texto>
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  titulos: { gap: spacing.sm },
  filtros: { flexDirection: 'row', gap: spacing.sm },
  filtro: {
    minHeight: 48,
    justifyContent: 'center',
    paddingHorizontal: spacing.md,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
  },
  filtroActivo: { backgroundColor: colors.primary, borderColor: colors.primary },
  lista: { gap: spacing.sm },
});
