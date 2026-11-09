import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_evento_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
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
                for (final estado in const [
                  EstadoEvento.pendiente,
                  EstadoEvento.aprobado,
                  EstadoEvento.rechazado,
                  EstadoEvento.cancelado,
                ])
                  ChoiceChip(
                    label: Text(_estado(estado)),
                    selected: eventos.filtroEstado == estado,
                    onSelected: (_) => eventos.filtrar(estado: estado),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (eventos.error != null)
              Text(
                eventos.error!,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            if (eventos.eventosFiltrados.isEmpty)
              Text(AppStrings.adminSinSolicitudes, style: AppTextStyles.body)
            else
              for (final evento in eventos.eventosFiltrados)
                ListTile(
                  title: Text(evento.titulo),
                  subtitle: Text(_detalle(evento, eventos.deportes)),
                  isThreeLine: true,
                  trailing: Wrap(
                    children: [
                      if (evento.estado == EstadoEvento.pendiente) ...[
                        TextButton(
                          onPressed: () => _aprobar(context, evento),
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

  Future<void> _aprobar(BuildContext context, Evento evento) async {
    var actual = evento;
    if (!_canchaLista(actual)) {
      final cancha = await _pedirCancha(context);
      if (cancha == null) return;
      final error = await eventos.actualizarEvento(
        evento: actual,
        titulo: actual.titulo,
        descripcion: actual.descripcion,
        canchaId: cancha.id,
      );
      if (error != null) return;
    }
    final resultado = await eventos.cambiarEstado(actual, EstadoEvento.aprobado);
    if (resultado == AppStrings.adminAsignaCancha && context.mounted) {
      final cancha = await _pedirCancha(context);
      if (cancha == null) return;
      final error = await eventos.actualizarEvento(
        evento: actual,
        titulo: actual.titulo,
        descripcion: actual.descripcion,
        canchaId: cancha.id,
      );
      if (error != null) return;
      await eventos.cambiarEstado(actual, EstadoEvento.aprobado);
    }
  }

  bool _canchaLista(Evento evento) {
    if (evento.canchaId.isEmpty) return false;
    for (final cancha in eventos.canchas) {
      if (cancha.id == evento.canchaId) return cancha.activa;
    }
    return false;
  }

  Future<Cancha?> _pedirCancha(BuildContext context) {
    final activas = eventos.canchas.where((cancha) => cancha.activa).toList();
    return showDialog<Cancha>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.adminAsignaCancha),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final cancha in activas)
              ListTile(
                title: Text(cancha.nombre),
                onTap: () => Navigator.pop(context, cancha),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancelar),
          ),
        ],
      ),
    );
  }
}

String _detalle(Evento evento, List<Deporte> deportes) {
  final disciplina = evento.deporteNombre ?? AppStrings.adminSinDisciplina;
  final hora =
      '${minutosATexto(evento.horaInicio)}–${minutosATexto(evento.horaFin)}';
  final capacidad = evento.capacidad > 0
      ? ' · Capacidad: ${evento.capacidad}'
      : '';
  return '$disciplina · ${evento.fecha} $hora\n'
      '${evento.canchaNombre} · ${_estado(evento.estado)}$capacidad\n'
      '${AppStrings.adminCreadoPor}: ${_creador(evento, deportes)}';
}

String _creador(Evento evento, List<Deporte> deportes) {
  final uid = evento.creadoPorUid;
  if (uid.isEmpty) return AppStrings.adminSinDato;
  for (final deporte in deportes) {
    if (deporte.entrenadorUid == uid && deporte.entrenadorNombre.isNotEmpty) {
      return deporte.entrenadorNombre;
    }
  }
  return 'Administración';
}

String _estado(EstadoEvento estado) {
  return switch (estado) {
    EstadoEvento.pendiente => AppStrings.adminPendientes,
    EstadoEvento.aprobado => AppStrings.adminAprobados,
    EstadoEvento.rechazado => AppStrings.adminRechazados,
    EstadoEvento.cancelado => AppStrings.adminCancelados,
  };
}
