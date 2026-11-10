import AsyncStorage from '@react-native-async-storage/async-storage';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

// Dónde guarda Supabase la sesión del vecino. En el celular va cifrada en el llavero del
// sistema (SecureStore); en la web no existe, así que usa el almacenamiento del navegador.
// SecureStore limita cada valor a unos 2 KB y la sesión de Supabase pesa más, por eso se
// parte en trozos.
const TAMANO_TROZO = 1800;

const claveTrozos = (clave: string) => `${clave}.trozos`;
const claveTrozo = (clave: string, indice: number) => `${clave}.${indice}`;

async function leerSeguro(clave: string): Promise<string | null> {
  const cantidad = Number(await SecureStore.getItemAsync(claveTrozos(clave)));
  if (!cantidad) return null;
  const trozos: string[] = [];
  for (let i = 0; i < cantidad; i += 1) {
    const trozo = await SecureStore.getItemAsync(claveTrozo(clave, i));
    if (trozo === null) return null;
    trozos.push(trozo);
  }
  return trozos.join('');
}

async function borrarSeguro(clave: string): Promise<void> {
  const cantidad = Number(await SecureStore.getItemAsync(claveTrozos(clave)));
  for (let i = 0; i < cantidad; i += 1) {
    await SecureStore.deleteItemAsync(claveTrozo(clave, i));
  }
  await SecureStore.deleteItemAsync(claveTrozos(clave));
}

async function guardarSeguro(clave: string, valor: string): Promise<void> {
  await borrarSeguro(clave);
  const cantidad = Math.ceil(valor.length / TAMANO_TROZO);
  for (let i = 0; i < cantidad; i += 1) {
    await SecureStore.setItemAsync(
      claveTrozo(clave, i),
      valor.slice(i * TAMANO_TROZO, (i + 1) * TAMANO_TROZO),
    );
  }
  await SecureStore.setItemAsync(claveTrozos(clave), String(cantidad));
}

export const almacenSesion =
  Platform.OS === 'web'
    ? AsyncStorage
    : {
        getItem: leerSeguro,
        setItem: guardarSeguro,
        removeItem: borrarSeguro,
      };
