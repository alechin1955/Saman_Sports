import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/views/widgets/opcion_panel.dart';

/// Menú del panel del estudiante (según el Figma). Se define una sola vez
/// y lo usan todas las pantallas del estudiante.
class OpcionesEstudiante {
  static const List<OpcionPanel> menu = [
    OpcionPanel(
      icono: Icons.dashboard_outlined,
      texto: AppStrings.dashboard,
      ruta: AppRoutes.dashboardEstudiante,
    ),
    OpcionPanel(
      icono: Icons.search,
      texto: AppStrings.explorarDeportes,
      ruta: AppRoutes.estudianteExplorar,
    ),
    OpcionPanel(
      icono: Icons.event_note_outlined,
      texto: AppStrings.misDisciplinas,
      ruta: AppRoutes.estudianteDisciplinas,
    ),
    OpcionPanel(
      icono: Icons.receipt_long_outlined,
      texto: AppStrings.estatusPagos,
      ruta: AppRoutes.estudiantePagos,
    ),
    OpcionPanel(
      icono: Icons.history,
      texto: AppStrings.historial,
      ruta: AppRoutes.estudianteHistorial,
    ),
    OpcionPanel(
      icono: Icons.notifications_none,
      texto: AppStrings.recordatorios,
      ruta: AppRoutes.estudianteRecordatorios,
    ),
    OpcionPanel(
      icono: Icons.forum_outlined,
      texto: AppStrings.comunidad,
      ruta: AppRoutes.estudianteComunidad,
    ),
    OpcionPanel(
      icono: Icons.support_agent,
      texto: AppStrings.soporte,
      ruta: AppRoutes.estudianteSoporte,
    ),
    OpcionPanel(
      icono: Icons.person_outline,
      texto: AppStrings.miPerfil,
      ruta: AppRoutes.estudiantePerfil,
    ),
  ];
}
