import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
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

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saman Sports',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => _inicioSegunSesion(),
        ...AppRoutes.routes(_auth),
      },
    );
  }

  Widget _inicioSegunSesion() {
    if (Firebase.apps.isEmpty) {
      return const HomeView();
    }
    return StreamBuilder<User?>(
      stream: _sesion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          return const HomeView();
        }
        return DashboardPlaceholderView(titulo: _titulo(user.email));
      },
    );
  }

  Stream<User?> _sesion() {
    if (Firebase.apps.isEmpty) {
      return Stream<User?>.value(null);
    }
    return FirebaseAuth.instance.authStateChanges();
  }

  String _titulo(String? correo) {
    return switch (AuthController.destinoDesdeCorreo(correo)) {
      DestinoLogin.entrenador => AppStrings.panelEntrenador,
      DestinoLogin.administrador => AppStrings.panelAdmin,
      _ => AppStrings.panelEstudiante,
    };
  }
}
