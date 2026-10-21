import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/home_controller.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_theme.dart';
import 'package:saman_sports/views/dashboards/dashboard_placeholder_view.dart';
import 'package:saman_sports/views/home/home_view.dart';

class SamanSportsApp extends StatefulWidget {
  const SamanSportsApp({super.key});

  @override
  State<SamanSportsApp> createState() => _SamanSportsAppState();
}

class _SamanSportsAppState extends State<SamanSportsApp> {
  final AuthController _auth = AuthController();
  final HomeController _home = HomeController();
  late final Stream<Object?> _sesion = _abrirSesion();

  @override
  void dispose() {
    _auth.dispose();
    _home.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => _InicioSegunSesion(auth: _auth, home: _home, sesion: _sesion),
        ...AppRoutes.routes(_auth),
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
    required this.sesion,
  });

  final AuthController auth;
  final HomeController home;
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_listo) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.auth.registrando || widget.auth.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_usuario == null) {
      return HomeView(controller: widget.home);
    }
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        if (widget.auth.registrando || widget.auth.cargando) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return FutureBuilder<ResultadoRol>(
          future: _rol,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
