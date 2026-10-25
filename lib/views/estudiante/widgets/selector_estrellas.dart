import 'package:flutter/material.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';

/// Cinco estrellas que se pueden tocar para calificar de 1 a 5.
class SelectorEstrellas extends StatelessWidget {
  const SelectorEstrellas({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  final int valor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            tooltip: '$i',
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= valor ? Icons.star : Icons.star_border,
              color: AppColors.primary,
              size: AppSizes.iconMedium,
            ),
          ),
      ],
    );
  }
}
