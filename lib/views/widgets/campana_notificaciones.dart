import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/notificaciones_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/models/notificacion.dart';
import 'package:saman_sports/views/widgets/notificaciones_scope.dart';

class CampanaNotificaciones extends StatelessWidget {
  const CampanaNotificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NotificacionesScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return IconButton(
          tooltip: AppStrings.notificacionesTitulo,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogo) => _DialogoAvisos(controller: controller),
          ),
          icon: Badge(
            isLabelVisible: controller.noLeidas > 0,
            label: Text('${controller.noLeidas}'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}

class _DialogoAvisos extends StatelessWidget {
  const _DialogoAvisos({required this.controller});

  final NotificacionesController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.notificacionesTitulo),
      content: SizedBox(
        width: 420,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.notificaciones.isEmpty) {
              return Text(AppStrings.sinNotificaciones);
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: controller.marcarTodas,
                    child: const Text(AppStrings.marcarTodas),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final aviso in controller.notificaciones)
                        _Aviso(controller: controller, aviso: aviso),
                    ],
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
          child: const Text(AppStrings.cerrar),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.controller, required this.aviso});

  final NotificacionesController controller;
  final Notificacion aviso;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(aviso.titulo),
      subtitle: Text('${aviso.mensaje}\n${aviso.fecha.toIso8601String()}'),
      isThreeLine: true,
      trailing: aviso.pideConfirmacion
          ? Wrap(
              spacing: AppSizes.space4,
              children: [
                TextButton(
                  onPressed: () => controller.responder(aviso, true),
                  child: const Text(AppStrings.confirmarParticipacion),
                ),
                TextButton(
                  onPressed: () => controller.responder(aviso, false),
                  child: const Text(AppStrings.noAsistire),
                ),
              ],
            )
          : TextButton(
              onPressed: aviso.leida ? null : () => controller.marcarLeida(aviso),
              child: const Text(AppStrings.marcarLeida),
            ),
    );
  }
}
