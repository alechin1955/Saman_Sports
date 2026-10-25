import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Estado de la cuenta del estudiante y de sus pagos (RF-06 y RF-15).
/// La lista de pagos se conecta a la colección pagos en el Hito 3.
class EstatusPagosView extends StatefulWidget {
  const EstatusPagosView({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final EstudianteController controller;

  @override
  State<EstatusPagosView> createState() => _EstatusPagosViewState();
}

class _EstatusPagosViewState extends State<EstatusPagosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.cargarPerfil();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: AppRoutes.estudiantePagos,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.estatusPagos,
      descripcion: AppStrings.estatusPagosDescripcion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final c = widget.controller;
              final estudiante = c.estudiante;
              if (c.error != null && estudiante == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MensajeError(texto: c.error!),
                    const SizedBox(height: AppSizes.space16),
                    BotonSecundario(
                      texto: AppStrings.reintentar,
                      onPressed: c.cargarPerfil,
                    ),
                  ],
                );
              }
              if (c.cargando || estudiante == null) {
                return const EtiquetaEjemplo(cargando: true);
              }
              return _EstadoCuenta(estudiante: estudiante);
            },
          ),
          const SizedBox(height: AppSizes.space32),
          Text(AppStrings.comoFuncionaInscripcion, style: AppTextStyles.title),
          const SizedBox(height: AppSizes.space16),
          const _PasosInscripcion(),
          const SizedBox(height: AppSizes.space32),
          Text(AppStrings.pagos, style: AppTextStyles.title),
          const SizedBox(height: AppSizes.space16),
          const EstadoVacio(
            icono: Icons.receipt_long_outlined,
            titulo: AppStrings.sinPagos,
            texto: AppStrings.sinPagosTexto,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _tarjeta() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSizes.radius),
    border: Border.all(color: AppColors.border),
  );
}

class _EstadoCuenta extends StatelessWidget {
  const _EstadoCuenta({required this.estudiante});

  final Estudiante estudiante;

  @override
  Widget build(BuildContext context) {
    final e = estudiante;
    return Container(
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: _tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.estadoCuenta, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSizes.space12),
          Wrap(
            spacing: AppSizes.space8,
            runSpacing: AppSizes.space8,
            children: [
              _Estado(
                texto: e.activo
                    ? AppStrings.cuentaActiva
                    : AppStrings.cuentaInactiva,
                ok: e.activo,
              ),
              _Estado(
                texto: e.solvente ? AppStrings.solvente : AppStrings.noSolvente,
                ok: e.solvente,
              ),
            ],
          ),
          if (!(e.activo && e.solvente)) ...[
            const SizedBox(height: AppSizes.space12),
            Text(
              AppStrings.avisoSolvencia,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({required this.texto, required this.ok});

  final String texto;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.error;
    return Chip(
      avatar: Icon(
        ok ? Icons.check_circle_outline : Icons.warning_amber_outlined,
        size: AppSizes.iconSmall,
        color: color,
      ),
      label: Text(texto),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: AppTextStyles.label.copyWith(color: color),
      side: BorderSide.none,
    );
  }
}

class _PasosInscripcion extends StatelessWidget {
  const _PasosInscripcion();

  static const List<String> _pasos = [
    AppStrings.pasoElegir,
    AppStrings.pasoPendiente,
    AppStrings.pasoPagar,
    AppStrings.pasoConfirmada,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: _tarjeta(),
      child: Column(
        children: [
          for (var i = 0; i < _pasos.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == _pasos.length - 1 ? 0 : AppSizes.space16,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: AppSizes.space16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  Expanded(child: Text(_pasos[i], style: AppTextStyles.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
