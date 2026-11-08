import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { Destacado, Nota, Rotulo, TituloPantalla } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { InterruptoresConsentimiento } from '@/components/InterruptoresConsentimiento';
import { Pantalla } from '@/components/Pantalla';
import { useDatosMunicipales, useSesion } from '@/sesion';

// Pantalla 03 (maqueta 03-consentimiento). Los permisos se guardan solo en memoria.
export default function Consentimiento() {
  const { municipalidad } = useDatosMunicipales();
  const { consentimientos, guardarConsentimientos } = useSesion();
  const [permisos, setPermisos] = useState(consentimientos);
  // Si los cambia en Privacidad y mis datos (desde "Leer la política"), se reflejan aquí.
  useEffect(() => setPermisos(consentimientos), [consentimientos]);

  const entrar = () => {
    guardarConsentimientos(permisos);
    // Al entrar, "volver" ya no regresa a las pantallas de ingreso.
    if (router.canDismiss()) router.dismissAll();
    router.replace('/inicio');
  };

  return (
    <Pantalla encabezadoHastaArriba encabezado={<BarraSuperior titulo="Paso 3 de 3" />}>
      <TituloPantalla
        titulo="Tus datos, tus reglas"
        texto="Elige qué quieres usar. Puedes cambiarlo cuando quieras en Mi perfil."
      />
      <Destacado
        icono="verified-user"
        titulo={`${municipalidad.nombre} es responsable de tus datos`}
        texto="Almira solo los trata por encargo de la municipalidad (Ley N.° 29733)."
      />
      <Rotulo texto="Autoriza lo que quieras usar" />
      <InterruptoresConsentimiento valor={permisos} onCambiar={setPermisos} />
      <Nota
        icono="block"
        texto="Nunca vendemos tus datos ni te calificamos como «buen» o «mal» pagador."
      />
      <Boton titulo="Aceptar y entrar" onPress={entrar} />
      <Boton
        tipo="terciario"
        titulo="Leer la política de privacidad"
        onPress={() => router.push('/privacidad')}
      />
    </Pantalla>
  );
}
