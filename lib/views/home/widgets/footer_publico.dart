import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/app_logo.dart';

class FooterPublico extends StatelessWidget {
  const FooterPublico({super.key, required this.onLink});

  final void Function(String link) onLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Column(
        children: [
          const AppLogo(size: 32, mostrarTexto: true),
          const SizedBox(height: AppSizes.space12),
          Wrap(
            spacing: AppSizes.space16,
            children: [
              for (final link in [AppStrings.inicio, AppStrings.deportes, AppStrings.entrenadores, AppStrings.resenas])
                TextButton(onPressed: () => onLink(link), child: Text(link)),
            ],
          ),
          const SizedBox(height: AppSizes.space8),
          Text(AppStrings.copyright, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
