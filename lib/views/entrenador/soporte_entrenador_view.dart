import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/soporte_entrenador_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

class SoporteEntrenadorView extends StatefulWidget {
  const SoporteEntrenadorView({super.key, required this.auth, this.controller});

  final AuthController auth;
  final SoporteEntrenadorController? controller;

  @override
  State<SoporteEntrenadorView> createState() => _SoporteEntrenadorViewState();
}

class _SoporteEntrenadorViewState extends State<SoporteEntrenadorView> {
  late final SoporteEntrenadorController controller =
      widget.controller ?? SoporteEntrenadorController();
  late final bool _propio = widget.controller == null;
  final _asunto = TextEditingController();
  final _descripcion = TextEditingController();
  String? _categoria;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.iniciar();
    });
  }

  @override
  void dispose() {
    _asunto.dispose();
    _descripcion.dispose();
    if (_propio) controller.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final enviado = await controller.crear(
      categoria: _categoria,
      asunto: _asunto.text,
      descripcion: _descripcion.text,
    );
    if (!mounted || !enviado) return;
    setState(() {
      _categoria = null;
      _asunto.clear();
      _descripcion.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(controller.mensaje ?? 'Solicitud enviada.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEntrenador.menu,
      rutaActiva: AppRoutes.entrenadorSoporte,
      subtituloPanel: 'Panel del entrenador',
      titulo: 'Soporte',
      descripcion:
          'Envía una solicitud a la coordinación y consulta su respuesta.',
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final dosColumnas =
                constraints.maxWidth >= AppSizes.perfilDosColumnas;
            final formulario = _FormularioSoporte(
              controller: controller,
              categoria: _categoria,
              asunto: _asunto,
              descripcion: _descripcion,
              onCategoria: (valor) {
                setState(() => _categoria = valor);
                controller.limpiarErrorFormulario();
              },
              onEnviar: _enviar,
            );
            final historial = _HistorialSoporte(controller: controller);

            if (!dosColumnas) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  formulario,
                  const SizedBox(height: AppSizes.space24),
                  historial,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 380, child: formulario),
                const SizedBox(width: AppSizes.space24),
                Expanded(child: historial),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FormularioSoporte extends StatelessWidget {
  const _FormularioSoporte({
    required this.controller,
    required this.categoria,
    required this.asunto,
    required this.descripcion,
    required this.onCategoria,
    required this.onEnviar,
  });

  final SoporteEntrenadorController controller;
  final String? categoria;
  final TextEditingController asunto;
  final TextEditingController descripcion;
  final ValueChanged<String?> onCategoria;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return _TarjetaSoporte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nueva solicitud', style: AppTextStyles.subtitle),
          const SizedBox(height: AppSizes.space4),
          Text(
            'Cuéntanos qué ocurrió para que la coordinación pueda ayudarte.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.space16),
          DropdownButtonFormField<String>(
            key: ValueKey(categoria),
            initialValue: categoria,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: SoporteEntrenadorController.categorias.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: controller.enviando ? null : onCategoria,
          ),
          const SizedBox(height: AppSizes.space16),
          TextField(
            controller: asunto,
            enabled: !controller.enviando,
            maxLength: SoporteEntrenadorController.maximoAsunto,
            textInputAction: TextInputAction.next,
            onChanged: (_) => controller.limpiarErrorFormulario(),
            decoration: const InputDecoration(
              labelText: 'Asunto',
              hintText: 'Resume el problema',
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          TextField(
            controller: descripcion,
            enabled: !controller.enviando,
            minLines: 4,
            maxLines: 7,
            maxLength: SoporteEntrenadorController.maximoDescripcion,
            onChanged: (_) => controller.limpiarErrorFormulario(),
            decoration: const InputDecoration(
              labelText: 'Descripción',
              hintText: 'Incluye los detalles necesarios para ayudarte',
              alignLabelWithHint: true,
            ),
          ),
          if (controller.errorFormulario != null) ...[
            const SizedBox(height: AppSizes.space8),
            MensajeError(texto: controller.errorFormulario!),
          ],
          const SizedBox(height: AppSizes.space16),
          BotonPrimario(
            texto: 'Enviar solicitud',
            icono: Icons.send_outlined,
            anchoCompleto: true,
            cargando: controller.enviando,
            onPressed: onEnviar,
          ),
        ],
      ),
    );
  }
}

class _HistorialSoporte extends StatelessWidget {
  const _HistorialSoporte({required this.controller});

  final SoporteEntrenadorController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Mis solicitudes', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSizes.space16),
        if (controller.error != null) ...[
          MensajeError(texto: controller.error!),
          const SizedBox(height: AppSizes.space16),
        ],
        if (controller.cargando && controller.tickets.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (controller.tickets.isEmpty)
          const EstadoVacio(
            icono: Icons.support_agent_outlined,
            titulo: 'No tienes solicitudes',
            texto: 'Cuando necesites ayuda, envía tu primera solicitud.',
          )
        else
          for (final ticket in controller.tickets) ...[
            _TicketCard(ticket: ticket),
            const SizedBox(height: AppSizes.space12),
          ],
      ],
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final TicketSoporte ticket;

  @override
  Widget build(BuildContext context) {
    final resuelto = ticket.estado == EstadoTicket.resuelto;
    final colorEstado = resuelto ? AppColors.success : AppColors.primary;
    return _TarjetaSoporte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(ticket.asunto, style: AppTextStyles.subtitle),
              ),
              const SizedBox(width: AppSizes.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space8,
                  vertical: AppSizes.space4,
                ),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                child: Text(
                  resuelto ? 'Resuelto' : 'Abierto',
                  style: AppTextStyles.label.copyWith(color: colorEstado),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space4),
          Text(
            '${SoporteEntrenadorController.categoriaEtiqueta(ticket.categoria)} · ${_fecha(ticket.fecha)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.space12),
          Text(ticket.descripcion, style: AppTextStyles.body),
          if (ticket.respuesta.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.space16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.space12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radius),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respuesta de coordinación',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space4),
                  Text(ticket.respuesta, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaSoporte extends StatelessWidget {
  const _TarjetaSoporte({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

String _fecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}
