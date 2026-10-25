import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/views/home/widgets/resena_card.dart';

/// Reseña escrita por el estudiante, con las acciones Editar y Eliminar.
class MiResenaCard extends StatelessWidget {
  const MiResenaCard({
    super.key,
    required this.resena,
    required this.onEditar,
    required this.onEliminar,
  });

  final Resena resena;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final f = resena.fecha;
    final fecha =
        '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

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
              Expanded(
                child: Text(
                  resena.disciplina,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle,
                ),
              ),
              Estrellas(valor: resena.estrellas.toDouble()),
            ],
          ),
          const SizedBox(height: AppSizes.space4),
          Text(
            fecha,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          Text(resena.comentario, style: AppTextStyles.body),
          const SizedBox(height: AppSizes.space8),
          Wrap(
            spacing: AppSizes.space8,
            children: [
              TextButton.icon(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSmall),
                label: const Text(AppStrings.editar),
              ),
              TextButton.icon(
                onPressed: onEliminar,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(
                  Icons.delete_outline,
                  size: AppSizes.iconSmall,
                ),
                label: const Text(AppStrings.eliminar),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
