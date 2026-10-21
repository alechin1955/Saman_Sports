import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/deporte.dart';

class DeporteCard extends StatelessWidget {
  const DeporteCard({super.key, required this.deporte, required this.onDetalles});

  final Deporte deporte;
  final VoidCallback onDetalles;

  @override
  Widget build(BuildContext context) {
    final progreso = deporte.cupos == 0 ? 0.0 : deporte.inscritos / deporte.cupos;
    final color = switch (deporte.estadoCupos) {
      EstadoCupos.disponible => AppColors.success,
      EstadoCupos.pocosCupos => AppColors.primary,
      EstadoCupos.completo => AppColors.error,
    };
    final estado = switch (deporte.estadoCupos) {
      EstadoCupos.disponible => AppStrings.estadoDisponible,
      EstadoCupos.pocosCupos => AppStrings.estadoPocos,
      EstadoCupos.completo => AppStrings.estadoCompleto,
    };
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
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(_icono(deporte.icono), color: AppColors.primary),
          ),
          const SizedBox(height: AppSizes.space8),
          Text(deporte.nombre, style: AppTextStyles.subtitle),
          Text(deporte.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.space8),
          Text(deporte.horario, style: AppTextStyles.bodySmall),
          Text(deporte.entrenadorNombre, style: AppTextStyles.label),
          const SizedBox(height: AppSizes.space8),
          LinearProgressIndicator(value: progreso.clamp(0, 1), color: color, backgroundColor: AppColors.border),
          const SizedBox(height: AppSizes.space8),
          Text('${AppStrings.cupos}: ${deporte.disponibles}', style: AppTextStyles.bodySmall),
          Chip(label: Text(estado), backgroundColor: color.withValues(alpha: 0.12), labelStyle: AppTextStyles.label.copyWith(color: color)),
          TextButton(onPressed: onDetalles, child: Text(AppStrings.verDetalles)),
        ],
      ),
    );
  }

  IconData _icono(String nombre) {
    return switch (nombre) {
      'futbol' => Icons.sports_soccer,
      'baloncesto' => Icons.sports_basketball,
      'tenis' => Icons.sports_tennis,
      'voleibol' => Icons.sports_volleyball,
      'natacion' => Icons.pool,
      'running' => Icons.directions_run,
      _ => Icons.sports,
    };
  }
}
