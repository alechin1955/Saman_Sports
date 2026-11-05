import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_resena_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class ResenasAdminView extends StatelessWidget {
  const ResenasAdminView({super.key, required this.resenas});

  final AdminResenaController resenas;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: resenas,
      builder: (context, _) {
        final lista = resenas.resenasFiltradas;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSizes.space8,
              children: [
                for (final filtro in FiltroResena.values)
                  ChoiceChip(
                    label: Text(_filtro(filtro)),
                    selected: resenas.filtro == filtro,
                    onSelected: (_) => resenas.cambiarFiltro(filtro),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (resenas.error != null)
              Text(
                resenas.error!,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            if (resenas.cargando && lista.isEmpty)
              const CircularProgressIndicator()
            else if (lista.isEmpty)
              Text(AppStrings.adminSinResenas, style: AppTextStyles.body)
            else
              for (final item in lista)
                Opacity(
                  opacity: item.visible ? 1 : 0.45,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.resena.autorNombre,
                            style: AppTextStyles.subtitle,
                          ),
                          Text(item.resena.disciplina),
                          _Estrellas(cantidad: item.resena.estrellas),
                          Text(item.resena.comentario),
                          Text(_fecha(item.resena.fecha)),
                          Row(
                            children: [
                              Text(AppStrings.adminVisible),
                              Switch(
                                value: item.visible,
                                onChanged: resenas.guardando
                                    ? null
                                    : (valor) => resenas.cambiarVisibilidad(
                                        item,
                                        valor,
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _Estrellas extends StatelessWidget {
  const _Estrellas({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < cantidad; i++)
          const Icon(
            Icons.star,
            color: AppColors.primary,
            size: AppSizes.iconSmall,
          ),
      ],
    );
  }
}

String _filtro(FiltroResena filtro) {
  return switch (filtro) {
    FiltroResena.todas => AppStrings.adminTodas,
    FiltroResena.visibles => AppStrings.adminVisibles,
    FiltroResena.ocultas => AppStrings.adminOcultas,
  };
}

String _fecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}
