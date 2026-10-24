import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/estudiante.dart';

/// Tarjeta del Dashboard con el saludo, los datos del estudiante y el
/// estado de su cuenta (activo y solvente).
class BienvenidaCard extends StatelessWidget {
  const BienvenidaCard({super.key, required this.estudiante});

  final Estudiante estudiante;

  @override
  Widget build(BuildContext context) {
    final e = estudiante;
    final puedeInscribirse = e.activo && e.solvente;

    return Container(
      padding: const EdgeInsets.all(AppSizes.space24),
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
              CircleAvatar(
                radius: AppSizes.iconMedium,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  e.iniciales,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.hola} ${e.nombre}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(height: AppSizes.space4),
                    Text(
                      e.correo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space16),
          Text(
            '${AppStrings.carnet}: ${e.carnet}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSizes.space12),
          Wrap(
            spacing: AppSizes.space8,
            runSpacing: AppSizes.space8,
            children: [
              _ChipEstado(
                texto: e.activo
                    ? AppStrings.cuentaActiva
                    : AppStrings.cuentaInactiva,
                icono: e.activo ? Icons.check_circle_outline : Icons.block,
                color: e.activo ? AppColors.success : AppColors.error,
              ),
              _ChipEstado(
                texto: e.solvente ? AppStrings.solvente : AppStrings.noSolvente,
                icono: e.solvente
                    ? Icons.verified_outlined
                    : Icons.warning_amber_outlined,
                color: e.solvente ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          if (!puedeInscribirse) ...[
            const SizedBox(height: AppSizes.space16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.space12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: AppSizes.iconSmall,
                  ),
                  const SizedBox(width: AppSizes.space8),
                  Expanded(
                    child: Text(
                      AppStrings.avisoSolvencia,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({
    required this.texto,
    required this.icono,
    required this.color,
  });

  final String texto;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icono, size: AppSizes.iconSmall, color: color),
      label: Text(texto),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: AppTextStyles.label.copyWith(color: color),
      side: BorderSide.none,
    );
  }
}
