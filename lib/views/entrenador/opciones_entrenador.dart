import 'package:flutter/material.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/views/widgets/opcion_panel.dart';

class OpcionesEntrenador {
  static const List<OpcionPanel> menu = [
    OpcionPanel(
      icono: Icons.dashboard_outlined,
      texto: 'Inicio',
      ruta: AppRoutes.dashboardEntrenador,
    ),
    OpcionPanel(
      icono: Icons.sports_outlined,
      texto: 'Disciplinas',
      ruta: AppRoutes.entrenadorDisciplinas,
    ),
    OpcionPanel(
      icono: Icons.fact_check_outlined,
      texto: 'Asistencia',
      ruta: AppRoutes.entrenadorAsistencia,
    ),
    OpcionPanel(
      icono: Icons.event_outlined,
      texto: 'Eventos',
      ruta: AppRoutes.entrenadorEventos,
    ),
    OpcionPanel(
      icono: Icons.reviews_outlined,
      texto: 'Reseñas',
      ruta: AppRoutes.entrenadorResenas,
    ),
    OpcionPanel(
      icono: Icons.support_agent_outlined,
      texto: 'Soporte',
      ruta: AppRoutes.entrenadorSoporte,
    ),
    OpcionPanel(
      icono: Icons.person_outline,
      texto: 'Mi perfil',
      ruta: AppRoutes.entrenadorPerfil,
    ),
  ];
}
