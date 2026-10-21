import 'package:flutter/material.dart';
import 'package:saman_sports/views/dashboards/dashboard_placeholder_view.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperarContrasena = '/recuperar-contrasena';
  static const String dashboardEstudiante = '/estudiante';
  static const String dashboardEntrenador = '/entrenador';
  static const String dashboardAdmin = '/admin';

  static Map<String, WidgetBuilder> routes() {
    return {
      home: (_) => const DashboardPlaceholderView(titulo: 'Home'),
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
    };
  }
}
