import 'package:saman_sports/views/admin/admin_dashboard_view.dart';
import 'package:saman_sports/views/entrenador/dashboard_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/asistencia_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/disciplinas_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/eventos_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/perfil_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/resenas_entrenador_view.dart';
import 'package:saman_sports/views/entrenador/soporte_entrenador_view.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/auth/forgot_password_view.dart';
import 'package:saman_sports/views/auth/login_view.dart';
import 'package:saman_sports/views/auth/register_view.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/views/auth/guardia_rol.dart';
import 'package:saman_sports/controllers/admin/admin_controladores.dart';
import 'package:saman_sports/controllers/estudiante_controladores.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/views/estudiante/dashboard_estudiante_view.dart';
import 'package:saman_sports/views/estudiante/historial_estudiante_view.dart';
import 'package:saman_sports/views/estudiante/proximamente_estudiante_view.dart';
import 'package:saman_sports/views/estudiante/perfil_estudiante_view.dart';
import 'package:saman_sports/views/estudiante/recordatorios_estudiante_view.dart';
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
  static const String entrenadorDisciplinas = '/entrenador/disciplinas';
  static const String entrenadorAsistencia = '/entrenador/asistencia';
  static const String entrenadorEventos = '/entrenador/eventos';
  static const String entrenadorResenas = '/entrenador/resenas';
  static const String entrenadorSoporte = '/entrenador/soporte';
  static const String entrenadorPerfil = '/entrenador/perfil';

  static Map<String, WidgetBuilder> routes(
    AuthController auth,
    EstudianteController estudiante,
    ExplorarDeportesController explorar,
    ComunidadController comunidad, [
    AdminControladores? admin,
    EstudianteControladores? panelEstudiante,
  ]) {
    final panel = panelEstudiante ?? EstudianteControladores();
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
        ExplorarDeportesView(
          auth: auth,
          controller: explorar,
          inscripciones: panel.inscripciones,
        ),
      ),
      estudianteDisciplinas: (_) => _soloEstudiante(
        auth,
        MisDisciplinasView(auth: auth, controller: panel.inscripciones),
      ),
      estudiantePagos: (_) => _soloEstudiante(
        auth,
        EstatusPagosView(
          auth: auth,
          controller: estudiante,
          pagos: panel.pagos,
        ),
      ),
      estudianteHistorial: (_) => _soloEstudiante(
        auth,
        HistorialEstudianteView(auth: auth, controller: panel.historial),      ),
      estudianteRecordatorios: (_) => _soloEstudiante(
        auth,
        RecordatoriosEstudianteView(
          auth: auth,
          controller: panel.recordatorios,
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
      dashboardEntrenador: (_) =>
          _soloEntrenador(auth, DashboardEntrenadorView(auth: auth)),
      entrenadorDisciplinas: (_) =>
          _soloEntrenador(auth, DisciplinasEntrenadorView(auth: auth)),
      entrenadorAsistencia: (context) => _soloEntrenador(
        auth,
        AsistenciaEntrenadorView(
          auth: auth,
          deporteInicialId:
              ModalRoute.of(context)?.settings.arguments as String?,
        ),
      ),
      entrenadorEventos: (_) =>
          _soloEntrenador(auth, EventosEntrenadorView(auth: auth)),
      entrenadorResenas: (_) =>
          _soloEntrenador(auth, ResenasEntrenadorView(auth: auth)),
      entrenadorSoporte: (_) =>
          _soloEntrenador(auth, SoporteEntrenadorView(auth: auth)),
      entrenadorPerfil: (_) =>
          _soloEntrenador(auth, PerfilEntrenadorView(auth: auth)),
      dashboardAdmin: (_) => GuardiaRol(
        auth: auth,
        esperado: DestinoLogin.administrador,
        child: AdminDashboardView(
          auth: auth,
          controladores: admin ?? AdminControladores(),
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

  static Widget _soloEntrenador(AuthController auth, Widget pantalla) {
    return GuardiaRol(
      auth: auth,
      esperado: DestinoLogin.entrenador,
      child: pantalla,
    );
  }
}
