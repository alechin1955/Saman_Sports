import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/views/entrenador/widgets/disciplinas_nomina.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/opcion_panel.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Punto de entrada del entrenador, con la estructura compartida por los roles.
class DashboardEntrenadorView extends StatefulWidget {
  const DashboardEntrenadorView({
    super.key,
    required this.auth,
    this.controller,
  });

  final AuthController auth;
  final EntrenadorController? controller;

  @override
  State<DashboardEntrenadorView> createState() =>
      _DashboardEntrenadorViewState();
}

class _DashboardEntrenadorViewState extends State<DashboardEntrenadorView> {
  late final EntrenadorController controller =
      widget.controller ?? EntrenadorController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.cargar();
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  static const opciones = [
    OpcionPanel(
      icono: Icons.dashboard_outlined,
      texto: 'Dashboard',
      ruta: AppRoutes.dashboardEntrenador,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: opciones,
      rutaActiva: AppRoutes.dashboardEntrenador,
      subtituloPanel: 'Panel del entrenador',
      titulo: 'Dashboard del entrenador',
      descripcion: 'Organiza tus disciplinas y acompaña a tu equipo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.space24),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.sports_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
                const SizedBox(height: AppSizes.space16),
                Text(
                  'Bienvenido a tu espacio deportivo',
                  style: AppTextStyles.title.copyWith(color: AppColors.surface),
                ),
                const SizedBox(height: AppSizes.space8),
                Text(
                  'Consulta tus disciplinas, revisa los inscritos y lleva el control de cada entrenamiento.',
                  style: AppTextStyles.body.copyWith(color: AppColors.surface),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.space24),
          DisciplinasNomina(controller: controller),
        ],
      ),
    );
  }
}
