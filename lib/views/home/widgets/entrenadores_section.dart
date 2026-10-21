import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/home_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/home/widgets/entrenador_card.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';

class EntrenadoresSection extends StatelessWidget {
  const EntrenadoresSection({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.entrenadores, style: AppTextStyles.title),
          if (controller.ejemplosEntrenadores) const EtiquetaEjemplo(),
          const SizedBox(height: AppSizes.space16),
          if (controller.cargando)
            const EtiquetaEjemplo(cargando: true)
          else if (controller.entrenadores.isEmpty)
            Text(AppStrings.prontoEntrenadores, style: AppTextStyles.body)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < AppSizes.mobile) {
                  return SizedBox(
                    height: AppSizes.entrenadorCarruselAlto,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: controller.entrenadores.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSizes.space12),
                      itemBuilder: (context, index) => EntrenadorCard(entrenador: controller.entrenadores[index]),
                    ),
                  );
                }
                return Wrap(
                  alignment: WrapAlignment.start,
                  spacing: AppSizes.space12,
                  runSpacing: AppSizes.space12,
                  children: [
                    for (final entrenador in controller.entrenadores)
                      EntrenadorCard(entrenador: entrenador),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
