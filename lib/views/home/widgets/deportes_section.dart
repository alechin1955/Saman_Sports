import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/home_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/home/widgets/deporte_card.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';

class DeportesSection extends StatelessWidget {
  const DeportesSection({super.key, required this.controller, required this.onDetalles});

  final HomeController controller;
  final VoidCallback onDetalles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.deportesDisponibles, style: AppTextStyles.title),
          if (controller.ejemplosDeportes) const EtiquetaEjemplo(),
          const SizedBox(height: AppSizes.space16),
          if (controller.cargando)
            const _Skeleton()
          else if (controller.deportes.isEmpty)
            Text(AppStrings.prontoDeportes, style: AppTextStyles.body)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columnas = constraints.maxWidth < AppSizes.mobile
                    ? 1
                    : constraints.maxWidth < AppSizes.desktop
                        ? 2
                        : 3;
                final ancho = (constraints.maxWidth - AppSizes.space12 * (columnas - 1)) / columnas;
                return Wrap(
                  spacing: AppSizes.space12,
                  runSpacing: AppSizes.space12,
                  children: [
                    for (final deporte in controller.deportes)
                      SizedBox(
                        width: ancho,
                        child: DeporteCard(deporte: deporte, onDetalles: onDetalles),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 160, child: EtiquetaEjemplo(cargando: true));
  }
}
