import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/controllers/eventos_entrenador_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';
import 'package:saman_sports/views/entrenador/widgets/crear_evento_dialog.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

class EventosEntrenadorView extends StatefulWidget {
  const EventosEntrenadorView({
    super.key,
    required this.auth,
    this.controller,
    this.entrenador,
  });

  final AuthController auth;
  final EventosEntrenadorController? controller;
  final EntrenadorController? entrenador;

  @override
  State<EventosEntrenadorView> createState() => _EventosEntrenadorViewState();
}

class _EventosEntrenadorViewState extends State<EventosEntrenadorView> {
  late final EventosEntrenadorController controller =
      widget.controller ?? EventosEntrenadorController();
  late final EntrenadorController entrenador =
      widget.entrenador ?? EntrenadorController();
  late final bool _controladorPropio = widget.controller == null;
  late final bool _entrenadorPropio = widget.entrenador == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.iniciar();
      entrenador.cargar(cargarNominaInicial: false);
    });
  }

  @override
  void dispose() {
    if (_controladorPropio) controller.dispose();
    if (_entrenadorPropio) entrenador.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (entrenador.disciplinas.isEmpty) return;
    controller.limpiarMensajes();
    final creado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CrearEventoDialog(
        controller: controller,
        disciplinas: entrenador.disciplinas,
      ),
    );
    if (creado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de evento enviada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEntrenador.menu,
      rutaActiva: AppRoutes.entrenadorEventos,
      subtituloPanel: 'Panel del entrenador',
      titulo: 'Eventos',
      descripcion: 'Solicita eventos y consulta si fueron aprobados, rechazados o siguen pendientes.',
      child: ListenableBuilder(
        listenable: Listenable.merge([controller, entrenador]),
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: entrenador.cargando || entrenador.disciplinas.isEmpty
                    ? null
                    : _crear,
                icon: const Icon(Icons.add),
                label: const Text('Solicitar evento'),
              ),
            ),
            if (entrenador.disciplinas.isEmpty && !entrenador.cargando) ...[
              const SizedBox(height: AppSizes.space12),
              const Text(
                'Necesitas una disciplina asignada para solicitar eventos.',
              ),
            ],
            const SizedBox(height: AppSizes.space24),
            if (controller.error != null && controller.eventos.isEmpty)
              MensajeError(texto: controller.error!)
            else if (controller.cargando)
              const Center(child: CircularProgressIndicator())
            else if (controller.eventos.isEmpty)
              const EstadoVacio(
                icono: Icons.event_outlined,
                titulo: 'No has solicitado eventos',
                texto: 'Tus solicitudes y la respuesta de la coordinación aparecerán aquí.',
              )
            else
              for (final evento in controller.eventos)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.space12),
                  child: _EventoCard(evento: evento),
                ),
          ],
        ),
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final (color, texto) = switch (evento.estado) {
      EstadoEvento.aprobado => (AppColors.success, 'Aprobado'),
      EstadoEvento.rechazado => (AppColors.error, 'Rechazado'),
      EstadoEvento.cancelado => (AppColors.textSecondary, 'Cancelado'),
      EstadoEvento.pendiente => (AppColors.primary, 'Pendiente'),
    };
    return Container(
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(evento.titulo, style: AppTextStyles.title)),
              Chip(
                avatar: Icon(Icons.circle, size: 10, color: color),
                label: Text(texto),
                side: BorderSide.none,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space8),
          Text(
            '${evento.deporteNombre ?? 'Disciplina'} · ${evento.fecha} · ${evento.horaInicio.toString().padLeft(2, '0')}:00–${evento.horaFin.toString().padLeft(2, '0')}:00',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSizes.space4),
          Text(
            '${evento.canchaNombre}${evento.capacidad > 0 ? ' · ${evento.capacidad} personas' : ''}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (evento.descripcion.isNotEmpty) ...[
            const SizedBox(height: AppSizes.space12),
            Text(evento.descripcion, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}
