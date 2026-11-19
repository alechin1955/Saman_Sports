import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/soporte_estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/formato_fecha.dart';
import 'package:saman_sports/core/utils/ticket_soporte_estudiante.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/views/estudiante/opciones_estudiante.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/home/widgets/etiqueta_ejemplo.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

/// Soporte del estudiante: formulario para crear un ticket y la lista de
/// sus tickets con la respuesta del administrador, en tiempo real.
class SoporteEstudianteView extends StatefulWidget {
  const SoporteEstudianteView({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final SoporteEstudianteController controller;

  @override
  State<SoporteEstudianteView> createState() => _SoporteEstudianteViewState();
}

class _SoporteEstudianteViewState extends State<SoporteEstudianteView> {
  final _asunto = TextEditingController();
  final _descripcion = TextEditingController();
  String? _categoria;
  String? _errorFormulario;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.iniciar();
    });
  }

  @override
  void dispose() {
    _asunto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final mensajes = ScaffoldMessenger.of(context);
    final error = await widget.controller.enviar(
      categoria: _categoria ?? '',
      asunto: _asunto.text,
      descripcion: _descripcion.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _errorFormulario = error);
      return;
    }
    setState(() {
      _errorFormulario = null;
      _categoria = null;
      _asunto.clear();
      _descripcion.clear();
    });
    mensajes.showSnackBar(
      const SnackBar(content: Text(AppStrings.soporteEnviado)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      auth: widget.auth,
      opciones: OpcionesEstudiante.menu,
      rutaActiva: AppRoutes.estudianteSoporte,
      subtituloPanel: AppStrings.panelEstudiante,
      titulo: AppStrings.soporte,
      descripcion: AppStrings.soporteDescripcion,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final formulario = _Formulario(
            enviando: widget.controller.enviando,
            categoria: _categoria,
            asunto: _asunto,
            descripcion: _descripcion,
            error: _errorFormulario,
            onCategoria: (valor) => setState(() => _categoria = valor),
            onEnviar: _enviar,
          );
          final lista = _MisTickets(controller: widget.controller);
          return LayoutBuilder(
            builder: (context, medidas) {
              if (medidas.maxWidth < AppSizes.perfilDosColumnas) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    formulario,
                    const SizedBox(height: AppSizes.space24),
                    lista,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: formulario),
                  const SizedBox(width: AppSizes.space24),
                  Expanded(flex: 3, child: lista),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.enviando,
    required this.categoria,
    required this.asunto,
    required this.descripcion,
    required this.error,
    required this.onCategoria,
    required this.onEnviar,
  });

  final bool enviando;
  final String? categoria;
  final TextEditingController asunto;
  final TextEditingController descripcion;
  final String? error;
  final ValueChanged<String?> onCategoria;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.soporteNuevoTicket, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSizes.space16),
          DropdownButtonFormField<String>(
            key: ValueKey(categoria),
            initialValue: categoria,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: AppStrings.soporteCategoria,
            ),
            items: categoriasSoporteEstudiante.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: enviando ? null : onCategoria,
          ),
          const SizedBox(height: AppSizes.space16),
          TextField(
            key: const ValueKey('soporte_asunto'),
            controller: asunto,
            enabled: !enviando,
            maxLength: maximoAsuntoSoporte,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: AppStrings.soporteAsunto,
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          TextField(
            key: const ValueKey('soporte_descripcion'),
            controller: descripcion,
            enabled: !enviando,
            minLines: 4,
            maxLines: 7,
            maxLength: maximoDescripcionSoporte,
            decoration: const InputDecoration(
              labelText: AppStrings.soporteDescripcionCampo,
              alignLabelWithHint: true,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSizes.space8),
            MensajeError(texto: error!),
          ],
          const SizedBox(height: AppSizes.space16),
          BotonPrimario(
            texto: enviando
                ? AppStrings.soporteEnviando
                : AppStrings.soporteEnviar,
            icono: Icons.send_outlined,
            anchoCompleto: true,
            cargando: enviando,
            onPressed: onEnviar,
          ),
        ],
      ),
    );
  }
}

class _MisTickets extends StatelessWidget {
  const _MisTickets({required this.controller});

  final SoporteEstudianteController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final Widget contenido;
    if (c.error != null) {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MensajeError(texto: c.error!),
          const SizedBox(height: AppSizes.space16),
          BotonSecundario(texto: AppStrings.reintentar, onPressed: c.iniciar),
        ],
      );
    } else if (c.cargando) {
      contenido = const EtiquetaEjemplo(cargando: true);
    } else if (c.tickets.isEmpty) {
      contenido = const EstadoVacio(
        icono: Icons.support_agent_outlined,
        titulo: AppStrings.soporteSinTickets,
        texto: AppStrings.soporteSinTicketsTexto,
      );
    } else {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final ticket in c.tickets) ...[
            _TarjetaTicket(ticket: ticket),
            const SizedBox(height: AppSizes.space12),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.soporteMisTickets, style: AppTextStyles.subtitle),
        const SizedBox(height: AppSizes.space16),
        contenido,
      ],
    );
  }
}

class _TarjetaTicket extends StatelessWidget {
  const _TarjetaTicket({required this.ticket});

  final TicketSoporte ticket;

  @override
  Widget build(BuildContext context) {
    final resuelto = ticket.estado == EstadoTicket.resuelto;
    final color = resuelto ? AppColors.success : AppColors.primary;
    final tieneRespuesta = ticket.respuesta.trim().isNotEmpty;
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSizes.space8,
            runSpacing: AppSizes.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(ticket.asunto, style: AppTextStyles.label),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.space8,
                  vertical: AppSizes.space4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                ),
                child: Text(
                  resuelto
                      ? AppStrings.soporteResuelto
                      : AppStrings.soporteAbierto,
                  style: AppTextStyles.bodySmall.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space4),
          Text(
            '${ticket.categoriaVisible} · ${fechaCorta(ticket.fecha)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.space8),
          Text(ticket.descripcion, style: AppTextStyles.body),
          const SizedBox(height: AppSizes.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.space12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: tieneRespuesta
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.soporteRespuesta,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.space4),
                      Text(ticket.respuesta, style: AppTextStyles.body),
                    ],
                  )
                : Text(
                    AppStrings.soporteSinRespuesta,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
