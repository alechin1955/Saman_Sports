import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class BarraGrafico {
  const BarraGrafico({required this.etiqueta, required this.valor});

  final String etiqueta;
  final num valor;
}

class GraficoBarras extends StatelessWidget {
  const GraficoBarras({
    super.key,
    required this.titulo,
    required this.barras,
    this.horizontal = false,
  });

  final String titulo;
  final List<BarraGrafico> barras;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final maximo = barras.fold<num>(0, (mayor, barra) {
      return barra.valor > mayor ? barra.valor : mayor;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: AppTextStyles.subtitle),
        const SizedBox(height: AppSizes.space12),
        if (barras.isEmpty)
          Text(AppStrings.adminSinGrafico, style: AppTextStyles.body)
        else if (horizontal)
          for (final barra in barras) _fila(barra, maximo)
        else
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final barra in barras)
                  Expanded(child: _columna(barra, maximo)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _fila(BarraGrafico barra, num maximo) {
    final factor = maximo == 0 ? 0.0 : barra.valor / maximo;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(barra.etiqueta, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: factor == 0 ? 0.02 : factor.toDouble(),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.space8),
          Text('${barra.valor}', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _columna(BarraGrafico barra, num maximo) {
    final factor = maximo == 0 ? 0.0 : (barra.valor / maximo).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${barra.valor}', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSizes.space4),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: factor == 0 ? 0.02 : factor,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.space4),
          Text(
            barra.etiqueta,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
