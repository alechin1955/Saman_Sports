import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/entrenador/entrenador_notificacion_controller.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class CampanaEntrenador extends StatelessWidget {
  const CampanaEntrenador({super.key, required this.controller});

  final EntrenadorNotificacionController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pendientes = controller.noLeidas;
        return IconButton(
          tooltip: EntrenadorNotificacionController.titulo,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) =>
                ListaNotificacionesEntrenador(controller: controller),
          ),
          icon: Badge(
            isLabelVisible: pendientes > 0,
            label: Text('$pendientes'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}

class ListaNotificacionesEntrenador extends StatelessWidget {
  const ListaNotificacionesEntrenador({super.key, required this.controller});

  final EntrenadorNotificacionController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(EntrenadorNotificacionController.titulo),
      content: SizedBox(
        width: 420,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.cargando && controller.notificaciones.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.notificaciones.isEmpty) {
              return Text(
                EntrenadorNotificacionController.vacio,
                style: AppTextStyles.body,
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final aviso in controller.notificaciones)
                  ListTile(
                    title: Text(aviso.titulo, style: AppTextStyles.subtitle),
                    subtitle: Text(aviso.mensaje),
                    trailing: aviso.leida
                        ? null
                        : TextButton(
                            onPressed: () => controller.marcarLeida(aviso),
                            child: const Text(
                              EntrenadorNotificacionController.marcar,
                            ),
                          ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            EntrenadorNotificacionController.cerrar,
            style: AppTextStyles.body.copyWith(color: AppColors.navy),
          ),
        ),
      ],
    );
  }
}
