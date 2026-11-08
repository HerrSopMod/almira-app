import { documentoValido, USUARIO_EJEMPLO } from '@almira/shared';
import { Redirect, router } from 'expo-router';
import { useState } from 'react';
import { Destacado, Nota, PiePrototipo, TituloPantalla } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { CampoDocumento } from '@/components/CampoDocumento';
import { Pantalla } from '@/components/Pantalla';
import { DOCUMENTO_EJEMPLO, useSesion } from '@/sesion';

// Pantalla 02c (Stitch 3). Solo se llega después de "Continuar con Google": la
// cuenta de Google se vincula al documento con el que figura en el padrón.
export default function VincularDni() {
  const { metodoIngreso, nombreGoogle } = useSesion();
  const [documento, setDocumento] = useState(DOCUMENTO_EJEMPLO);

  if (metodoIngreso !== 'google') return <Redirect href="/ingreso" />;

  return (
    <Pantalla encabezadoHastaArriba encabezado={<BarraSuperior titulo="Paso 1 de 3" />}>
      <TituloPantalla
        titulo="Vincula tu DNI"
        texto={`Hola, ${nombreGoogle ?? USUARIO_EJEMPLO.nombre}. Con tu documento encontramos tus tributos en el padrón municipal.`}
      />
      <CampoDocumento valor={documento} onCambiar={setDocumento} />
      <Destacado
        icono="sms"
        texto="Te enviaremos un código SMS al celular registrado en el padrón municipal."
      />
      <Boton
        icono="sms"
        titulo="Recibir código por SMS"
        deshabilitado={!documentoValido(documento)}
        onPress={() => router.push('/codigo')}
      />
      <Nota
        icono="verified-user"
        texto="Tus datos se tratan según la Ley N.° 29733 de Protección de Datos Personales."
      />
      <Nota texto="Datos de ejemplo. En este prototipo no se envía ni se guarda ninguna información." />
      <PiePrototipo />
    </Pantalla>
  );
}
