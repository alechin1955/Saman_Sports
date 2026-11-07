import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saman_sports/controllers/eventos_entrenador_controller.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';

class CrearEventoDialog extends StatefulWidget {
  const CrearEventoDialog({
    super.key,
    required this.controller,
    required this.disciplinas,
  });

  final EventosEntrenadorController controller;
  final List<Deporte> disciplinas;

  @override
  State<CrearEventoDialog> createState() => _CrearEventoDialogState();
}

class _CrearEventoDialogState extends State<CrearEventoDialog> {
  final nombre = TextEditingController();
  final ubicacion = TextEditingController();
  final capacidad = TextEditingController();
  final descripcion = TextEditingController();
  Deporte? disciplina;
  DateTime fecha = DateTime.now();
  int horaInicio = 840;
  int horaFin = 960;

  @override
  void initState() {
    super.initState();
    disciplina = widget.disciplinas.firstOrNull;
    final manana = DateTime.now().add(const Duration(days: 1));
    fecha = DateTime(manana.year, manana.month, manana.day);
  }

  @override
  void dispose() {
    nombre.dispose();
    ubicacion.dispose();
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
    if (deporte == null) return;
    final ok = await widget.controller.solicitar(
      nombre: nombre.text,
      disciplina: deporte,
      fecha: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
      ubicacion: ubicacion.text,
      capacidad: int.tryParse(capacidad.text) ?? 0,
      descripcion: descripcion.text,
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      title: Text('Solicitar evento', style: AppTextStyles.title),
      content: SizedBox(
        width: 560,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => SingleChildScrollView(
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
                    labelText: 'Nombre del evento',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSizes.space12),
                DropdownButtonFormField<Deporte>(
                  initialValue: disciplina,
                  decoration: const InputDecoration(
                    labelText: 'Disciplina',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final item in widget.disciplinas)
                      DropdownMenuItem(value: item, child: Text(item.nombre)),
                  ],
                  onChanged: (valor) => setState(() => disciplina = valor),
                ),
                const SizedBox(height: AppSizes.space12),
                OutlinedButton.icon(
                  onPressed: _elegirFecha,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Fecha: ${_fecha(fecha)}'),
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
                              labelText: 'Hora de inicio',
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
                              labelText: 'Hora de fin',
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
                          child: TextField(
                            controller: ubicacion,
                            decoration: const InputDecoration(
                              labelText: 'Ubicación',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: ancho,
                          child: TextField(
                            controller: capacidad,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Capacidad',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSizes.space12),
                TextField(
                  controller: descripcion,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.controller.guardando
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: widget.controller.guardando ? null : _enviar,
          icon: widget.controller.guardando
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: const Text('Enviar solicitud'),
        ),
      ],
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
