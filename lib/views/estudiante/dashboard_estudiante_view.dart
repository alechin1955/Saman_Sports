import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/accesos_rapidos.dart';
import 'package:saman_sports/views/estudiante/widgets/bienvenida_card.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Pantalla de inicio del panel del estudiante (Observer: observa a
/// EstudianteController con ListenableBuilder).
class DashboardEstudianteView extends StatefulWidget {
  const DashboardEstudianteView({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final EstudianteController controller;

  @override
  State<DashboardEstudianteView> createState() =>
      _DashboardEstudianteViewState();
}

class _DashboardEstudianteViewState extends State<DashboardEstudianteView> {
  @override
  void initState() {
    super.initState();
    // Se carga después del primer frame para no notificar durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.cargarPerfil();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: AppRoutes.dashboardEstudiante,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.dashboard,
      descripcion: AppStrings.dashboardEstudianteDescripcion,
      child: ListenableBuilder(
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
            return const Column(
              children: [
                EtiquetaEjemplo(cargando: true),
                SizedBox(height: AppSizes.space24),
                EtiquetaEjemplo(cargando: true),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BienvenidaCard(estudiante: estudiante),
              const SizedBox(height: AppSizes.space32),
              Text(AppStrings.accesosRapidos, style: AppTextStyles.title),
              const SizedBox(height: AppSizes.space16),
              const AccesosRapidos(),
            ],
          );
        },
      ),
    );
  }
}
