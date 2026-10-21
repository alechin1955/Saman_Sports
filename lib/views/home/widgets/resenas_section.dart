import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/home_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/home/widgets/resena_card.dart';

class ResenasSection extends StatelessWidget {
  const ResenasSection({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final promedio = controller.promedioEstrellas.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.resenas, style: AppTextStyles.title),
          if (controller.ejemplosResenas) const EtiquetaEjemplo(),
          const SizedBox(height: AppSizes.space8),
          Text('$promedio★ · ${controller.totalResenas} ${AppStrings.resenas}', style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSizes.space16),
          if (controller.cargando)
            const EtiquetaEjemplo(cargando: true)
          else if (controller.resenas.isEmpty)
            Text(AppStrings.prontoResenas, style: AppTextStyles.body)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columnas = constraints.maxWidth < AppSizes.mobile ? 1 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.resenas.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnas,
                    mainAxisSpacing: AppSizes.space12,
                    crossAxisSpacing: AppSizes.space12,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) => ResenaCard(resena: controller.resenas[index]),
                );
              },
            ),
        ],
      ),
    );
  }
}
