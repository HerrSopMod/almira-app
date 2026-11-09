import { Redirect } from 'expo-router';

// Al abrir la app se ve directamente el ingreso: Google y correo con contraseña.
export default function Raiz() {
  return <Redirect href="/ingreso" />;
}
