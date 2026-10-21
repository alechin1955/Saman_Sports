import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/widgets/app_logo.dart';

class AuthFeature {
  const AuthFeature({
    required this.icono,
    required this.titulo,
    required this.texto,
  });

  final IconData icono;
  final String titulo;
  final String texto;
}

class AuthInfoPanel extends StatelessWidget {
  const AuthInfoPanel({
    super.key,
    required this.tagline,
    required this.palabraResaltada,
    required this.descripcion,
    required this.features,
  });

  final String tagline;
  final String palabraResaltada;
  final String descripcion;
  final List<AuthFeature> features;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(size: 56, mostrarTexto: true),
          Text(
            AppStrings.universidad.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSizes.space48),
          Text.rich(_tagline()),
          const SizedBox(height: AppSizes.space16),
          Container(
            width: AppSizes.space48,
            height: AppSizes.space4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
          ),
          const SizedBox(height: AppSizes.space24),
          Text(
            descripcion,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.space32),
          for (final feature in features) ...[
            _FeatureRow(feature: feature),
            const SizedBox(height: AppSizes.space16),
          ],
          const SizedBox(height: AppSizes.space32),
          Text(
            AppStrings.copyright,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  TextSpan _tagline() {
    final indice = tagline.toLowerCase().indexOf(palabraResaltada.toLowerCase());
    if (indice < 0) {
      return TextSpan(text: tagline, style: AppTextStyles.titleLarge);
    }
    final fin = indice + palabraResaltada.length;
    return TextSpan(
      style: AppTextStyles.titleLarge,
      children: [
        TextSpan(text: tagline.substring(0, indice)),
        TextSpan(
          text: tagline.substring(indice, fin),
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
        ),
        TextSpan(text: tagline.substring(fin)),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final AuthFeature feature;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSizes.space48,
          height: AppSizes.space48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(feature.icono, color: AppColors.primary),
        ),
        const SizedBox(width: AppSizes.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(feature.titulo, style: AppTextStyles.label),
              Text(
                feature.texto,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
