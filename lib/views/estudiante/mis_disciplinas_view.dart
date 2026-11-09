import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/formato_fecha.dart';
import 'package:saman_sports/models/inscripcion.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_inscripcion_chip.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Disciplinas en las que está inscrito el estudiante (RF-04 y RF-05).
/// Muestra el estado de cada inscripción y permite cancelarla.
class MisDisciplinasView extends StatefulWidget {
  const MisDisciplinasView({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final InscripcionesController controller;

  @override
  State<MisDisciplinasView> createState() => _MisDisciplinasViewState();
}

class _MisDisciplinasViewState extends State<MisDisciplinasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.iniciar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: AppRoutes.estudianteDisciplinas,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.misDisciplinas,
      descripcion: AppStrings.misDisciplinasDescripcion,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          if (c.error != null) {
            return Column(
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
          }
          if (c.cargando) return const EtiquetaEjemplo(cargando: true);

          final activas = c.activas;
          if (activas.isEmpty) {
            return EstadoVacio(
              icono: Icons.event_note_outlined,
              titulo: AppStrings.sinDisciplinas,
              texto: AppStrings.sinDisciplinasTexto,
              textoAccion: AppStrings.explorarDeportes,
              onAccion: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.estudianteExplorar,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final inscripcion in activas) ...[
                _TarjetaInscripcion(inscripcion: inscripcion, controller: c),
                const SizedBox(height: AppSizes.space12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaInscripcion extends StatelessWidget {
  const _TarjetaInscripcion({
    required this.inscripcion,
    required this.controller,
  });

  final Inscripcion inscripcion;
  final InscripcionesController controller;

  Future<void> _cancelar(BuildContext context) async {
    final mensajes = ScaffoldMessenger.of(context);
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.cancelarInscripcion),
        content: const Text(AppStrings.cancelarInscripcionPregunta),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.volver),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.siCancelar),
          ),
        ],
      ),
    );
    if (confirma != true) return;
    final error = await controller.cancelar(inscripcion);
    mensajes.showSnackBar(
      SnackBar(content: Text(error ?? AppStrings.inscripcionCancelada)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendiente = inscripcion.estado == EstadoInscripcion.pendiente;
    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSizes.space12,
            runSpacing: AppSizes.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(inscripcion.deporteNombre, style: AppTextStyles.subtitle),
              EstadoInscripcionChip(estado: inscripcion.estado),
            ],
          ),
          const SizedBox(height: AppSizes.space8),
          Text(
            '${AppStrings.inscritoEl} ${fechaCorta(inscripcion.fecha)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (pendiente) ...[
            const SizedBox(height: AppSizes.space8),
            Text(AppStrings.pendienteDePagoTexto, style: AppTextStyles.body),
          ],
          const SizedBox(height: AppSizes.space12),
          Wrap(
            spacing: AppSizes.space12,
            runSpacing: AppSizes.space8,
            children: [
              if (pendiente)
                TextButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.estudiantePagos,
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text(AppStrings.irAPagos),
                ),
              BotonSecundario(
                texto: AppStrings.cancelarInscripcion,
                onPressed: controller.procesando
                    ? null
                    : () => _cancelar(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}