import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class TarjetaResumen extends StatelessWidget {
  const TarjetaResumen({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    this.detalle,
    this.color,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final String? detalle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final acento = color ?? AppColors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: acento),
            const SizedBox(height: AppSizes.space12),
            Text(titulo, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSizes.space4),
            Text(valor, style: AppTextStyles.title),
            if (detalle != null) ...[
              const SizedBox(height: AppSizes.space4),
              Text(detalle!, style: AppTextStyles.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
