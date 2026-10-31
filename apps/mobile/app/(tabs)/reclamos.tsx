import {
  colors,
  ETIQUETA_ESTADO_RECLAMO,
  ETIQUETA_TIPO_RECLAMO,
  spacing,
  type EstadoReclamo,
  type TipoReclamo,
} from '@almira/shared';
import { useState } from 'react';
import { Linking, StyleSheet, View } from 'react-native';
import {
  Destacado,
  Insignia,
  Progreso,
  Separador,
  Tarjeta,
  Vacio,
  type Tono,
} from '@/components/Bloques';
import { Boton } from '@/components/Boton';
import { Campo } from '@/components/Campo';
import { Encabezado } from '@/components/Encabezado';
import { Opcion } from '@/components/Opcion';
import { Pantalla } from '@/components/Pantalla';
import { Texto } from '@/components/Texto';
import { useDatosMunicipales, useSesion } from '@/sesion';

const PASOS = ['1. Tipo', '2. Foto y GPS', '3. Detalle'];
const TONO_ESTADO: Record<EstadoReclamo, Tono> = {
  en_atencion: 'atencion',
  derivado: 'atencion',
  resuelto: 'exito',
};

export default function Reclamos() {
  const { agregarReclamo } = useSesion();
  const { municipalidad, vecino, reclamos } = useDatosMunicipales();

  const [paso, setPaso] = useState(0);
  const [tipo, setTipo] = useState<TipoReclamo>('basura');
  const [evidencia, setEvidencia] = useState(false);
  const [detalle, setDetalle] = useState('');

  const activos = reclamos.filter((reclamo) => reclamo.estado !== 'resuelto').length;

  const reiniciar = () => {
    setPaso(0);
    setEvidencia(false);
    setDetalle('');
  };

  const enviar = () => {
    if (!vecino) return;
    const correlativo = String(1000 + reclamos.length);
    agregarReclamo({
      id: `nuevo-${correlativo}`,
      municipalidadId: municipalidad.id,
      vecinoId: vecino.id,
      codigo: `REC-2025-${correlativo}`,
      tipo,
      titulo: ETIQUETA_TIPO_RECLAMO[tipo],
      descripcion: detalle,
      estado: 'en_atencion',
      area: null,
      fotoRuta: 'ejemplo/nuevo.jpg',
      latitud: -12.1198,
      longitud: -77.0294,
      plazo: null,
    });
    reiniciar();
  };

  return (
    <Pantalla conPestanas encabezado={<Encabezado titulo="Reclamos" conAvisos />}>
      <View style={estilos.grupo}>
        <Texto variante="headlineLg">Reclamos ciudadanos</Texto>
        <Texto color={colors.textSecondary}>{municipalidad.nombre}</Texto>
      </View>

      {paso === 0 ? (
        <>
          <Destacado
            icono="verified"
            titulo="Atención vecinal con evidencia"
            texto="Cada foto registra fecha, hora y ubicación para acelerar la fiscalización."
          />
          <Boton
            icono="add-a-photo"
            titulo="Nuevo reclamo con evidencia"
            deshabilitado={!vecino}
            onPress={() => setPaso(1)}
          />
        </>
      ) : (
        <View style={estilos.grupo}>
          <Texto variante="labelSm" color={colors.textSecondary}>
            Paso {paso} de 3 · {PASOS[paso - 1]}
          </Texto>
          <Progreso porcentaje={(paso / 3) * 100} />
          {paso === 1
            ? (Object.keys(ETIQUETA_TIPO_RECLAMO) as TipoReclamo[]).map((opcion) => (
                <Opcion
                  key={opcion}
                  titulo={ETIQUETA_TIPO_RECLAMO[opcion]}
                  seleccionada={tipo === opcion}
                  onPress={() => setTipo(opcion)}
                />
              ))
            : null}
          {paso === 2 ? (
            <Boton
              tipo="secundario"
              icono="photo-camera"
              titulo={evidencia ? 'Foto y ubicación de ejemplo listas' : 'Agregar foto y ubicación'}
              onPress={() => setEvidencia(true)}
            />
          ) : null}
          {paso === 3 ? (
            <Campo
              etiqueta="Detalle del reclamo"
              placeholder="Describe lo que ocurre"
              value={detalle}
              onChangeText={setDetalle}
            />
          ) : null}
          <Boton
            titulo={paso === 3 ? 'Enviar reclamo' : 'Continuar'}
            deshabilitado={(paso === 2 && !evidencia) || (paso === 3 && detalle.trim() === '')}
            onPress={() => (paso === 3 ? enviar() : setPaso(paso + 1))}
          />
          <Boton tipo="terciario" titulo="Cancelar" onPress={reiniciar} />
        </View>
      )}

      <View style={estilos.grupo}>
        <Texto variante="headlineMd">Tus reclamos registrados</Texto>
        <Texto variante="bodyMd" color={colors.textSecondary}>
          {activos} {activos === 1 ? 'activo' : 'activos'}
        </Texto>
        {reclamos.length === 0 ? (
          <Vacio texto="No tienes reclamos en esta municipalidad." />
        ) : (
          <Tarjeta>
            {reclamos.map((reclamo, indice) => (
              <View key={reclamo.id} style={estilos.grupo}>
                {indice > 0 ? <Separador /> : null}
                <Texto variante="labelSm" color={colors.textSecondary}>
                  {reclamo.codigo}
                </Texto>
                <Texto variante="bodyLgMedium">{reclamo.titulo}</Texto>
                <Insignia
                  texto={ETIQUETA_ESTADO_RECLAMO[reclamo.estado]}
                  tono={TONO_ESTADO[reclamo.estado]}
                />
                {reclamo.descripcion ? (
                  <Texto variante="bodyMd">{reclamo.descripcion}</Texto>
                ) : null}
                {reclamo.latitud !== null ? (
                  <Texto variante="bodyMd" color={colors.textSecondary}>
                    Coordenadas: {reclamo.latitud}, {reclamo.longitud}
                  </Texto>
                ) : null}
                {reclamo.area ? (
                  <Texto variante="bodyMd" color={colors.textSecondary}>
                    {reclamo.area}
                  </Texto>
                ) : null}
                {reclamo.plazo ? (
                  <Texto variante="bodyMd" color={colors.textSecondary}>
                    {reclamo.plazo}
                  </Texto>
                ) : null}
              </View>
            ))}
          </Tarjeta>
        )}
      </View>

      {municipalidad.telefonoAyuda ? (
        <View style={estilos.grupo}>
          <Tarjeta>
            <Texto variante="bodyLgMedium">¿Necesitas ayuda con un reclamo?</Texto>
            <Texto variante="bodyMd" color={colors.textSecondary}>
              Llama a la central {municipalidad.telefonoAyuda}
            </Texto>
          </Tarjeta>
          <Boton
            tipo="secundario"
            icono="call"
            titulo="Llamar"
            onPress={() => {
              const numero = municipalidad.telefonoAyuda?.split(' ')[0]?.replace(/\D/g, '');
              if (numero) Linking.openURL(`tel:${numero}`);
            }}
          />
        </View>
      ) : null}
    </Pantalla>
  );
}

const estilos = StyleSheet.create({
  grupo: { gap: spacing.sm },
});
