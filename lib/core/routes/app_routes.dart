import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/auth/forgot_password_view.dart';
import 'package:saman_sports/views/auth/login_view.dart';
import 'package:saman_sports/views/auth/register_view.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/views/auth/guardia_rol.dart';
import 'package:saman_sports/views/dashboards/dashboard_placeholder_view.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/views/estudiante/dashboard_estudiante_view.dart';
import 'package:saman_sports/views/estudiante/proximamente_estudiante_view.dart';
import 'package:saman_sports/views/estudiante/perfil_estudiante_view.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String recuperarContrasena = '/recuperar-contrasena';
  static const String dashboardEstudiante = '/estudiante';
  static const String dashboardEntrenador = '/entrenador';
  static const String dashboardAdmin = '/admin';
  static const String estudianteExplorar = '/estudiante/explorar';
  static const String estudianteDisciplinas = '/estudiante/disciplinas';
  static const String estudiantePagos = '/estudiante/pagos';
  static const String estudianteComunidad = '/estudiante/comunidad';
  static const String estudiantePerfil = '/estudiante/perfil';

  static Map<String, WidgetBuilder> routes(
    AuthController auth,
    EstudianteController estudiante,
  ) {
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
      dashboardEstudiante: (_) => _soloEstudiante(
        auth,
        DashboardEstudianteView(auth: auth, controller: estudiante),
      ),
      estudianteExplorar: (_) => _soloEstudiante(
        auth,
        ProximamenteEstudianteView(
          auth: auth,
          ruta: estudianteExplorar,
          titulo: AppStrings.explorarDeportes,
          descripcion: AppStrings.explorarDeportesDescripcion,
        ),
      ),
      estudianteDisciplinas: (_) => _soloEstudiante(
        auth,
        ProximamenteEstudianteView(
          auth: auth,
          ruta: estudianteDisciplinas,
          titulo: AppStrings.misDisciplinas,
          descripcion: AppStrings.misDisciplinasDescripcion,
        ),
      ),
      estudiantePagos: (_) => _soloEstudiante(
        auth,
        ProximamenteEstudianteView(
          auth: auth,
          ruta: estudiantePagos,
          titulo: AppStrings.estatusPagos,
          descripcion: AppStrings.estatusPagosDescripcion,
        ),
      ),
      estudianteComunidad: (_) => _soloEstudiante(
        auth,
        ProximamenteEstudianteView(
          auth: auth,
          ruta: estudianteComunidad,
          titulo: AppStrings.comunidad,
          descripcion: AppStrings.comunidadDescripcion,
        ),
      ),
      estudiantePerfil: (_) => _soloEstudiante(
        auth,
        PerfilEstudianteView(auth: auth, controller: estudiante),
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

  /// Todas las pantallas del estudiante pasan por GuardiaRol:
  /// solo un usuario con rol 'estudiante' puede verlas.
  static Widget _soloEstudiante(AuthController auth, Widget pantalla) {
    return GuardiaRol(
      auth: auth,
      esperado: DestinoLogin.estudiante,
      child: pantalla,
    );
  }
}
