import 'package:saman_sports/views/entrenador/widgets/boton_exportar_asistencia.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';

/// Lista de la nómina con una columna por estado: el entrenador marca a todos
/// y guarda la sesión completa de una sola vez.
class RegistroAsistencia extends StatelessWidget {
  const RegistroAsistencia({
    super.key,
    required this.controller,
    this.disciplina = '',
  });
  final AsistenciaController controller;
  final String disciplina;

  /// Por debajo de este ancho la tabla pasa a una fila por alumno.
  static const double anchoTabla = 800;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      if (c.deporteId == null) return const SizedBox.shrink();
      final sinRegistrar = c.alumnos.length - c.presentes - c.ausentes;
      return Container(
        padding: const EdgeInsets.all(AppSizes.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Registro de asistencia', style: AppTextStyles.title),
            const SizedBox(height: AppSizes.space12),
            BotonExportarAsistencia(
              key: ValueKey(c.deporteId),
              controller: c,
              disciplina: disciplina,
            ),
            const SizedBox(height: AppSizes.space12),
            Wrap(
              spacing: AppSizes.space12,
              runSpacing: AppSizes.space8,
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
                  '${c.presentes} presentes · ${c.ausentes} ausentes · $sinRegistrar sin registrar',
                  style: AppTextStyles.body,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (c.cargando)
              const Center(child: CircularProgressIndicator())
            else if (c.error != null) ...[
              Text(c.error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: AppSizes.space8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => c.abrir(c.deporteId!, c.fecha, c.alumnos),
                  child: const Text('Reintentar asistencia'),
                ),
              ),
            ] else if (c.alumnos.isEmpty)
              const Text(
                'No hay estudiantes confirmados para registrar asistencia.',
              )
            else ...[
              LayoutBuilder(
                builder: (context, restricciones) =>
                    restricciones.maxWidth >= anchoTabla
                    ? _TablaAsistencia(controller: c)
                    : _ListaCompacta(controller: c),
              ),
              const SizedBox(height: AppSizes.space16),
              if (c.mensaje != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.space12),
                  child: Text(c.mensaje!, style: AppTextStyles.body),
                ),
              if (c.cambios && !c.completa)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.space12),
                  child: Text(
                    sinRegistrar == 1
                        ? 'Falta 1 estudiante por marcar para poder guardar.'
                        : 'Faltan $sinRegistrar estudiantes por marcar para poder guardar.',
                    style: AppTextStyles.bodySmall,
                  ),
                )
              else if (c.cambios)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.space12),
                  child: Text(
                    'Tienes cambios sin guardar. Guarda o descarta antes de cambiar de disciplina o fecha.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              Wrap(
                spacing: AppSizes.space12,
                runSpacing: AppSizes.space8,
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
                          : () => _confirmarDescarte(context),
                      child: const Text('Descartar cambios'),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );

  Future<void> _confirmarDescarte(BuildContext context) async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Se recuperará la última asistencia guardada de esta fecha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true) {
      await controller.abrir(
        controller.deporteId!,
        controller.fecha,
        controller.alumnos,
        descartar: true,
      );
    }
  }
}

/// Las tres columnas de la tabla. `null` es «Sin registrar».
const List<EstadoAsistencia?> _opciones = [
  EstadoAsistencia.presente,
  EstadoAsistencia.ausente,
  null,
];

String _etiqueta(EstadoAsistencia? estado) => switch (estado) {
  EstadoAsistencia.presente => 'Presente',
  EstadoAsistencia.ausente => 'Ausente',
  null => 'Sin registrar',
};

const _borde = BorderSide(color: AppColors.border);

class _TablaAsistencia extends StatelessWidget {
  const _TablaAsistencia({required this.controller});
  final AsistenciaController controller;

  static const double _anchoOpcion = 150;
  static const double _anchoCarnet = 140;

  @override
  Widget build(BuildContext context) {
    final encabezado = AppTextStyles.label.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.background,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.space16,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Estudiante', style: encabezado),
                      ),
                    ),
                  ),
                  _celdaCarnet(Text('Carnet', style: encabezado)),
                  Container(
                    width: _anchoOpcion * _opciones.length,
                    decoration: const BoxDecoration(
                      border: Border(left: _borde),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.space8),
                          child: Text('Asistencia', style: encabezado),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(top: _borde),
                          ),
                          child: Row(
                            children: [
                              for (final (i, opcion) in _opciones.indexed)
                                Container(
                                  // El borde izquierdo del grupo ocupa 1 px.
                                  width: i == 0
                                      ? _anchoOpcion - 1
                                      : _anchoOpcion,
                                  padding: const EdgeInsets.all(
                                    AppSizes.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: i == 0
                                        ? null
                                        : const Border(left: _borde),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _etiqueta(opcion),
                                    style: encabezado,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final alumno in controller.alumnos)
            DecoratedBox(
              decoration: const BoxDecoration(border: Border(top: _borde)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.space16,
                          vertical: AppSizes.space12,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            alumno.nombre,
                            style: AppTextStyles.label,
                          ),
                        ),
                      ),
                    ),
                    _celdaCarnet(
                      Text(
                        alumno.carnet,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    for (final opcion in _opciones)
                      Container(
                        width: _anchoOpcion,
                        decoration: const BoxDecoration(
                          border: Border(left: _borde),
                        ),
                        child: _OpcionAsistencia(
                          controller: controller,
                          alumno: alumno,
                          opcion: opcion,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _celdaCarnet(Widget child) => Container(
    width: _anchoCarnet,
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16),
    decoration: const BoxDecoration(border: Border(left: _borde)),
    alignment: Alignment.centerLeft,
    child: child,
  );
}

class _ListaCompacta extends StatelessWidget {
  const _ListaCompacta({required this.controller});
  final AsistenciaController controller;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppSizes.radius),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, alumno) in controller.alumnos.indexed)
          Container(
            padding: const EdgeInsets.all(AppSizes.space12),
            decoration: BoxDecoration(
              border: i == 0 ? null : const Border(top: _borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NombreAlumno(alumno: alumno),
                const SizedBox(height: AppSizes.space8),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (j, opcion) in _opciones.indexed) ...[
                        if (j > 0) const SizedBox(width: AppSizes.space8),
                        Expanded(
                          child: _OpcionAsistencia(
                            controller: controller,
                            alumno: alumno,
                            opcion: opcion,
                            compacta: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _NombreAlumno extends StatelessWidget {
  const _NombreAlumno({required this.alumno});
  final AlumnoInscrito alumno;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(alumno.nombre, style: AppTextStyles.label),
      Text(
        'Carnet: ${alumno.carnet}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}

class _OpcionAsistencia extends StatelessWidget {
  const _OpcionAsistencia({
    required this.controller,
    required this.alumno,
    required this.opcion,
    this.compacta = false,
  });
  final AsistenciaController controller;
  final AlumnoInscrito alumno;
  final EstadoAsistencia? opcion;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final seleccionada = c.estados[alumno.inscripcionId] == opcion;
    final (color, icono) = switch ((opcion, seleccionada)) {
      (EstadoAsistencia.presente, true) => (
        AppColors.success,
        Icons.check_circle,
      ),
      (EstadoAsistencia.ausente, true) => (AppColors.error, Icons.cancel),
      (null, true) => (AppColors.navy, Icons.radio_button_checked),
      _ => (AppColors.textSecondary, Icons.radio_button_unchecked),
    };
    final fondo = seleccionada && opcion != null
        ? color.withValues(alpha: 0.12)
        : null;
    final texto = Text(
      _etiqueta(opcion),
      textAlign: TextAlign.center,
      style: (compacta ? AppTextStyles.bodySmall : AppTextStyles.body).copyWith(
        color: seleccionada ? AppColors.navy : AppColors.textSecondary,
        fontWeight: seleccionada ? FontWeight.w600 : null,
      ),
    );
    final contenido = compacta
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: color, size: AppSizes.iconSmall),
              const SizedBox(height: AppSizes.space4),
              texto,
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: color, size: AppSizes.iconSmall),
              const SizedBox(width: AppSizes.space8),
              Flexible(child: texto),
            ],
          );
    return Semantics(
      key: ValueKey(
        'asistencia-${alumno.inscripcionId}-${opcion?.name ?? 'sin'}',
      ),
      button: true,
      selected: seleccionada,
      label: '${alumno.nombre}: ${_etiqueta(opcion)}',
      excludeSemantics: true,
      child: Material(
        color: fondo ?? Colors.transparent,
        shape: compacta
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius),
                side: BorderSide(
                  color: fondo == null ? AppColors.border : color,
                ),
              )
            : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: c.guardando
              ? null
              : () => c.marcar(alumno.inscripcionId, opcion),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space8,
              vertical: AppSizes.space12,
            ),
            child: contenido,
          ),
        ),
      ),
    );
  }
}
