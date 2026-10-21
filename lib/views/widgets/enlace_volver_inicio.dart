import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';

void volverAlInicio(BuildContext context) {
  final navigator = Navigator.of(context);
  var encontroHome = false;
  navigator.popUntil((route) {
    final esHome = route.settings.name == AppRoutes.home;
    if (esHome) encontroHome = true;
    return esHome || route.isFirst;
  });
  if (!encontroHome) {
    navigator.pushReplacementNamed(AppRoutes.home);
  }
}

class EnlaceVolverInicio extends StatelessWidget {
  const EnlaceVolverInicio({
    super.key,
    this.texto = AppStrings.volverAlInicio,
    this.onPressed,
  });

  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed ?? () => volverAlInicio(context),
        icon: const Icon(Icons.arrow_back),
        label: Text(texto),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
