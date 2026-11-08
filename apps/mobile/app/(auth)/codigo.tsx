import { codigoValido, USUARIO_EJEMPLO } from '@almira/shared';
import { router } from 'expo-router';
import { useState } from 'react';
import { Nota, TituloPantalla } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { CasillasCodigo } from '@/components/CasillasCodigo';
import { Pantalla } from '@/components/Pantalla';

// Pantalla 02b (Stitch 2). Todo es simulado: no se envía ningún SMS y sirve
// cualquier código de 6 dígitos. Viene lleno con el código de ejemplo.
export default function Codigo() {
  const [codigo, setCodigo] = useState<string>(USUARIO_EJEMPLO.codigoSmsEjemplo);
  const [reenviado, setReenviado] = useState(false);

  // Vuelve a donde se escribió el documento: Ingreso, o Vincula tu DNI si entró con Google.
  const cambiarDni = () => {
    if (router.canGoBack()) router.back();
    else router.replace('/ingreso');
  };

  return (
    <Pantalla encabezadoHastaArriba encabezado={<BarraSuperior titulo="Paso 1 de 3" />}>
      <TituloPantalla
        titulo="Ingresa el código"
        texto={`Lo enviamos por SMS al ${USUARIO_EJEMPLO.telefonoEnmascarado}`}
      />
      <CasillasCodigo valor={codigo} onCambiar={setCodigo} />
      <Nota texto="Datos de ejemplo. Sirve cualquier código de 6 dígitos." />
      {reenviado ? (
        <Nota
          icono="sms"
          texto="Reenvío simulado: en este prototipo no se envía ningún SMS."
        />
      ) : null}
      <Boton
        titulo="Verificar"
        deshabilitado={!codigoValido(codigo)}
        onPress={() => router.push('/municipalidad')}
      />
      <Boton tipo="terciario" titulo="Reenviar código" onPress={() => setReenviado(true)} />
      <Boton tipo="terciario" titulo="Cambiar DNI" onPress={cambiarDni} />
    </Pantalla>
  );
}
