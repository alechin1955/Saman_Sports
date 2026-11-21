import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/controllers/eventos_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
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

  Future<void> _editar(Evento evento) async {
    controller.limpiarMensajes();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CrearEventoDialog(
        controller: controller,
        disciplinas: entrenador.disciplinas,
        canchas: controller.canchas,
        inicial: evento,
      ),
    );
    final mensaje = controller.mensaje;
    controller.limpiarMensajes();
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje ?? AppStrings.entSolicitudActualizada)),
      );
    }
  }

  Future<void> _cancelar(Evento evento) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.entCancelarSolicitud),
        content: const Text(AppStrings.entConfirmarCancelarSolicitud),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.entCancelarSolicitud),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final hecho = await controller.cancelarSolicitud(evento);
    if (!mounted || !hecho) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(controller.mensaje ?? AppStrings.entSolicitudCancelada),
      ),
    );
    controller.limpiarMensajes();
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
        canchas: controller.canchas,
      ),
    );
    final mensaje = controller.mensaje;
    controller.limpiarMensajes();
    if (creado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje ?? AppStrings.entSolicitudEnviadaCorta)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEntrenador.menu,
      rutaActiva: AppRoutes.entrenadorEventos,
      subtituloPanel: AppStrings.entPanel,
      titulo: AppStrings.adminEventos,
      descripcion: AppStrings.entEventosDescripcion,
      child: ListenableBuilder(
        listenable: Listenable.merge([controller, entrenador]),
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed:
                    entrenador.cargando ||
                        entrenador.disciplinas.isEmpty ||
                        controller.cargandoCanchas ||
                        controller.canchas.isEmpty
                    ? null
                    : _crear,
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.entSolicitarEvento),
              ),
            ),
            if (entrenador.disciplinas.isEmpty && !entrenador.cargando) ...[
              const SizedBox(height: AppSizes.space12),
              const Text(AppStrings.entDisciplinaRequerida),
            ],
            if (controller.errorCanchas != null) ...[
              const SizedBox(height: AppSizes.space12),
              MensajeError(texto: controller.errorCanchas!),
            ] else if (controller.canchas.isEmpty &&
                !controller.cargandoCanchas) ...[
              const SizedBox(height: AppSizes.space12),
              const Text(
                AppStrings.entSinCanchasEvento,
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
                titulo: AppStrings.entSinSolicitudesEvento,
                texto: AppStrings.entSinSolicitudesEventoTexto,
              )
            else
              for (final evento in controller.eventos)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.space12),
                  child: _EventoCard(
                    evento: evento,
                    onEditar: evento.estado == EstadoEvento.pendiente
                        ? () => _editar(evento)
                        : null,
                    onCancelar: evento.estado == EstadoEvento.pendiente
                        ? () => _cancelar(evento)
                        : null,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.evento, this.onEditar, this.onCancelar});

  final Evento evento;
  final VoidCallback? onEditar;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context) {
    final (color, texto) = switch (evento.estado) {
      EstadoEvento.aprobado => (AppColors.success, AppStrings.entAprobado),
      EstadoEvento.rechazado => (AppColors.error, AppStrings.entRechazado),
      EstadoEvento.cancelado => (AppColors.textSecondary, AppStrings.entCancelado),
      EstadoEvento.pendiente => (AppColors.primary, AppStrings.entPendiente),
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
            '${evento.deporteNombre ?? AppStrings.adminDisciplina} · ${evento.fecha} · ${minutosATexto(evento.horaInicio)}–${minutosATexto(evento.horaFin)}',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSizes.space4),
          Text(
            '${evento.canchaNombre}${evento.capacidad > 0 ? ' · ${AppStrings.entPersonasCapacidad(evento.capacidad)}' : ''}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (evento.descripcion.isNotEmpty) ...[
            const SizedBox(height: AppSizes.space12),
            Text(evento.descripcion, style: AppTextStyles.bodySmall),
          ],
          if (onEditar != null || onCancelar != null) ...[
            const SizedBox(height: AppSizes.space12),
            Wrap(
              spacing: AppSizes.space8,
              children: [
                if (onEditar != null)
                  TextButton(
                    onPressed: onEditar,
                    child: const Text(AppStrings.editar),
                  ),
                if (onCancelar != null)
                  TextButton(
                    onPressed: onCancelar,
                    child: const Text(AppStrings.entCancelarSolicitud),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
