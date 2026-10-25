import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/opcion_panel.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Punto de entrada del entrenador, con la estructura compartida por los roles.
class DashboardEntrenadorView extends StatelessWidget {
  const DashboardEntrenadorView({super.key, required this.auth});

  final AuthController auth;

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
      auth: auth,
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
          Text('Tu jornada de entrenamiento', style: AppTextStyles.subtitle),
          const SizedBox(height: AppSizes.space8),
          Text(
            'Aquí encontrarás las disciplinas que te asigne la coordinación deportiva.',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
