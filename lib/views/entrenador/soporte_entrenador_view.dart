import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

class SoporteEntrenadorView extends StatelessWidget {
  const SoporteEntrenadorView({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: auth,
      opciones: OpcionesEntrenador.menu,
      rutaActiva: AppRoutes.entrenadorSoporte,
      subtituloPanel: 'Panel del entrenador',
      titulo: 'Soporte',
      descripcion:
          '¿Tienes un problema? Escríbele a la coordinación de deportes.',
      child: EstadoVacio(
        icono: Icons.support_agent,
        titulo: 'Estamos construyendo esta sección',
        texto: 'Muy pronto podrás usarla desde tu panel.',
        textoAccion: 'Ir al inicio',
        onAccion: () => Navigator.pushReplacementNamed(
          context,
          AppRoutes.dashboardEntrenador,
        ),
      ),
    );
  }
}
