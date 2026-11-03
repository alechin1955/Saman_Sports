import 'package:saman_sports/views/entrenador/dashboard_entrenador_view.dart';
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
import 'package:saman_sports/controllers/explorar_deportes_controller.dart';
import 'package:saman_sports/views/estudiante/explorar_deportes_view.dart';
import 'package:saman_sports/controllers/comunidad_controller.dart';
import 'package:saman_sports/views/estudiante/comunidad_view.dart';
import 'package:saman_sports/views/estudiante/estatus_pagos_view.dart';
import 'package:saman_sports/views/estudiante/mis_disciplinas_view.dart';

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
  static const String estudianteHistorial = '/estudiante/historial';
  static const String estudianteRecordatorios = '/estudiante/recordatorios';
  static const String estudianteSoporte = '/estudiante/soporte';

  static Map<String, WidgetBuilder> routes(
    AuthController auth,
    EstudianteController estudiante,
    ExplorarDeportesController explorar,
    ComunidadController comunidad,
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
        ExplorarDeportesView(auth: auth, controller: explorar),
      ),
      estudianteDisciplinas: (_) =>
          _soloEstudiante(auth, MisDisciplinasView(auth: auth)),
      estudiantePagos: (_) => _soloEstudiante(
        auth,
        EstatusPagosView(auth: auth, controller: estudiante),
      ),
      estudianteHistorial: (_) => _soloEstudiante(
        auth,
        ProximamenteEstudianteView(
          auth: auth,
          ruta: estudianteHistorial,
          titulo: AppStrings.historial,
          descripcion: AppStrings.historialDescripcion,
        ),
      ),
      estudianteRecordatorios: (_) => _soloEstudiante(
        auth,
        ProximamenteEstudianteView(
          auth: auth,
          ruta: estudianteRecordatorios,
          titulo: AppStrings.recordatorios,
          descripcion: AppStrings.recordatoriosDescripcion,
        ),
      ),
      estudianteSoporte: (_) => _soloEstudiante(
        auth,
        ProximamenteEstudianteView(
          auth: auth,
          ruta: estudianteSoporte,
          titulo: AppStrings.soporte,
          descripcion: AppStrings.soporteDescripcion,
        ),
      ),
      estudianteComunidad: (_) => _soloEstudiante(
        auth,
        ComunidadView(auth: auth, controller: comunidad),
      ),
      estudiantePerfil: (_) => _soloEstudiante(
        auth,
        PerfilEstudianteView(auth: auth, controller: estudiante),
      ),
      dashboardEntrenador: (_) => GuardiaRol(
        auth: auth,
        esperado: DestinoLogin.entrenador,
        child: DashboardEntrenadorView(auth: auth),
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
