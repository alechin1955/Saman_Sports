import 'package:flutter/material.dart';
import 'package:saman_sports/views/dashboards/dashboard_placeholder_view.dart';
import 'package:saman_sports/views/home/home_view.dart';
import 'package:saman_sports/views/widgets/widgets_preview_view.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperarContrasena = '/recuperar-contrasena';
  static const String dashboardEstudiante = '/estudiante';
  static const String dashboardEntrenador = '/entrenador';
  static const String dashboardAdmin = '/admin';
  static const String previewWidgets = '/preview-widgets';

  static Map<String, WidgetBuilder> routes() {
    return {
      home: (_) => const HomeView(),
      login: (_) => const DashboardPlaceholderView(titulo: 'Login'),
      registro: (_) => const DashboardPlaceholderView(titulo: 'Registro'),
      recuperarContrasena: (_) =>
          const DashboardPlaceholderView(titulo: 'Recuperar contraseña'),
      dashboardEstudiante: (_) =>
          const DashboardPlaceholderView(titulo: 'Panel del estudiante'),
      dashboardEntrenador: (_) =>
          const DashboardPlaceholderView(titulo: 'Panel del entrenador'),
      dashboardAdmin: (_) =>
          const DashboardPlaceholderView(titulo: 'Panel del administrador'),
      previewWidgets: (_) => const WidgetsPreviewView(),
    };
  }
}
