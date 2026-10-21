import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/entrenador_publico.dart';

class EntrenadorCard extends StatelessWidget {
  const EntrenadorCard({super.key, required this.entrenador});

  final EntrenadorPublico entrenador;

  @override
  Widget build(BuildContext context) {
    final foto = entrenador.fotoUrl;
    return Container(
      width: AppSizes.entrenadorCardAncho,
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: AppSizes.space24,
            backgroundColor: AppColors.navy,
            backgroundImage: foto == null ? null : NetworkImage(foto),
            child: foto == null
                ? Text(entrenador.iniciales, style: AppTextStyles.label.copyWith(color: AppColors.surface))
                : null,
          ),
          const SizedBox(height: AppSizes.space8),
          Text('${entrenador.nombre} ${entrenador.apellido}', textAlign: TextAlign.center, style: AppTextStyles.label),
          Text(entrenador.disciplina, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
          Text(entrenador.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
