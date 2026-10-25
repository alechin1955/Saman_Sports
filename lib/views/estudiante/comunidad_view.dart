import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/comunidad_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/estudiante/widgets/formulario_resena.dart';
import 'package:saman_sports/views/estudiante/widgets/mi_resena_card.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Comunidad del estudiante (RF-11): publicar, editar y eliminar reseñas.
class ComunidadView extends StatefulWidget {
  const ComunidadView({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final ComunidadController controller;

  @override
  State<ComunidadView> createState() => _ComunidadViewState();
}

class _ComunidadViewState extends State<ComunidadView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.iniciar();
    });
  }

  void _avisar(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: esError ? AppColors.error : AppColors.success,
        content: Text(texto),
      ),
    );
  }

  Future<void> _editar(Resena resena) async {
    widget.controller.limpiarErrorFormulario();
    final guardado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
        title: Text(AppStrings.editarResena, style: AppTextStyles.title),
        content: SizedBox(
          width: AppSizes.formMaxWidth,
          child: SingleChildScrollView(
            child: FormularioResena(
              controller: widget.controller,
              inicial: resena,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelar),
          ),
        ],
      ),
    );
    if (!mounted || guardado != true) return;
    _avisar(AppStrings.resenaActualizada);
  }

  Future<void> _eliminar(Resena resena) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: Text(
          AppStrings.confirmarEliminarResena,
          style: AppTextStyles.title,
        ),
        content: Text(
          AppStrings.eliminarNoSeDeshace,
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelar),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.eliminar),
          ),
        ],
      ),
    );
    if (!mounted || confirmado != true) return;

    final ok = await widget.controller.eliminar(resena);
    if (!mounted) return;
    if (ok) {
      _avisar(AppStrings.resenaEliminada);
    } else {
      _avisar(
        widget.controller.errorFormulario ?? AppStrings.errorInesperado,
        esError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formulario = _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.escribeResena, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSizes.space4),
          Text(
            AppStrings.escribeResenaTexto,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          FormularioResena(controller: widget.controller),
        ],
      ),
    );
    final lista = _MisResenas(
      controller: widget.controller,
      onEditar: _editar,
      onEliminar: _eliminar,
    );

    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: AppRoutes.estudianteComunidad,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.comunidad,
      descripcion: AppStrings.comunidadDescripcion,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= AppSizes.perfilDosColumnas) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: formulario),
                const SizedBox(width: AppSizes.space24),
                Expanded(flex: 3, child: lista),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              formulario,
              const SizedBox(height: AppSizes.space32),
              lista,
            ],
          );
        },
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _MisResenas extends StatelessWidget {
  const _MisResenas({
    required this.controller,
    required this.onEditar,
    required this.onEliminar,
  });

  final ComunidadController controller;
  final void Function(Resena resena) onEditar;
  final void Function(Resena resena) onEliminar;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final Widget contenido;
        if (c.error != null && c.misResenas.isEmpty) {
          contenido = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MensajeError(texto: c.error!),
              const SizedBox(height: AppSizes.space16),
              BotonSecundario(
                texto: AppStrings.reintentar,
                onPressed: c.iniciar,
              ),
            ],
          );
        } else if (c.cargando) {
          contenido = const EtiquetaEjemplo(cargando: true);
        } else if (c.misResenas.isEmpty) {
          contenido = const EstadoVacio(
            icono: Icons.rate_review_outlined,
            titulo: AppStrings.sinMisResenas,
            texto: AppStrings.sinMisResenasTexto,
          );
        } else {
          contenido = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final resena in c.misResenas)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.space12),
                  child: MiResenaCard(
                    resena: resena,
                    onEditar: () => onEditar(resena),
                    onEliminar: () => onEliminar(resena),
                  ),
                ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.misResenas, style: AppTextStyles.title),
            const SizedBox(height: AppSizes.space16),
            contenido,
          ],
        );
      },
    );
  }
}
