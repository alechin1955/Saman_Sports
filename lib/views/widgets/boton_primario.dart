import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class BotonPrimario extends StatelessWidget {
  const BotonPrimario({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    this.icono,
    this.anchoCompleto = false,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;
  final IconData? icono;
  final bool anchoCompleto;

  @override
  Widget build(BuildContext context) {
    final boton = ElevatedButton(
      onPressed: cargando ? null : onPressed,
      child: cargando
          ? const SizedBox(
              width: AppSizes.space16,
              height: AppSizes.space16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.surface,
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(texto, style: AppTextStyles.button),
                  if (icono != null) ...[
                    const SizedBox(width: AppSizes.space8),
                    Icon(icono, color: AppColors.surface, size: AppSizes.space16),
                  ],
                ],
              ),
            ),
    );

    if (!anchoCompleto) {
      return boton;
    }
    return SizedBox(width: double.infinity, child: boton);
  }
}
