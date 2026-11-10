import { codigoContribuyenteValido, documentoValido, spacing } from '@almira/shared';
import { Redirect, router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { Destacado, Nota, Rotulo, TituloPantalla } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { CampoDocumento } from '@/components/CampoDocumento';
import { Opcion } from '@/components/Opcion';
import { Pantalla } from '@/components/Pantalla';
import { useMunicipalidades, useSesion } from '@/sesion';
import { supabaseConfigurado } from '@/supabase';

// Pantalla 02c. Después de elegir la municipalidad: el vecino vincula su código de
// contribuyente (o de predio) con su DNI, y puede agregar más. La coincidencia la valida el
// padrón de la municipalidad (en el servidor con Supabase; sin Supabase, con datos de ejemplo).
export default function VincularCodigos() {
  const { metodoIngreso, nombreCuenta, municipalidadId, vinculos, vincularCodigo } = useSesion();
  const municipalidades = useMunicipalidades();
  const municipalidad = municipalidades.find((m) => m.id === municipalidadId);
  const [codigo, setCodigo] = useState('');
  const [documento, setDocumento] = useState('');
  const [mensaje, setMensaje] = useState<string | null>(null);
  const [ocupado, setOcupado] = useState(false);

  if (!metodoIngreso) return <Redirect href="/ingreso" />;

  const propios = vinculos.filter((v) => v.municipalidadId === municipalidadId);
  const listo = codigoContribuyenteValido(codigo) && documentoValido(documento);

  const vincular = async () => {
    setMensaje(null);
    setOcupado(true);
    try {
      const error = await vincularCodigo(codigo, documento);
      setMensaje(error);
      if (!error) {
        // Queda listo para agregar otro código; el DNI se conserva porque es el mismo vecino.
        setCodigo('');
      }
    } finally {
      setOcupado(false);
    }
  };

  return (
    <Pantalla encabezadoHastaArriba encabezado={<BarraSuperior titulo="Paso 3 de 5" />}>
      <TituloPantalla
        titulo="Vincula tus códigos"
        texto={`${nombreCuenta ? `Hola, ${nombreCuenta}. ` : ''}Con tu código de contribuyente y tu DNI encontramos tus tributos en el padrón${municipalidad ? ` de ${municipalidad.nombre}` : ''}.`}
      />

      {propios.length > 0 ? (
        <View style={estilos.lista}>
          <Rotulo texto={`Códigos vinculados (${propios.length})`} />
          {propios.map((v) => (
            <Opcion
              key={`${v.municipalidadId}-${v.codigo}`}
              icono="check-circle"
              titulo={v.codigo}
              detalle="Vinculado"
              seleccionada
              onPress={() => undefined}
            />
          ))}
        </View>
      ) : null}

      <Campo
        etiqueta="Código de contribuyente"
        ayuda="Lo encuentras en tu recibo municipal."
        autoCapitalize="characters"
        autoComplete="off"
        autoCorrect={false}
        maxLength={20}
        value={codigo}
        onChangeText={(texto) => setCodigo(texto.replace(/[^A-Za-z0-9-]/g, ''))}
      />
      <CampoDocumento valor={documento} onCambiar={setDocumento} />
      <Destacado
        icono="verified-user"
        texto="Comparamos el código y tu DNI con el padrón de la municipalidad. No guardamos tu DNI en la cuenta."
      />
      {supabaseConfigurado ? null : (
        <Nota texto="Datos de ejemplo: prueba con el código 0048217 y el DNI 40000082." />
      )}
      {mensaje ? <Nota texto={mensaje} /> : null}

      <Boton
        titulo={propios.length > 0 ? 'Agregar este código' : 'Vincular código'}
        deshabilitado={!listo || ocupado}
        onPress={vincular}
      />
      <Boton
        tipo="secundario"
        titulo="Continuar"
        deshabilitado={vinculos.length === 0}
        onPress={() => router.push('/celular')}
      />
      <Boton
        tipo="terciario"
        titulo="Tengo códigos de otra municipalidad"
        onPress={() => (router.canGoBack() ? router.back() : router.replace('/municipalidad'))}
      />
      <Nota
        icono="verified-user"
        texto="Tus datos se tratan según la Ley N.° 29733 de Protección de Datos Personales."
      />
    </Pantalla>
  );
}

const estilos = StyleSheet.create({ lista: { gap: spacing.sm } });
