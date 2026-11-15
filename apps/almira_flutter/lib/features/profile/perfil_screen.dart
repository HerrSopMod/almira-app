import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/iconos.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../core/errors/error_app.dart';
import '../../core/utils/formato.dart';
import '../../core/widgets/app_confirm_dialog.dart';
import '../../core/widgets/componentes.dart';
import '../../shared/services/proveedores.dart';
import '../payments/pagos_logica.dart';
import '../complaints/piezas_lista.dart';
import 'whatsapp_opcion.dart';

/// Mi perfil: cabecera compacta y opciones agrupadas. Solo muestra el nombre
/// y el código de contribuyente; nunca el DNI ni el teléfono.
class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final acepta = await confirmar(
      context,
      titulo: '¿Cerrar sesión?',
      mensaje: 'Tendrás que volver a ingresar para ver tu información.',
      textoConfirmar: 'Cerrar sesión',
      destructivo: true,
    );
    // Al cerrarse, la app vuelve sola al ingreso.
    if (acepta) await ref.read(sesionProvider.notifier).cerrarSesion();
  }

  Future<void> _crearClave(BuildContext context, WidgetRef ref) async {
    final clave = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogoClave(),
    );
    if (clave == null || !context.mounted) return;
    try {
      await ref.read(servicioAuthProvider).crearClaveWeb(clave);
      if (context.mounted) mostrarMensaje(context, 'Tu clave web quedó guardada.');
    } catch (error) {
      if (context.mounted) mostrarMensaje(context, ErrorApp.de(error).detalle);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(vistaProvider).valueOrNull;
    final sesion = ref.watch(sesionProvider);
    final textoGrande = ref.watch(textoGrandeProvider);
    final esDemo = ref.watch(esDemoProvider);
    final textos = Theme.of(context).textTheme;
    final vecino = v?.vecino;
    final nombre = vecino?.nombre ?? sesion.cuenta?.nombre;
    final codigo = vecino?.codigoContribuyente;

    // Barra compacta turquesa (con la flecha atrás), la identidad del vecino en el mismo color y
    // las opciones en la hoja blanca que se monta encima.
    return Scaffold(
      appBar: AppBar(
        // Sin pantalla anterior no hay flecha: el título toma el margen de la pantalla.
        titleSpacing: context.canPop() ? null : AppSpacing.margen,
        title: const Text('Mi perfil'),
        actions: [
          if (esDemo)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.lg),
              child: Center(child: EtiquetaDemo(sobreTurquesa: true)),
            ),
        ],
      ),
      body: ColoredBox(
        color: AppColors.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ColoredBox(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margen,
                  AppSpacing.sm,
                  AppSpacing.margen,
                  AppSpacing.solapeHoja + AppSpacing.lg,
                ),
                child: SobreTurquesa(
                  child: Row(
                    children: [
                      Container(
                        width: AppSpacing.cajaGrande,
                        height: AppSpacing.cajaGrande,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.onPrimary, shape: BoxShape.circle),
                        child: nombre == null
                            ? const Icon(Phosphor.user, color: AppColors.primaryDark)
                            : ExcludeSemantics(
                                child: Text(
                                  iniciales(nombre),
                                  style: textos.titleMedium!.copyWith(color: AppColors.primaryDark),
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre == null ? 'Tu cuenta' : tipoTitulo(nombre),
                              style: textos.titleLarge!.copyWith(color: AppColors.onPrimary),
                            ),
                            if (codigo != null || vecino == null)
                              Text(
                                codigo == null ? 'Sin código vinculado' : 'Contribuyente $codigo',
                                style: textos.bodyMedium!.copyWith(color: AppColors.onPrimary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            HojaBlanca(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.margen,
                AppSpacing.xl,
                AppSpacing.margen,
                AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                        _Grupo(
                          titulo: 'Cuenta y predio',
                          filas: [
                            for (final predio in v?.predios ?? const [])
                              FilaLista(titulo: predio.direccion, detalle: DetalleFila('Predio ${predio.codigo}')),
                            FilaLista(
                              titulo: vecino == null ? 'Vincular cuponera' : 'Vincular otra cuponera',
                              alTocar: () => context.push(Rutas.vincular),
                            ),
                            FilaLista(
                              titulo: 'Municipalidad',
                              detalle: v?.municipalidad == null ? null : DetalleFila(v!.municipalidad!.nombre),
                              alTocar: () => context.push(Rutas.municipalidad),
                            ),
                          ],
                        ),
                        _Grupo(
                          titulo: 'Preferencias',
                          filas: [
                            if (!esDemo)
                              FilaLista(
                                titulo: 'Clave web',
                                detalle: DetalleFila('Para entrar con tu correo o tu cuponera'),
                                alTocar: () => _crearClave(context, ref),
                              ),
                            FilaLista(titulo: 'Avisos y canales', alTocar: () => context.push(Rutas.avisos)),
                            // Los recordatorios necesitan la cuenta real y un contribuyente vinculado.
                            if (!esDemo && vecino != null) const OpcionWhatsapp(),
                            FilaLista(titulo: 'Privacidad', alTocar: () => context.push(Rutas.privacidad)),
                            FilaInterruptor(
                              titulo: 'Texto más grande',
                              valor: textoGrande,
                              alCambiar: ref.read(textoGrandeProvider.notifier).cambiar,
                            ),
                          ],
                        ),
                        _Grupo(
                          titulo: 'Trámites y ayuda',
                          filas: [
                            FilaLista(
                              titulo: 'Constancias de pago',
                              alTocar: () => context.go('${Rutas.pagos}?filtro=${FiltroDeuda.pagados.name}'),
                            ),
                            FilaLista(titulo: 'Atención', alTocar: () => context.push(Rutas.atencion)),
                          ],
                        ),
                        // Peligro suave, según la guía: borde gris y texto en rojo oscuro.
                        OutlinedButton(
                          onPressed: () => _cerrarSesion(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Text(esDemo ? 'Salir de la demostración' : 'Cerrar sesión'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grupo de opciones: rótulo en mayúsculas pequeñas y filas con divisor, sin caja.
class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.filas});

  final String titulo;
  final List<Widget> filas;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RotuloSeccion(titulo),
            const SizedBox(height: AppSpacing.xs),
            ListaFilas(filas: filas),
          ],
        ),
      );
}

/// Pide la clave web dos veces. La clave no se guarda en el teléfono.
class _DialogoClave extends StatefulWidget {
  const _DialogoClave();

  @override
  State<_DialogoClave> createState() => _DialogoClaveState();
}

class _DialogoClaveState extends State<_DialogoClave> {
  final _formulario = GlobalKey<FormState>();
  final _clave = TextEditingController();
  final _repetir = TextEditingController();
  bool _ver = false;

  @override
  void dispose() {
    _clave.dispose();
    _repetir.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppConfirmDialog(
    titulo: 'Clave web',
    textoConfirmar: 'Guardar',
    alConfirmar: () {
      if (_formulario.currentState!.validate()) Navigator.pop(context, _clave.text);
    },
    alCancelar: () => Navigator.pop(context),
    contenido: Form(
      key: _formulario,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _clave,
            obscureText: !_ver,
            decoration: InputDecoration(
              labelText: 'Nueva clave',
              helperText: 'Mínimo 8 caracteres.',
              suffixIcon: IconButton(
                tooltip: _ver ? 'Ocultar clave' : 'Mostrar clave',
                icon: Icon(
                  _ver
                      ? Phosphor.eyeSlash
                      : Phosphor.eye,
                ),
                onPressed: () => setState(() => _ver = !_ver),
              ),
            ),
            validator: (v) =>
                (v ?? '').length >= 8 ? null : 'Usa al menos 8 caracteres.',
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _repetir,
            obscureText: !_ver,
            decoration: const InputDecoration(labelText: 'Repite tu clave'),
            validator: (v) =>
                v == _clave.text ? null : 'Las claves no coinciden.',
          ),
        ],
      ),
    ),
  );
}
