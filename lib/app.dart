import 'package:saman_sports/views/entrenador/dashboard_entrenador_view.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/admin/admin_controladores.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/comunidad_controller.dart';
import 'package:saman_sports/controllers/estudiante_controladores.dart';
import 'package:saman_sports/controllers/explorar_deportes_controller.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/controllers/home_controller.dart';
import 'package:saman_sports/controllers/notificaciones_controller.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_theme.dart';
import 'package:saman_sports/views/admin/admin_dashboard_view.dart';
import 'package:saman_sports/views/dashboards/dashboard_placeholder_view.dart';
import 'package:saman_sports/views/estudiante/dashboard_estudiante_view.dart';
import 'package:saman_sports/views/home/home_view.dart';
import 'package:saman_sports/views/widgets/notificaciones_scope.dart';

class SamanSportsApp extends StatefulWidget {
  const SamanSportsApp({
    super.key,
    @visibleForTesting this.auth,
    @visibleForTesting this.sesion,
    @visibleForTesting this.notificaciones,
  });

  final AuthController? auth;
  final Stream<Object?>? sesion;
  final NotificacionesController? notificaciones;

  @override
  State<SamanSportsApp> createState() => _SamanSportsAppState();
}

class _SamanSportsAppState extends State<SamanSportsApp> {
  late final AuthController _auth;
  late final bool _authPropio;
  late final NotificacionesController _notificaciones;
  late final bool _avisosPropios;
  final HomeController _home = HomeController();
  final EstudianteController _estudiante = EstudianteController();
  final ExplorarDeportesController _explorar = ExplorarDeportesController();
  final ComunidadController _comunidad = ComunidadController();
  final AdminControladores _admin = AdminControladores();
  final EstudianteControladores _panelEstudiante = EstudianteControladores();
  late final Stream<Object?> _sesion;

  @override
  void initState() {
    super.initState();
    _authPropio = widget.auth == null;
    _auth = widget.auth ?? AuthController();
    _avisosPropios = widget.notificaciones == null;
    _notificaciones = widget.notificaciones ?? NotificacionesController();
    _notificaciones.iniciar();
    _sesion = widget.sesion ?? _abrirSesion();
  }

  @override
  void dispose() {
    if (_authPropio) _auth.dispose();
    if (_avisosPropios) _notificaciones.dispose();
    _home.dispose();
    _estudiante.dispose();
    _explorar.dispose();
    _comunidad.dispose();
    _admin.dispose();
        _panelEstudiante.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => NotificacionesScope(
        controller: _notificaciones,
        child: child ?? const SizedBox.shrink(),
      ),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => _InicioSegunSesion(
          auth: _auth,
          home: _home,
          estudiante: _estudiante,
          admin: _admin,
          sesion: _sesion,
        ),
        ...AppRoutes.routes(
          _auth,
          _estudiante,
          _explorar,
          _comunidad,
          _admin,
          _panelEstudiante,
        ),
      },
    );
  }

  Stream<Object?> _abrirSesion() {
    try {
      return FirebaseServices.authStateChanges();
    } catch (_) {
      return Stream<Object?>.value(null);
    }
  }
}

class _InicioSegunSesion extends StatefulWidget {
  const _InicioSegunSesion({
    required this.auth,
    required this.home,
    required this.estudiante,
    required this.admin,
    required this.sesion,
  });

  final AuthController auth;
  final HomeController home;
  final EstudianteController estudiante;
  final AdminControladores admin;
  final Stream<Object?> sesion;

  @override
  State<_InicioSegunSesion> createState() => _InicioSegunSesionState();
}

class _InicioSegunSesionState extends State<_InicioSegunSesion> {
  StreamSubscription<Object?>? _sub;
  Object? _usuario;
  Future<ResultadoRol>? _rol;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _listo = true;
    widget.auth.addListener(_alCambiarAuth);
    try {
      _sub = widget.sesion.listen(
        (usuario) {
          if (!mounted) return;
          setState(() {
            _usuario = usuario;
            _listo = true;
            if (widget.auth.registrando || widget.auth.cargando) {
              _rol = null;
              return;
            }
            _rol = usuario == null ? null : widget.auth.rolSesionActual();
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _usuario = null;
            _rol = null;
            _listo = true;
          });
        },
      );
    } catch (_) {
      _listo = true;
    }
  }

  void _alCambiarAuth() {
    if (!mounted) return;
    if (!widget.auth.cargando &&
        !widget.auth.registrando &&
        _usuario != null &&
        _rol == null) {
      setState(() {
        _rol = widget.auth.rolSesionActual();
      });
    }
  }

  void _pedirRol() {
    if (!mounted) return;
    if (widget.auth.cargando || widget.auth.registrando) return;
    if (_usuario == null || _rol != null) return;
    setState(() {
      _rol = widget.auth.rolSesionActual();
    });
  }

  @override
  void dispose() {
    widget.auth.removeListener(_alCambiarAuth);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_listo) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_usuario == null) {
      return HomeView(controller: widget.home);
    }
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        if (widget.auth.registrando || widget.auth.cargando) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return FutureBuilder<ResultadoRol>(
          future: _rol,
          builder: (context, snapshot) {
            if (_rol == null &&
                _usuario != null &&
                !widget.auth.cargando &&
                !widget.auth.registrando) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _pedirRol());
            }
            if (_rol == null ||
                snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final resultado = snapshot.data;
            if (resultado == null || resultado.tipo == TipoResultadoRol.error) {
              return _ErrorRol(
                onReintentar: () {
                  setState(() => _rol = widget.auth.rolSesionActual());
                },
              );
            }
            if (resultado.destino == null) {
              return _SesionSinRol(auth: widget.auth, home: widget.home);
            }
            if (resultado.destino == DestinoLogin.estudiante) {
              return DashboardEstudianteView(
                auth: widget.auth,
                controller: widget.estudiante,
              );
            }
            if (resultado.destino == DestinoLogin.entrenador) {
              return DashboardEntrenadorView(auth: widget.auth);
            }
            if (resultado.destino == DestinoLogin.administrador) {
              return AdminDashboardView(
                auth: widget.auth,
                controladores: widget.admin,
              );
            }
            return DashboardPlaceholderView(
              controller: widget.auth,
              titulo: _titulo(resultado.destino!),
            );
          },
        );
      },
    );
  }

  String _titulo(DestinoLogin destino) {
    return switch (destino) {
      DestinoLogin.estudiante => AppStrings.panelEstudiante,
      DestinoLogin.entrenador => AppStrings.panelEntrenador,
      DestinoLogin.administrador => AppStrings.panelAdmin,
    };
  }
}

class _ErrorRol extends StatelessWidget {
  const _ErrorRol({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.errorConexion),
            const SizedBox(height: AppSizes.space16),
            ElevatedButton(
              onPressed: onReintentar,
              child: Text(AppStrings.reintentar),
            ),
          ],
        ),
      ),
    );
  }
}

class _SesionSinRol extends StatefulWidget {
  const _SesionSinRol({required this.auth, required this.home});

  final AuthController auth;
  final HomeController home;

  @override
  State<_SesionSinRol> createState() => _SesionSinRolState();
}

class _SesionSinRolState extends State<_SesionSinRol> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.auth.cerrarSesion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeView(controller: widget.home);
  }
}
