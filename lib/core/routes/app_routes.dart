import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/auth/forgot_password_view.dart';
import 'package:saman_sports/views/auth/login_view.dart';
import 'package:saman_sports/views/auth/register_view.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/views/auth/guardia_rol.dart';
import 'package:saman_sports/views/dashboards/dashboard_placeholder_view.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperarContrasena = '/recuperar-contrasena';
  static const String dashboardEstudiante = '/estudiante';
  static const String dashboardEntrenador = '/entrenador';
  static const String dashboardAdmin = '/admin';

  static Map<String, WidgetBuilder> routes(AuthController auth) {
    return {
      login: (_) => LoginView(controller: auth),
      registro: (_) => RegisterView(controller: auth),
      recuperarContrasena: (context) {
        final argumento = ModalRoute.of(context)?.settings.arguments;
        return ForgotPasswordView(
          controller: auth,
          correoInicial: argumento is String ? argumento : null,
        );
      },
      dashboardEstudiante: (_) => GuardiaRol(
        auth: auth,
        esperado: DestinoLogin.estudiante,
        child: DashboardPlaceholderView(
          controller: auth,
          titulo: AppStrings.panelEstudiante,
        ),
      ),
      dashboardEntrenador: (_) => GuardiaRol(
        auth: auth,
        esperado: DestinoLogin.entrenador,
        child: DashboardPlaceholderView(
          controller: auth,
          titulo: AppStrings.panelEntrenador,
        ),
      ),
      dashboardAdmin: (_) => GuardiaRol(
        auth: auth,
        esperado: DestinoLogin.administrador,
        child: DashboardPlaceholderView(
          controller: auth,
          titulo: AppStrings.panelAdmin,
        ),
      ),
    };
  }
}
