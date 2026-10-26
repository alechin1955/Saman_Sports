import 'package:saman_sports/views/entrenador/widgets/boton_exportar_asistencia.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

class RegistroAsistencia extends StatelessWidget {
  const RegistroAsistencia({
    super.key,
    required this.controller,
    this.disciplina = '',
  });
  final AsistenciaController controller;
  final String disciplina;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      if (c.deporteId == null) return const SizedBox.shrink();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Registro de asistencia', style: AppTextStyles.title),
              const SizedBox(height: 12),
              BotonExportarAsistencia(
                key: ValueKey(c.deporteId),
                controller: c,
                disciplina: disciplina,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Fecha: ${claveFecha(c.fecha)}'),
                    onPressed: c.guardando || c.cargando || c.cambios
                        ? null
                        : () async {
                            final hoy = DateTime.now();
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: c.fecha,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(hoy.year, hoy.month, hoy.day),
                            );
                            if (fecha != null && context.mounted) {
                              await c.abrir(c.deporteId!, fecha, c.alumnos);
                            }
                          },
                  ),
                  Text(
                    '${c.presentes} presentes · ${c.ausentes} ausentes · ${c.alumnos.length - c.presentes - c.ausentes} sin registrar',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (c.cargando)
                const Center(child: CircularProgressIndicator())
              else if (c.error != null) ...[
                Text(c.error!, style: const TextStyle(color: AppColors.error)),
                OutlinedButton(
                  onPressed: () => c.abrir(c.deporteId!, c.fecha, c.alumnos),
                  child: const Text('Reintentar asistencia'),
                ),
              ] else ...[
                if (c.alumnos.isEmpty)
                  const Text(
                    'No hay estudiantes confirmados para registrar asistencia.',
                  ),
                for (final alumno in c.alumnos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alumno.nombre, style: AppTextStyles.subtitle),
                        Text('Carnet: ${alumno.carnet}'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Presente'),
                              selected:
                                  c.estados[alumno.inscripcionId] ==
                                  EstadoAsistencia.presente,
                              onSelected: c.guardando
                                  ? null
                                  : (_) => c.marcar(
                                      alumno.inscripcionId,
                                      EstadoAsistencia.presente,
                                    ),
                            ),
                            ChoiceChip(
                              label: const Text('Ausente'),
                              selected:
                                  c.estados[alumno.inscripcionId] ==
                                  EstadoAsistencia.ausente,
                              onSelected: c.guardando
                                  ? null
                                  : (_) => c.marcar(
                                      alumno.inscripcionId,
                                      EstadoAsistencia.ausente,
                                    ),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                if (c.mensaje != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(c.mensaje!, style: AppTextStyles.body),
                  ),
                if (c.cambios)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Tienes cambios sin guardar. Guarda o descarta antes de cambiar de disciplina o fecha.',
                    ),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: c.completa && c.cambios && !c.guardando
                          ? c.guardar
                          : null,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        c.guardando ? 'Guardando…' : 'Guardar asistencia',
                      ),
                    ),
                    if (c.cambios)
                      OutlinedButton(
                        onPressed: c.guardando
                            ? null
                            : () async {
                                final descartar = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('¿Descartar cambios?'),
                                    content: const Text(
                                      'Se recuperará la última asistencia guardada de esta fecha.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Continuar editando'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Descartar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (descartar == true) {
                                  await c.abrir(
                                    c.deporteId!,
                                    c.fecha,
                                    c.alumnos,
                                    descartar: true,
                                  );
                                }
                              },
                        child: const Text('Descartar cambios'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
