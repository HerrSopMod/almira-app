import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';

/// Tope de la foto de perfil (el bucket de Supabase admite hasta 2 MB).
const fotoPerfilMaximaBytes = 2 * 1024 * 1024;

/// Dirección temporal de la foto de perfil de la cuenta, o null si no hay foto (o en modo
/// demostración). Se vuelve a pedir al cambiarla.
final fotoPerfilProvider = FutureProvider.autoDispose<String?>((ref) async {
  // Otra cuenta, otra foto.
  ref.watch(sesionProvider.select((s) => s.usuarioId));
  if (ref.watch(esDemoProvider)) return null;
  return ref.read(repositorioProvider).urlFotoPerfil();
});

/// Foto de perfil en un círculo; sin foto, las iniciales (o un ícono si no hay nombre).
class AvatarPerfil extends ConsumerWidget {
  const AvatarPerfil({super.key, required this.lado, this.nombre});

  final double lado;
  final String? nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(fotoPerfilProvider).valueOrNull;
    final textos = Theme.of(context).textTheme;
    final iniciales = nombre == null ? null : _iniciales(nombre!);
    final respaldo = Container(
      width: lado,
      height: lado,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.onPrimary, shape: BoxShape.circle),
      child: iniciales == null
          ? Icon(Phosphor.user, size: lado * 0.5, color: AppColors.primaryDark)
          : ExcludeSemantics(
              child: Text(
                iniciales,
                style: textos.titleMedium!.copyWith(color: AppColors.primaryDark, fontSize: lado * 0.34),
              ),
            ),
    );
    if (url == null) return respaldo;
    return ClipOval(
      child: Image.network(
        url,
        width: lado,
        height: lado,
        fit: BoxFit.cover,
        semanticLabel: 'Tu foto de perfil',
        // Si la dirección venció o falla la red, se ven las iniciales.
        errorBuilder: (_, _, _) => respaldo,
        loadingBuilder: (_, hijo, progreso) => progreso == null ? hijo : respaldo,
      ),
    );
  }
}

String _iniciales(String nombre) => iniciales(nombre);

/// Ícono del botón «Mi perfil» de la cabecera: la foto si hay, o el ícono de siempre.
class IconoPerfil extends ConsumerWidget {
  const IconoPerfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(fotoPerfilProvider).valueOrNull;
    if (url == null) return const Icon(Phosphor.userCircle);
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(color: AppColors.onPrimary, shape: BoxShape.circle),
      child: const AvatarPerfil(lado: 28),
    );
  }
}

/// Avatar del Perfil: se toca para cambiar la foto (con una insignia de cámara). En modo
/// demostración no se puede cambiar.
class AvatarEditable extends ConsumerWidget {
  const AvatarEditable({super.key, required this.lado, this.nombre, this.editable = true});

  final double lado;
  final String? nombre;
  final bool editable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = AvatarPerfil(lado: lado, nombre: nombre);
    if (!editable) return avatar;
    return Semantics(
      button: true,
      label: 'Cambiar foto de perfil',
      child: GestureDetector(
        onTap: () => cambiarFotoPerfil(context, ref),
        child: SizedBox(
          width: lado + 6,
          height: lado + 6,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(left: 0, top: 0, child: avatar),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const ExcludeSemantics(child: Icon(Phosphor.camera, size: 15, color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Origen { camara, galeria, quitar }

/// Hoja para elegir de dónde sale la foto (cámara o galería) o quitarla.
Future<void> cambiarFotoPerfil(BuildContext context, WidgetRef ref) async {
  final hayFoto = ref.read(fotoPerfilProvider).valueOrNull != null;
  final eleccion = await showModalBottomSheet<_Origen>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margen, 0, AppSpacing.margen, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Foto de perfil', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _Origen.camara),
            icon: const Icon(Phosphor.camera),
            label: const Text('Tomar foto'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, _Origen.galeria),
            icon: const Icon(Phosphor.images),
            label: const Text('Elegir de la galería'),
          ),
          if (hayFoto) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, _Origen.quitar),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.2),
              ),
              icon: const Icon(Phosphor.trash),
              label: const Text('Quitar foto'),
            ),
          ],
        ],
      ),
    ),
  );
  if (eleccion == null || !context.mounted) return;

  final repositorio = ref.read(repositorioProvider);
  try {
    if (eleccion == _Origen.quitar) {
      await repositorio.quitarFotoPerfil();
      ref.invalidate(fotoPerfilProvider);
      if (context.mounted) mostrarMensaje(context, 'Quitamos tu foto.');
      return;
    }
    final archivo = await ImagePicker().pickImage(
      source: eleccion == _Origen.camara ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front,
    );
    if (archivo == null) return;
    final bytes = await archivo.readAsBytes();
    if (bytes.length > fotoPerfilMaximaBytes) {
      if (context.mounted) mostrarMensaje(context, 'La foto pesa demasiado. Elige otra.');
      return;
    }
    await repositorio.guardarFotoPerfil(bytes);
    ref.invalidate(fotoPerfilProvider);
    if (context.mounted) mostrarMensaje(context, 'Listo, cambiamos tu foto.');
  } on PlatformException catch (error) {
    final sinPermiso = error.code.contains('denied');
    if (context.mounted) {
      mostrarMensaje(
        context,
        sinPermiso
            ? 'Sin permiso para usar la ${eleccion == _Origen.camara ? 'cámara' : 'galería'}. Actívalo en los ajustes del teléfono.'
            : 'No pudimos abrir la ${eleccion == _Origen.camara ? 'cámara' : 'galería'}. Inténtalo de nuevo.',
      );
    }
  } catch (error) {
    if (context.mounted) mostrarMensaje(context, ErrorApp.de(error).detalle);
  }
}
