import { colors, spacing } from '@almira/shared';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { useAuth } from '@/auth';
import { Nota, Rotulo, Tarjeta } from './Bloques';
import { Boton } from './Boton';
import { Campo } from './Campo';
import { Texto } from './Texto';
import { supabaseConfigurado } from '@/supabase';

const celularValido = (valor: string) => /^9\d{8}$/.test(valor);

// Vincula el WhatsApp del vecino: confirma el celular con un código por SMS y luego Almira le
// escribe por WhatsApp. Solo se muestra con Supabase conectado y una sesión real.
export function VincularWhatsapp() {
  const { sesion, pedirCodigoVinculo, confirmarVinculo } = useAuth();
  const [celular, setCelular] = useState('');
  const [codigo, setCodigo] = useState('');
  const [codigoEnviado, setCodigoEnviado] = useState(false);
  const [ocupado, setOcupado] = useState(false);
  const [mensaje, setMensaje] = useState<string | null>(null);
  const [vinculado, setVinculado] = useState(false);

  if (!supabaseConfigurado || !sesion) return null;

  const ejecutar = async (accion: () => Promise<void>) => {
    setMensaje(null);
    setOcupado(true);
    try {
      await accion();
    } finally {
      setOcupado(false);
    }
  };

  const pedir = () =>
    ejecutar(async () => {
      const error = await pedirCodigoVinculo(celular);
      if (error) setMensaje(error);
      else setCodigoEnviado(true);
    });

  const confirmar = () =>
    ejecutar(async () => {
      const resultado = await confirmarVinculo(celular, codigo);
      setMensaje(resultado.mensaje);
      if (resultado.ok) setVinculado(true);
    });

  return (
    <View style={estilos.seccion}>
      <Rotulo texto="Vincula tu WhatsApp" />
      <Tarjeta style={estilos.tarjeta}>
        <Texto variante="bodyMd" color={colors.textSecondary}>
          Confirmamos tu celular con un código por SMS y luego te escribimos por WhatsApp.
        </Texto>
        <Campo
          etiqueta="Celular (+51)"
          placeholder="9 dígitos"
          keyboardType="number-pad"
          maxLength={9}
          editable={!vinculado}
          value={celular}
          onChangeText={(t) => {
            setCelular(t.replace(/\D/g, ''));
            setCodigoEnviado(false);
          }}
        />
        {codigoEnviado && !vinculado ? (
          <Campo
            etiqueta="Código de 6 dígitos"
            keyboardType="number-pad"
            maxLength={6}
            value={codigo}
            onChangeText={(t) => setCodigo(t.replace(/\D/g, ''))}
          />
        ) : null}
      </Tarjeta>
      {mensaje ? <Nota texto={mensaje} /> : null}
      {vinculado ? null : (
        <Boton
          icono={codigoEnviado ? 'check' : 'sms'}
          titulo={codigoEnviado ? 'Confirmar y vincular' : 'Enviar código por SMS'}
          deshabilitado={
            ocupado || !celularValido(celular) || (codigoEnviado && codigo.length !== 6)
          }
          onPress={codigoEnviado ? confirmar : pedir}
        />
      )}
    </View>
  );
}

const estilos = StyleSheet.create({
  seccion: { gap: spacing.sm },
  tarjeta: { gap: spacing.md },
});
