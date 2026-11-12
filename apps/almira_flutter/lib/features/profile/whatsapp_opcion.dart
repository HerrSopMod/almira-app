import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/models/preferencia_whatsapp.dart';
import '../../shared/services/proveedores.dart';

/// Estado de los recordatorios por WhatsApp de la cuenta. Se vuelve a leer al cambiarlos.
final preferenciaWhatsappProvider = FutureProvider.autoDispose<PreferenciaWhatsapp?>((ref) async {
  // Otra cuenta, otro estado.
  ref.watch(sesionProvider.select((s) => s.usuarioId));
  if (ref.watch(esDemoProvider)) return null;
  return ref.read(repositorioProvider).preferenciaWhatsapp();
});

const _mensajeNoSeEnvio =
    'No pudimos enviar el mensaje a ese número. Revisa que tenga WhatsApp activo e intenta de nuevo.';

/// Interruptor «Recordatorios por WhatsApp» de Mi perfil. Al activarlo abre una hoja con el
/// celular y el consentimiento; ya activo, muestra el número enmascarado y deja cambiarlo o apagarlo.
class OpcionWhatsapp extends ConsumerWidget {
  const OpcionWhatsapp({super.key});

  Future<void> _activar(BuildContext context, WidgetRef ref, {String? celularActual}) async {
    final activado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => HojaActivarWhatsapp(celularInicial: celularActual),
    );
    if (activado != true) return;
    ref.invalidate(preferenciaWhatsappProvider);
    if (context.mounted) mostrarMensaje(context, 'Recordatorios por WhatsApp activados.');
  }

  Future<void> _desactivar(BuildContext context, WidgetRef ref) async {
    final acepta = await confirmar(
      context,
      titulo: '¿Dejar de recibir recordatorios?',
      mensaje: 'Puedes volver a activarlos cuando quieras.',
      textoConfirmar: 'Desactivar',
      destructivo: true,
    );
    if (!acepta) return;
    try {
      await ref.read(repositorioProvider).desactivarWhatsapp();
      ref.invalidate(preferenciaWhatsappProvider);
      if (context.mounted) mostrarMensaje(context, 'Recordatorios por WhatsApp desactivados.');
    } catch (error) {
      if (context.mounted) mostrarMensaje(context, ErrorApp.de(error).detalle);
    }
  }

  Future<void> _gestionar(BuildContext context, WidgetRef ref, PreferenciaWhatsapp preferencia) async {
    final accion = await showModalBottomSheet<_AccionGestion>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _HojaGestion(numero: preferencia.numeroEnmascarado),
    );
    if (!context.mounted) return;
    switch (accion) {
      case _AccionGestion.cambiar:
        await _activar(context, ref, celularActual: preferencia.celular);
      case _AccionGestion.desactivar:
        await _desactivar(context, ref);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencia = ref.watch(preferenciaWhatsappProvider);
    final datos = preferencia.valueOrNull;
    final activo = datos?.activo == true;
    final textos = Theme.of(context).textTheme;

    return ListTile(
      leading: const Icon(Icons.chat_outlined),
      title: const Text('Recordatorios por WhatsApp'),
      subtitle: activo
          ? Text('Activo en ${datos!.numeroEnmascarado}')
          : (preferencia.hasError ? Text('No pudimos leer el estado', style: textos.bodySmall) : null),
      trailing: Switch(
        value: activo,
        // Mientras carga, el interruptor espera.
        onChanged: preferencia.isLoading && datos == null
            ? null
            : (quiere) => quiere ? _activar(context, ref) : _desactivar(context, ref),
      ),
      onTap: activo ? () => _gestionar(context, ref, datos!) : null,
    );
  }
}

enum _AccionGestion { cambiar, desactivar }

/// Opciones de unos recordatorios ya activos: botones de ancho completo.
class _HojaGestion extends StatelessWidget {
  const _HojaGestion({required this.numero});

  final String numero;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.margen, 0, AppSpacing.margen, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Recordatorios por WhatsApp', style: textos.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('Activo en $numero', style: textos.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () => Navigator.pop(context, _AccionGestion.cambiar),
            child: const Text('Cambiar número'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, _AccionGestion.desactivar),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.2),
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }
}

/// Hoja para activar los recordatorios: celular (+51, 9 dígitos), consentimiento y «Activar».
/// Se cierra con `true` cuando quedaron activos.
class HojaActivarWhatsapp extends ConsumerStatefulWidget {
  const HojaActivarWhatsapp({super.key, this.celularInicial});

  /// Al cambiar de número, el actual aparece escrito.
  final String? celularInicial;

  @override
  ConsumerState<HojaActivarWhatsapp> createState() => _HojaActivarWhatsappState();
}

class _HojaActivarWhatsappState extends ConsumerState<HojaActivarWhatsapp> {
  late final _celular = TextEditingController(text: widget.celularInicial ?? '');
  bool _acepta = false;
  bool _ocupado = false;
  bool _tocado = false;
  String? _error;

  @override
  void dispose() {
    _celular.dispose();
    super.dispose();
  }

  bool get _puedeActivar => validarCelularWhatsapp(_celular.text) == null && _acepta && !_ocupado;

  Future<void> _activar() async {
    if (!_puedeActivar) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    String? error;
    try {
      final resultado = await ref.read(repositorioProvider).activarWhatsapp(_celular.text.trim());
      switch (resultado) {
        case ResultadoWhatsapp.activado:
          if (mounted) Navigator.pop(context, true);
          return;
        case ResultadoWhatsapp.sinVinculo:
          error = 'Vincula tu cuponera para activar los recordatorios.';
        case ResultadoWhatsapp.limite:
          error = 'Hiciste varios intentos hoy. Inténtalo de nuevo mañana.';
        case ResultadoWhatsapp.noSeEnvio:
          error = _mensajeNoSeEnvio;
      }
    } catch (e) {
      error = ErrorApp.de(e).sinConexion ? ErrorApp.de(e).detalle : _mensajeNoSeEnvio;
    }
    if (mounted) {
      setState(() {
        _ocupado = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    // El teclado sube la hoja: el contenido se desplaza y nada queda tapado.
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: duracionDe(context, 150),
      padding: EdgeInsets.only(bottom: teclado),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(AppSpacing.margen, 0, AppSpacing.margen, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Recordatorios por WhatsApp', style: textos.titleLarge, textAlign: TextAlign.center),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _celular,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
              autovalidateMode: _tocado ? AutovalidateMode.always : AutovalidateMode.disabled,
              onChanged: (_) => setState(() => _tocado = true),
              onFieldSubmitted: (_) => _activar(),
              validator: validarCelularWhatsapp,
              decoration: const InputDecoration(
                labelText: 'Celular',
                prefixText: '+51 ',
                prefixIcon: Icon(Icons.smartphone_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _acepta,
              onChanged: _ocupado ? null : (v) => setState(() => _acepta = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(textoConsentimientoWhatsapp, style: textos.bodyMedium!.copyWith(color: AppColors.textPrimary)),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Aviso(_error!, tono: Tono.error),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _puedeActivar ? _activar : null,
              child: _ocupado
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Activar'),
            ),
          ],
        ),
      ),
    );
  }
}
