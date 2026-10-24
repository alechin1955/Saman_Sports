import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/deporte.dart';

/// Muestra la información completa de un deporte del catálogo.
/// La inscripción se habilita en el Hito 3.
Future<void> mostrarDetalleDeporte(BuildContext context, Deporte deporte) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      title: Text(deporte.nombre, style: AppTextStyles.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deporte.descripcion,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.space16),
              _Fila(
                icono: Icons.schedule,
                etiqueta: AppStrings.horario,
                valor: deporte.horario,
              ),
              _Fila(
                icono: Icons.person_outline,
                etiqueta: AppStrings.entrenador,
                valor: deporte.entrenadorNombre,
              ),
              _Fila(
                icono: Icons.groups_outlined,
                etiqueta: AppStrings.cuposDisponibles,
                valor: '${deporte.disponibles} / ${deporte.cupos}',
              ),
              const SizedBox(height: AppSizes.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.space12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                child: Text(
                  AppStrings.inscripcionProximamente,
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cerrar),
        ),
      ],
    ),
  );
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: AppSizes.iconSmall, color: AppColors.primary),
          const SizedBox(width: AppSizes.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(valor.isEmpty ? '—' : valor, style: AppTextStyles.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
