// Abre la app Flutter en Chrome: `pnpm flutter` (o `npm run flutter`) desde la raíz.
// Busca Flutter en el PATH y, si no está, en las carpetas habituales de Windows.
import { spawn, spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const app = resolve(dirname(fileURLToPath(import.meta.url)), '..', 'apps', 'almira_flutter');
const ext = process.platform === 'win32' ? '.bat' : '';
const candidatos = [
  process.env.FLUTTER_ROOT,
  'C:/dev/flutter',
  'C:/src/flutter',
  join(process.env.USERPROFILE ?? '', 'flutter'),
  join(process.env.USERPROFILE ?? '', 'development', 'flutter'),
  join(process.env.HOME ?? '', 'flutter'),
].filter(Boolean);

let flutter = 'flutter';
if (spawnSync(flutter, ['--version'], { shell: true, stdio: 'ignore' }).status !== 0) {
  const raiz = candidatos.find((c) => existsSync(join(c, 'bin', `flutter${ext}`)));
  if (!raiz) {
    console.error('No encuentro Flutter. Instálalo (https://docs.flutter.dev/get-started/install) o define FLUTTER_ROOT con su carpeta.');
    process.exit(1);
  }
  flutter = join(raiz, 'bin', `flutter${ext}`);
}

const conSupabase = existsSync(join(app, 'env.json'));
if (!conSupabase) {
  console.warn('Aviso: falta apps/almira_flutter/env.json (cópialo de env.example.json y completa las claves). Se abre en modo demostración.');
}
const dispositivo = process.argv[2] ?? 'chrome';
const args = ['run', '-d', dispositivo, ...(conSupabase ? ['--dart-define-from-file=env.json'] : [])];

const pub = spawnSync(`"${flutter}"`, ['pub', 'get'], { cwd: app, shell: true, stdio: 'inherit' });
if (pub.status !== 0) process.exit(pub.status ?? 1);
spawn(`"${flutter}"`, args, { cwd: app, shell: true, stdio: 'inherit' }).on('exit', (c) => process.exit(c ?? 0));
