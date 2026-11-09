// Importaciones "?raw" de Vite/Vitest: el archivo llega como texto (usado en las pruebas).
declare module '*?raw' {
  const texto: string;
  export default texto;
}
