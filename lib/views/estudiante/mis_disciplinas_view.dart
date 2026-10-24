import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Disciplinas en las que está inscrito el estudiante (RF-04 y RF-05).
/// En el Hito 2 muestra su estado vacío; en el Hito 3 se conecta a la
/// colección inscripciones.
class MisDisciplinasView extends StatelessWidget {
  const MisDisciplinasView({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: AppRoutes.estudianteDisciplinas,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.misDisciplinas,
      descripcion: AppStrings.misDisciplinasDescripcion,
      child: EstadoVacio(
        icono: Icons.event_note_outlined,
        titulo: AppStrings.sinDisciplinas,
        texto: AppStrings.sinDisciplinasTexto,
        textoAccion: AppStrings.explorarDeportes,
        onAccion: () => Navigator.pushReplacementNamed(
          context,
          AppRoutes.estudianteExplorar,
        ),
      ),
    );
  }
}
