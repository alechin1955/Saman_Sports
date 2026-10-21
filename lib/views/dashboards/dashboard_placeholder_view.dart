import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/views/widgets/enlace_volver_inicio.dart';

class DashboardPlaceholderView extends StatelessWidget {
  const DashboardPlaceholderView({
    super.key,
    required this.titulo,
    required this.controller,
  });

  final String titulo;
  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titulo),
            const SizedBox(height: AppSizes.space16),
            ElevatedButton(
              onPressed: () => volverAlInicio(context),
              child: const Text(AppStrings.volverAlInicio),
            ),
            const SizedBox(height: AppSizes.space12),
            ElevatedButton(
              onPressed: () async {
                await controller.cerrarSesion();
                if (!context.mounted) return;
                volverAlInicio(context);
              },
              child: const Text(AppStrings.cerrarSesion),
            ),
          ],
        ),
      ),
    );
  }
}
