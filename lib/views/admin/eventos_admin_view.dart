import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_evento_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/views/admin/evento_form_dialog.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';

class EventosAdminView extends StatelessWidget {
  const EventosAdminView({super.key, required this.eventos});

  final AdminEventoController eventos;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: eventos,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSizes.space8,
              runSpacing: AppSizes.space8,
              children: [
                BotonPrimario(
                  texto: AppStrings.adminNuevoEvento,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => EventoFormDialog(eventos: eventos),
                  ),
                ),
                ChoiceChip(
                  label: Text(AppStrings.adminTodos),
                  selected: eventos.filtroEstado == null,
                  onSelected: (_) => eventos.filtrar(limpiar: true),
                ),
                for (final estado in EstadoEvento.values)
                  ChoiceChip(
                    label: Text(_estado(estado)),
                    selected: eventos.filtroEstado == estado,
                    onSelected: (_) => eventos.filtrar(estado: estado),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (eventos.eventosFiltrados.isEmpty)
              Text(AppStrings.adminSinSolicitudes, style: AppTextStyles.body)
            else
              for (final evento in eventos.eventosFiltrados)
                ListTile(
                  title: Text(evento.titulo),
                  subtitle: Text('${evento.fecha} · ${_estado(evento.estado)}'),
                  trailing: Wrap(
                    children: [
                      if (evento.estado == EstadoEvento.pendiente) ...[
                        TextButton(
                          onPressed: () => eventos.cambiarEstado(
                            evento,
                            EstadoEvento.aprobado,
                          ),
                          child: Text(AppStrings.adminAprobar),
                        ),
                        TextButton(
                          onPressed: () => eventos.cambiarEstado(
                            evento,
                            EstadoEvento.rechazado,
                          ),
                          child: Text(AppStrings.adminRechazar),
                        ),
                      ],
                      if (evento.estado == EstadoEvento.aprobado)
                        TextButton(
                          onPressed: () => eventos.cambiarEstado(
                            evento,
                            EstadoEvento.cancelado,
                          ),
                          child: Text(AppStrings.cancelar),
                        ),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}

String _estado(EstadoEvento estado) {
  return switch (estado) {
    EstadoEvento.pendiente => AppStrings.adminPendientes,
    EstadoEvento.aprobado => AppStrings.adminAprobados,
    EstadoEvento.rechazado => AppStrings.adminRechazados,
    EstadoEvento.cancelado => AppStrings.adminCancelados,
  };
}
