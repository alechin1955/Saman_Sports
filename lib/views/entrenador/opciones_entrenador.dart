import 'package:flutter/material.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/views/widgets/opcion_panel.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

class OpcionesEntrenador {
  static const List<OpcionPanel> menu = [
    OpcionPanel(
      icono: Icons.dashboard_outlined,
      texto: AppStrings.inicio,
      ruta: AppRoutes.dashboardEntrenador,
    ),
    OpcionPanel(
      icono: Icons.sports_outlined,
      texto: AppStrings.disciplinas,
      ruta: AppRoutes.entrenadorDisciplinas,
    ),
    OpcionPanel(
      icono: Icons.fact_check_outlined,
      texto: AppStrings.asistencia,
      ruta: AppRoutes.entrenadorAsistencia,
    ),
    OpcionPanel(
      icono: Icons.event_outlined,
      texto: AppStrings.adminEventos,
      ruta: AppRoutes.entrenadorEventos,
    ),
    OpcionPanel(
      icono: Icons.reviews_outlined,
      texto: AppStrings.resenas,
      ruta: AppRoutes.entrenadorResenas,
    ),
    OpcionPanel(
      icono: Icons.support_agent_outlined,
      texto: AppStrings.soporte,
      ruta: AppRoutes.entrenadorSoporte,
    ),
    OpcionPanel(
      icono: Icons.person_outline,
      texto: AppStrings.miPerfil,
      ruta: AppRoutes.entrenadorPerfil,
    ),
  ];
}
