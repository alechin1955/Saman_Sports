import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class QueEsSection extends StatelessWidget {
  const QueEsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      (Icons.sports, AppStrings.featureDescubre, AppStrings.descubreDeportesTexto),
      (Icons.event_available_outlined, AppStrings.inscribeteFacil, AppStrings.inscribeteFacilTexto),
      (Icons.groups_outlined, AppStrings.conectaEntrenadores, AppStrings.conectaEntrenadoresTexto),
      (Icons.rate_review_outlined, AppStrings.comparteExperiencia, AppStrings.comparteExperienciaTexto),
    ];
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.queEsTitulo, style: AppTextStyles.title),
          const SizedBox(height: AppSizes.space8),
          Text(AppStrings.queEsTexto, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.space16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnas = constraints.maxWidth < AppSizes.mobile
                  ? 1
                  : constraints.maxWidth < AppSizes.desktop
                      ? 2
                      : 4;
              return GridView.count(
                crossAxisCount: columnas,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSizes.space12,
                crossAxisSpacing: AppSizes.space12,
                childAspectRatio: 1.4,
                children: [
                  for (final tarjeta in tarjetas)
                    _Tarjeta(icono: tarjeta.$1, titulo: tarjeta.$2, texto: tarjeta.$3),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.icono, required this.titulo, required this.texto});

  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppColors.primary),
          const SizedBox(height: AppSizes.space8),
          Text(titulo, style: AppTextStyles.label),
          Text(texto, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
