import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/iconos.dart';
import '../../shared/services/proveedores.dart';

/// Direcciones temporales de las fotos de una obra: (municipalidad, obra). Sin fotos, en modo
/// demostración o sin conexión, la lista queda vacía y la pantalla no muestra nada.
final fotosObraProvider = FutureProvider.autoDispose.family<List<String>, (String, String)>((ref, clave) async {
  if (ref.watch(esDemoProvider)) return const [];
  try {
    return await ref.read(repositorioProvider).urlsFotosObra(clave.$1, clave.$2);
  } catch (_) {
    // Las fotos acompañan al detalle: si no cargan, el detalle sigue completo.
    return const [];
  }
});

/// Fotos de la obra en una tira que se desliza. Al tocar una, se abre grande.
class FotosObra extends ConsumerWidget {
  const FotosObra({super.key, required this.municipalidadId, required this.obraId});

  final String municipalidadId;
  final String obraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = ref.watch(fotosObraProvider((municipalidadId, obraId))).valueOrNull ?? const <String>[];
    if (urls.isEmpty) return const SizedBox.shrink();
    final ancho = MediaQuery.sizeOf(context).width - AppSpacing.margen * 2;
    final unica = urls.length == 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grupo),
      child: SizedBox(
        height: ancho * 0.62,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) {
            final etiqueta = 'Foto ${i + 1} de ${urls.length} de la obra';
            return Semantics(
              button: true,
              label: etiqueta,
              child: GestureDetector(
                onTap: () => _abrir(context, urls, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.destacado),
                  child: SizedBox(
                    width: unica ? ancho : ancho * 0.86,
                    child: _Imagen(urls[i], ajuste: BoxFit.cover),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _abrir(BuildContext context, List<String> urls, int inicial) {
    showDialog<void>(
      context: context,
      builder: (_) => _VisorFotos(urls: urls, inicial: inicial),
    );
  }
}

class _Imagen extends StatelessWidget {
  const _Imagen(this.url, {required this.ajuste});

  final String url;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) => Image.network(
    url,
    fit: ajuste,
    width: double.infinity,
    height: double.infinity,
    excludeFromSemantics: true,
    loadingBuilder: (_, hijo, progreso) => progreso == null ? hijo : const ColoredBox(color: AppColors.surfaceSubtle),
    errorBuilder: (_, _, _) => const ColoredBox(
      color: AppColors.surfaceSubtle,
      child: Center(child: Icon(Phosphor.imageBroken, color: AppColors.textSecondary)),
    ),
  );
}

class _VisorFotos extends StatefulWidget {
  const _VisorFotos({required this.urls, required this.inicial});

  final List<String> urls;
  final int inicial;

  @override
  State<_VisorFotos> createState() => _VisorFotosState();
}

class _VisorFotosState extends State<_VisorFotos> {
  late final PageController _control = PageController(initialPage: widget.inicial);
  late int _actual = widget.inicial;

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Dialog.fullscreen(
      backgroundColor: AppColors.textPrimary,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _control,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _actual = i),
              itemBuilder: (_, i) => InteractiveViewer(
                maxScale: 4,
                child: Center(child: Image.network(widget.urls[i], fit: BoxFit.contain, excludeFromSemantics: true)),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Phosphor.x, color: AppColors.onPrimary),
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                bottom: AppSpacing.lg,
                left: 0,
                right: 0,
                child: Text(
                  '${_actual + 1} de ${widget.urls.length}',
                  textAlign: TextAlign.center,
                  style: textos.bodyMedium!.copyWith(color: AppColors.onPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
