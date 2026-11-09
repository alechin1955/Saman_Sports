import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/recordatorios_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/formato_fecha.dart';
import 'package:saman_sports/models/notificacion.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Recordatorios del estudiante: avisos de pago pendiente y de eventos que
/// envía el administrador. Se actualizan en tiempo real.
class RecordatoriosEstudianteView extends StatefulWidget {
  const RecordatoriosEstudianteView({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final RecordatoriosController controller;

  @override
  State<RecordatoriosEstudianteView> createState() =>
      _RecordatoriosEstudianteViewState();
}

class _RecordatoriosEstudianteViewState
    extends State<RecordatoriosEstudianteView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.iniciar();
    });
  }

  Future<void> _mostrarResultado(Future<String?> accion) async {
    final mensajes = ScaffoldMessenger.of(context);
    final error = await accion;
    if (error != null) {
      mensajes.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: AppRoutes.estudianteRecordatorios,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.recordatorios,
      descripcion: AppStrings.recordatoriosDescripcion,
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
          if (c.avisos.isEmpty) {
            return const EstadoVacio(
              icono: Icons.notifications_none,
              titulo: AppStrings.sinRecordatorios,
              texto: AppStrings.sinRecordatoriosTexto,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSizes.space12,
                runSpacing: AppSizes.space8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${c.noLeidos} ${AppStrings.sinLeer}',
                    style: AppTextStyles.subtitle,
                  ),
                  if (c.noLeidos > 0)
                    TextButton.icon(
                      onPressed: c.procesando
                          ? null
                          : () => _mostrarResultado(c.marcarTodos()),
                      icon: const Icon(Icons.done_all),
                      label: const Text(AppStrings.marcarTodasLeidas),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.space16),
              for (final aviso in c.avisos) ...[
                _TarjetaAviso(
                  aviso: aviso,
                  onMarcar: () => _mostrarResultado(c.marcarLeido(aviso)),
                ),
                const SizedBox(height: AppSizes.space12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaAviso extends StatelessWidget {
  const _TarjetaAviso({required this.aviso, required this.onMarcar});

  final Notificacion aviso;
  final VoidCallback onMarcar;

  IconData get _icono => switch (aviso.tipo) {
    'pago_pendiente' => Icons.receipt_long_outlined,
    'evento' => Icons.event_outlined,
    _ => Icons.notifications_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final nuevo = !aviso.leida;
    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: nuevo
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: nuevo ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _icono,
            color: nuevo ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSizes.space8,
                  runSpacing: AppSizes.space4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(aviso.titulo, style: AppTextStyles.label),
                    if (nuevo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.space8,
                          vertical: AppSizes.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                        ),
                        child: Text(
                          AppStrings.nuevo,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.space4),
                Text(aviso.mensaje, style: AppTextStyles.body),
                const SizedBox(height: AppSizes.space8),
                Text(
                  fechaCorta(aviso.fecha),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (nuevo) ...[
                  const SizedBox(height: AppSizes.space8),
                  TextButton(
                    onPressed: onMarcar,
                    child: const Text(AppStrings.marcarLeida),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}