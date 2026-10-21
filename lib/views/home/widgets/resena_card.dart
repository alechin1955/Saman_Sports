import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/resena.dart';

class Estrellas extends StatelessWidget {
  const Estrellas({super.key, required this.valor});

  final double valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(_icono(i), color: AppColors.primary, size: AppSizes.iconSmall),
      ],
    );
  }

  IconData _icono(int posicion) {
    if (valor >= posicion) return Icons.star;
    if (valor >= posicion - 0.5) return Icons.star_half;
    return Icons.star_border;
  }
}

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
          Estrellas(valor: resena.estrellas.toDouble()),
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
