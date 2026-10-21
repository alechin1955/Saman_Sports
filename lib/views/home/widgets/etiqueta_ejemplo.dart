import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class EtiquetaEjemplo extends StatelessWidget {
  const EtiquetaEjemplo({super.key, this.cargando = false});

  final bool cargando;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Container(
        height: AppSizes.skeletonAlto,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.space8),
      child: Text(
        AppStrings.datosEjemplo,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
