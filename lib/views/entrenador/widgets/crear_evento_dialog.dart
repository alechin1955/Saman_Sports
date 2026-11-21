import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saman_sports/controllers/eventos_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

class CrearEventoDialog extends StatefulWidget {
  const CrearEventoDialog({
    super.key,
    required this.controller,
    required this.disciplinas,
    required this.canchas,
    this.inicial,
  });

  final EventosEntrenadorController controller;
  final List<Deporte> disciplinas;
  final List<Cancha> canchas;
  final Evento? inicial;

  @override
  State<CrearEventoDialog> createState() => _CrearEventoDialogState();
}

class _CrearEventoDialogState extends State<CrearEventoDialog> {
  final nombre = TextEditingController();
  final capacidad = TextEditingController();
  final descripcion = TextEditingController();
  Deporte? disciplina;
  Cancha? cancha;
  DateTime fecha = DateTime.now();
  int horaInicio = 840;
  int horaFin = 960;

  @override
  void initState() {
    super.initState();
    final inicial = widget.inicial;
    disciplina = widget.disciplinas
        .where((item) => item.id == inicial?.deporteId)
        .firstOrNull ?? widget.disciplinas.firstOrNull;
    cancha = widget.canchas
        .where((item) => item.id == inicial?.canchaId && item.activa)
        .firstOrNull ?? widget.canchas.where((item) => item.activa).firstOrNull;
    if (inicial == null) {
      final manana = DateTime.now().add(const Duration(days: 1));
      fecha = DateTime(manana.year, manana.month, manana.day);
    } else {
      nombre.text = inicial.titulo;
      descripcion.text = inicial.descripcion;
      capacidad.text = '${inicial.capacidad}';
      horaInicio = inicial.horaInicio;
      horaFin = inicial.horaFin;
      fecha = DateTime.tryParse(inicial.fecha) ?? DateTime.now();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.observarCancha(cancha?.id);
    });
  }

  @override
  void dispose() {
    nombre.dispose();
    capacidad.dispose();
    descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (elegida != null && mounted) setState(() => fecha = elegida);
  }

  Future<void> _enviar() async {
    final deporte = disciplina;
    final seleccionada = cancha;
    if (deporte == null || seleccionada == null) return;
    final inicial = widget.inicial;
    final ok = inicial == null
        ? await widget.controller.solicitar(
            nombre: nombre.text,
            disciplina: deporte,
            cancha: seleccionada,
            fecha: fecha,
            horaInicio: horaInicio,
            horaFin: horaFin,
            capacidad: int.tryParse(capacidad.text) ?? 0,
            descripcion: descripcion.text,
          )
        : await widget.controller.editarSolicitud(
            evento: inicial,
            nombre: nombre.text,
            disciplina: deporte,
            cancha: seleccionada,
            fecha: fecha,
            horaInicio: horaInicio,
            horaFin: horaFin,
            capacidad: int.tryParse(capacidad.text) ?? 0,
            descripcion: descripcion.text,
          );
    if (ok && mounted) Navigator.pop(context, true);
  }

  void _cancelar() {
    widget.controller.limpiarMensajes();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final choque = cancha == null || widget.controller.cargandoOcupacion
            ? null
            : widget.controller.choqueHorario(
                cancha: cancha!,
                fecha: fecha,
                horaInicio: horaInicio,
                horaFin: horaFin,
              );
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          title: Text(
            widget.inicial == null
                ? AppStrings.entSolicitarEvento
                : AppStrings.entEditarSolicitud,
            style: AppTextStyles.title,
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.error != null) ...[
                    MensajeError(texto: widget.controller.error!),
                    const SizedBox(height: AppSizes.space12),
                  ],
                  TextField(
                    controller: nombre,
                    decoration: const InputDecoration(
                      labelText: AppStrings.entNombreEvento,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space12),
                  DropdownButtonFormField<Deporte>(
                    initialValue: disciplina,
                    decoration: const InputDecoration(
                      labelText: AppStrings.adminDisciplina,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final item in widget.disciplinas)
                        DropdownMenuItem(value: item, child: Text(item.nombre)),
                    ],
                    onChanged: widget.inicial == null
                        ? (valor) => setState(() => disciplina = valor)
                        : null,
                  ),
                  const SizedBox(height: AppSizes.space12),
                  DropdownButtonFormField<Cancha>(
                    initialValue: cancha,
                    decoration: const InputDecoration(
                      labelText: AppStrings.adminCancha,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final item in widget.canchas.where(
                        (cancha) => cancha.activa,
                      ))
                        DropdownMenuItem(value: item, child: Text(item.nombre)),
                    ],
                    onChanged: (valor) {
                      setState(() => cancha = valor);
                      widget.controller.observarCancha(valor?.id);
                    },
                  ),
                  const SizedBox(height: AppSizes.space12),
                  OutlinedButton.icon(
                    onPressed: _elegirFecha,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(AppStrings.entFechaEtiqueta(_fecha(fecha))),
                  ),
                  const SizedBox(height: AppSizes.space12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final ancho = constraints.maxWidth < 420
                          ? constraints.maxWidth
                          : (constraints.maxWidth - AppSizes.space12) / 2;
                      return Wrap(
                        spacing: AppSizes.space12,
                        runSpacing: AppSizes.space12,
                        children: [
                          SizedBox(
                            width: ancho,
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: horaInicio,
                              decoration: const InputDecoration(
                                labelText: AppStrings.adminHoraInicio,
                                border: OutlineInputBorder(),
                              ),
                              items: _horas
                                  .map(
                                    (hora) => DropdownMenuItem(
                                      value: hora,
                                      child: Text(minutosATexto(hora)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (valor) {
                                if (valor != null) {
                                  setState(() => horaInicio = valor);
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: ancho,
                            child: DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: horaFin,
                              decoration: const InputDecoration(
                                labelText: AppStrings.adminHoraFin,
                                border: OutlineInputBorder(),
                              ),
                              items: _horas
                                  .map(
                                    (hora) => DropdownMenuItem(
                                      value: hora,
                                      child: Text(minutosATexto(hora)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (valor) {
                                if (valor != null) {
                                  setState(() => horaFin = valor);
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.space12),
                  if (widget.controller.cargandoOcupacion)
                    const LinearProgressIndicator()
                  else if (widget.controller.errorOcupacion != null)
                    MensajeError(texto: widget.controller.errorOcupacion!)
                  else if (choque != null)
                    MensajeError(texto: choque),
                  if (widget.controller.cargandoOcupacion ||
                      widget.controller.errorOcupacion != null ||
                      choque != null)
                    const SizedBox(height: AppSizes.space12),
                  TextField(
                    controller: capacidad,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: AppStrings.entCapacidad,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space12),
                  TextField(
                    controller: descripcion,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: AppStrings.adminDescripcion,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: widget.controller.guardando ? null : _cancelar,
              child: const Text(AppStrings.cancelar),
            ),
            FilledButton.icon(
              onPressed:
                  widget.controller.guardando ||
                      widget.controller.cargandoOcupacion ||
                      widget.controller.errorOcupacion != null ||
                      cancha == null ||
                      choque != null
                  ? null
                  : _enviar,
              icon: widget.controller.guardando
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text(AppStrings.entEnviarSolicitud),
            ),
          ],
        );
      },
    );
  }

  static const _horas = [
    360,
    420,
    480,
    540,
    600,
    660,
    720,
    780,
    840,
    900,
    960,
    1020,
    1080,
    1140,
    1200,
    1260,
    1320,
  ];

  String _fecha(DateTime valor) =>
      '${valor.day.toString().padLeft(2, '0')}/${valor.month.toString().padLeft(2, '0')}/${valor.year}';
}
