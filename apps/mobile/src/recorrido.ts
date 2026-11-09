import { router } from 'expo-router';
import type { MetodoIngreso } from './auth';

// Recorrido después de autenticarse. Con Google o correo: Vincula tu DNI (02c), código
// (02b), Elige tu municipalidad (02d), consentimiento (03) e Inicio. Con celular, el código
// ya se verificó en el ingreso: pasa directo a 02d. Si ya aceptó el consentimiento, entra.
export function irTrasIngreso(metodo: MetodoIngreso | null, consentimientoAceptado: boolean) {
  if (consentimientoAceptado) {
    cerrarPantallasDeIngreso();
    router.replace('/inicio');
    return;
  }
  router.push(metodo === 'celular' ? '/municipalidad' : '/vincular-dni');
}

// Al entrar, "volver" ya no regresa a las pantallas de ingreso. Se llama antes de que la
// sesión registre el consentimiento; después, router.replace('/inicio').
export function cerrarPantallasDeIngreso() {
  if (router.canDismiss()) router.dismissAll();
}
