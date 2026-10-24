import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Pantalla provisional para las opciones del menú del estudiante que
/// todavía no están construidas. Se reemplaza por la pantalla real.
class ProximamenteEstudianteView extends StatelessWidget {
  const ProximamenteEstudianteView({
    super.key,
    required this.auth,
    required this.ruta,
    required this.titulo,
    required this.descripcion,
  });

  final AuthController auth;
  final String ruta;
  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: ruta,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: titulo,
      descripcion: descripcion,
      child: EstadoVacio(
        icono: Icons.construction_outlined,
        titulo: AppStrings.seccionEnConstruccion,
        texto: AppStrings.seccionEnConstruccionTexto,
        textoAccion: AppStrings.irAlDashboard,
        onAccion: () => Navigator.pushReplacementNamed(
          context,
          AppRoutes.dashboardEstudiante,
        ),
      ),
    );
  }
}
