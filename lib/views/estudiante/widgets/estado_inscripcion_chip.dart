import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/inscripcion.dart';

/// Etiqueta de color con el estado de una inscripción.
class EstadoInscripcionChip extends StatelessWidget {
  const EstadoInscripcionChip({super.key, required this.estado});

  final EstadoInscripcion estado;

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (estado) {
      EstadoInscripcion.pendiente => (
        AppStrings.estadoPendiente,
        AppColors.primary,
      ),
      EstadoInscripcion.confirmada => (
        AppStrings.estadoConfirmada,
        AppColors.success,
      ),
      EstadoInscripcion.cancelada => (
        AppStrings.estadoCancelada,
        AppColors.textSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space12,
        vertical: AppSizes.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Text(texto, style: AppTextStyles.label.copyWith(color: color)),
    );
  }
}