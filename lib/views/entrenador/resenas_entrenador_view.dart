import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/resenas_entrenador_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/home/widgets/resena_card.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

class ResenasEntrenadorView extends StatefulWidget {
  const ResenasEntrenadorView({super.key, required this.auth, this.controller});

  final AuthController auth;
  final ResenasEntrenadorController? controller;

  @override
  State<ResenasEntrenadorView> createState() => _ResenasEntrenadorViewState();
}

class _ResenasEntrenadorViewState extends State<ResenasEntrenadorView> {
  late final ResenasEntrenadorController controller =
      widget.controller ?? ResenasEntrenadorController();
  late final bool _propio = widget.controller == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.iniciar();
    });
  }

  @override
  void dispose() {
    if (_propio) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEntrenador.menu,
      rutaActiva: AppRoutes.entrenadorResenas,
      subtituloPanel: 'Panel del entrenador',
      titulo: 'Reseñas',
      descripcion:
          'Lee la opinión de los estudiantes sobre tus disciplinas asignadas.',
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null && controller.resenas.isEmpty) {
            return MensajeError(texto: controller.error!);
          }
          if (controller.resenas.isEmpty) {
            return const EstadoVacio(
              icono: Icons.reviews_outlined,
              titulo: 'Aún no hay reseñas',
              texto: 'Las reseñas que publiquen los estudiantes sobre tus disciplinas aparecerán aquí.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.space16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.primary),
                    const SizedBox(width: AppSizes.space8),
                    Text(
                      controller.promedio.toStringAsFixed(1),
                      style: AppTextStyles.title,
                    ),
                    const SizedBox(width: AppSizes.space8),
                    Expanded(
                      child: Text(
                        'promedio de ${controller.resenas.length} reseñas',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.space24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columnas = constraints.maxWidth >= 760 ? 2 : 1;
                  final ancho =
                      (constraints.maxWidth -
                          AppSizes.space16 * (columnas - 1)) /
                      columnas;
                  return Wrap(
                    spacing: AppSizes.space16,
                    runSpacing: AppSizes.space16,
                    children: [
                      for (final resena in controller.resenas)
                        SizedBox(
                          width: ancho,
                          child: ResenaCard(resena: resena),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
