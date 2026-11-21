import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/proximos_eventos_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/evento_publico.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

class ProximosEventosCard extends StatelessWidget {
  const ProximosEventosCard({super.key, required this.controller});

  final ProximosEventosController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.error != null) {
          return MensajeError(texto: controller.error!);
        }
        final eventos = controller.eventos;
        if (eventos.isEmpty) return Text(AppStrings.sinProximosEventos);
        final movil = MediaQuery.sizeOf(context).width < AppSizes.mobile;
        final hijos = [
          for (final evento in eventos)
            _Evento(controller: controller, evento: evento),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.proximosEventos, style: AppTextStyles.title),
            const SizedBox(height: AppSizes.space12),
            if (movil)
              Column(children: hijos)
            else
              Wrap(spacing: AppSizes.space12, runSpacing: AppSizes.space12, children: hijos),
          ],
        );
      },
    );
  }
}

class _Evento extends StatelessWidget {
  const _Evento({required this.controller, required this.evento});

  final ProximosEventosController controller;
  final EventoPublico evento;

  @override
  Widget build(BuildContext context) {
    final confirmar = controller.puedeConfirmar(evento);
    final estado = controller.participacion[evento.id];
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(evento.titulo, style: AppTextStyles.label),
              Text('${evento.fecha} · ${minutosATexto(evento.horaInicio)}'),
              Text('${evento.canchaNombre} · ${evento.deporteNombre}'),
              if (confirmar) ...[
                const Chip(label: Text(AppStrings.tuDeporte)),
                if (estado == EstadoParticipacion.confirmado)
                  Text(AppStrings.participacionConfirmada)
                else if (estado == EstadoParticipacion.rechazado)
                  Text(AppStrings.participacionRechazada)
                else
                  Wrap(
                    children: [
                      TextButton(
                        onPressed: () => controller.responder(evento, true),
                        child: const Text(AppStrings.confirmarParticipacion),
                      ),
                      TextButton(
                        onPressed: () => controller.responder(evento, false),
                        child: const Text(AppStrings.noAsistire),
                      ),
                    ],
                  ),
              ],
              if (controller.modo == ModoEventos.entrenador)
                Text(
                  '${controller.confirmados[evento.id] ?? 0} ${AppStrings.confirmadosEvento}',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
