import { router } from 'expo-router';
import type { MetodoIngreso } from './auth';

// Recorrido después de autenticarse (cualquier método): Elige tu municipalidad (02d), Vincula
// tus códigos (02c), Confirma tu celular (02e), consentimiento (03) e Inicio. Si ya aceptó el
// consentimiento, entra directo: la sesión se recuerda.
export function irTrasIngreso(_metodo: MetodoIngreso | null, consentimientoAceptado: boolean) {
  if (consentimientoAceptado) {
    cerrarPantallasDeIngreso();
    router.replace('/inicio');
    return;
  }
  router.push('/municipalidad');
}

// Al entrar, "volver" ya no regresa a las pantallas de ingreso. Se llama antes de que la
// sesión registre el consentimiento; después, router.replace('/inicio').
export function cerrarPantallasDeIngreso() {
  if (router.canDismiss()) router.dismissAll();
}
