import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';

class GuardiaRol extends StatefulWidget {
  const GuardiaRol({
    super.key,
    required this.auth,
    required this.esperado,
    required this.child,
  });

  final AuthController auth;
  final DestinoLogin esperado;
  final Widget child;

  @override
  State<GuardiaRol> createState() => _GuardiaRolState();
}

class _GuardiaRolState extends State<GuardiaRol> {
  late Future<ResultadoRol> _rol = widget.auth.rolSesionActual();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        if (widget.auth.registrando) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return FutureBuilder<ResultadoRol>(
          future: _rol,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final resultado = snapshot.data;
            if (resultado?.tipo == TipoResultadoRol.error) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppStrings.errorConexion),
                      const SizedBox(height: AppSizes.space16),
                      ElevatedButton(
                        onPressed: () => setState(() => _rol = widget.auth.rolSesionActual()),
                        child: Text(AppStrings.reintentar),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (resultado?.destino != widget.esperado) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (_) => false,
                );
              });
              return const SizedBox.shrink();
            }
            return widget.child;
          },
        );
      },
    );
  }
}
