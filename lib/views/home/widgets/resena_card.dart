import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/resena.dart';

class ResenaCard extends StatelessWidget {
  const ResenaCard({super.key, required this.resena});

  final Resena resena;

  @override
  Widget build(BuildContext context) {
    final dia = resena.fecha.day.toString().padLeft(2, '0');
    final mes = resena.fecha.month.toString().padLeft(2, '0');
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
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= resena.estrellas ? Icons.star : Icons.star_border,
                  color: AppColors.primary,
                  size: AppSizes.iconSmall,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.space8),
          Text(resena.comentario, maxLines: 4, overflow: TextOverflow.ellipsis, style: AppTextStyles.body),
          const SizedBox(height: AppSizes.space8),
          Text('${AppStrings.estudianteUnimet} ${resena.autorNombre}', style: AppTextStyles.label),
          Text('${resena.disciplina} · $dia/$mes/${resena.fecha.year}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
