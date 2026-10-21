import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';

class CtaSection extends StatelessWidget {
  const CtaSection({super.key, required this.onRegistrarme});

  final VoidCallback onRegistrarme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.space24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(AppStrings.listoParaEmpezar, style: AppTextStyles.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.space8),
            Text(AppStrings.ctaTexto, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.space16),
            BotonPrimario(texto: AppStrings.registrarme, onPressed: onRegistrarme),
          ],
        ),
      ),
    );
  }
}
