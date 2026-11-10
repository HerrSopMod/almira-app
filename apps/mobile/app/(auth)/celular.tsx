import { celularValido, codigoValido, USUARIO_EJEMPLO } from '@almira/shared';
import { Redirect, router } from 'expo-router';
import { useState } from 'react';
import { useAuth } from '@/auth';
import { Destacado, Nota, TituloPantalla } from '@/components/Bloques';
import { BarraSuperior } from '@/components/BarraSuperior';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Pantalla } from '@/components/Pantalla';
import { useSesion } from '@/sesion';
import { supabaseConfigurado } from '@/supabase';

// Pantalla 02e. Confirma el celular con un código SMS para poder avisarte por WhatsApp.
// Es opcional: "Ahora no" sigue sin avisos por celular. Quien ingresó con su celular ya lo
// tiene confirmado. El número no se escribe en logs ni se guarda en la cuenta.
export default function Celular() {
  const { metodoIngreso, vinculos, celularConfirmado, confirmarCelular } = useSesion();
  const { enviarCodigoCelular, verificarCodigoCelular } = useAuth();
  const [celular, setCelular] = useState('');
  const [codigo, setCodigo] = useState('');
  const [enviado, setEnviado] = useState(false);
  const [mensaje, setMensaje] = useState<string | null>(null);
  const [ocupado, setOcupado] = useState(false);

  if (!metodoIngreso) return <Redirect href="/ingreso" />;
  if (vinculos.length === 0) return <Redirect href="/vincular-codigos" />;

  const continuar = () => router.push('/consentimiento');

  const ejecutar = async (accion: () => Promise<string | null>) => {
    setMensaje(null);
    setOcupado(true);
    try {
      setMensaje(await accion());
    } finally {
      setOcupado(false);
    }
  };

  const enviar = () =>
    ejecutar(async () => {
      if (!supabaseConfigurado) {
        setCodigo(USUARIO_EJEMPLO.codigoSmsEjemplo);
        setEnviado(true);
        return null;
      }
      const error = await enviarCodigoCelular(celular);
      if (!error) setEnviado(true);
      return error;
    });

  const verificar = () =>
    ejecutar(async () => {
      const error = supabaseConfigurado ? await verificarCodigoCelular(celular, codigo) : null;
      if (!error) {
        confirmarCelular();
        continuar();
      }
      return error;
    });

  return (
    <Pantalla encabezadoHastaArriba encabezado={<BarraSuperior titulo="" />}>
      <TituloPantalla
        titulo="Confirma tu celular"
        texto="Lo usamos para avisarte por WhatsApp antes de que venzan tus tributos."
      />
      {celularConfirmado ? (
        <>
          <Destacado icono="check-circle" texto="Tu celular ya está confirmado." />
          <Boton titulo="Continuar" onPress={continuar} />
        </>
      ) : (
        <>
          <Campo
            etiqueta="Celular (+51)"
            placeholder="9 dígitos"
            keyboardType="number-pad"
            maxLength={9}
            autoComplete="tel"
            value={celular}
            onChangeText={(texto) => {
              setCelular(texto.replace(/\D/g, ''));
              setEnviado(false);
            }}
          />
          {enviado ? (
            <Campo
              etiqueta="Código de 6 dígitos"
              placeholder="Código que te llegó por SMS"
              keyboardType="number-pad"
              maxLength={6}
              autoComplete="sms-otp"
              value={codigo}
              onChangeText={(texto) => setCodigo(texto.replace(/\D/g, ''))}
            />
          ) : null}
          {mensaje ? <Nota texto={mensaje} /> : null}
          <Boton
            titulo={enviado ? 'Confirmar celular' : 'Recibir código por SMS'}
            icono={enviado ? undefined : 'sms'}
            deshabilitado={ocupado || !celularValido(celular) || (enviado && !codigoValido(codigo))}
            onPress={enviado ? verificar : enviar}
          />
          <Boton tipo="terciario" titulo="Ahora no" onPress={continuar} />
        </>
      )}
    </Pantalla>
  );
}
