import 'package:flutter/material.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/evento_publico.dart';

class ProximosEventosSection extends StatelessWidget {
  const ProximosEventosSection({super.key, required this.eventos});

  final List<EventoPublico> eventos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.proximosEventos, style: AppTextStyles.title),
          const SizedBox(height: AppSizes.space16),
          if (eventos.isEmpty)
            Text(AppStrings.sinProximosEventos, style: AppTextStyles.body)
          else
            Wrap(
              spacing: AppSizes.space12,
              runSpacing: AppSizes.space12,
              children: [
                for (final evento in eventos)
                  SizedBox(
                    width: 280,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.space12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(evento.titulo, style: AppTextStyles.label),
                            Text(evento.deporteNombre),
                            Text(evento.fecha),
                            Text(minutosATexto(evento.horaInicio)),
                            Text(evento.canchaNombre),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
