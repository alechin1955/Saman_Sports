import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_estudiante_controller.dart';
import 'package:saman_sports/controllers/admin/admin_inscripcion_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/inscripcion.dart';
import 'package:saman_sports/views/admin/widgets/tabla_desplazable.dart';

class InscripcionesAdminView extends StatelessWidget {
  const InscripcionesAdminView({
    super.key,
    required this.inscripciones,
    required this.estudiantes,
  });

  final AdminInscripcionController inscripciones;
  final AdminEstudianteController estudiantes;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([inscripciones, estudiantes]),
      builder: (context, _) {
        final movil = MediaQuery.sizeOf(context).width < AppSizes.mobile;
        final lista = inscripciones.inscripcionesFiltradas;
        final nombresEstudiantes = {
          for (final estudiante in estudiantes.estudiantes)
            estudiante.uid: estudiante.nombreCompleto,
        };
        final deportes = <String, String>{
          for (final item in inscripciones.inscripciones)
            item.deporteId: item.deporteNombre,
        };
        final deporte = deportes.containsKey(inscripciones.filtroDeporte)
            ? inscripciones.filtroDeporte
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSizes.space8,
              runSpacing: AppSizes.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(AppStrings.adminTodos),
                  selected: inscripciones.filtroEstado == null,
                  onSelected: (_) => inscripciones.filtrar(
                    deporteId: inscripciones.filtroDeporte,
                  ),
                ),
                for (final estado in EstadoInscripcion.values)
                  ChoiceChip(
                    label: Text(_estadoFiltro(estado)),
                    selected: inscripciones.filtroEstado == estado,
                    onSelected: (_) => inscripciones.filtrar(
                      estado: estado,
                      deporteId: inscripciones.filtroDeporte,
                    ),
                  ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('deporte-$deporte'),
                    initialValue: deporte,
                    decoration: InputDecoration(labelText: AppStrings.deportes),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.adminTodos),
                      ),
                      for (final item in deportes.entries)
                        DropdownMenuItem(
                          value: item.key,
                          child: Text(item.value),
                        ),
                    ],
                    onChanged: (valor) => inscripciones.filtrar(
                      estado: inscripciones.filtroEstado,
                      deporteId: valor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (inscripciones.error != null)
              Text(
                inscripciones.error!,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            if (inscripciones.cargando && lista.isEmpty)
              const CircularProgressIndicator()
            else if (lista.isEmpty)
              Text(AppStrings.adminSinInscripciones, style: AppTextStyles.body)
            else if (movil)
              for (final item in lista)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.space12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nombreEstudiante(item, nombresEstudiantes),
                          style: AppTextStyles.subtitle,
                        ),
                        Text(item.deporteNombre),
                        Text('${_fecha(item.fecha)} · ${_estadoFila(item.estado)}'),
                        Text(_pago(item.pagoId)),
                        _Acciones(item: item, panel: inscripciones),
                      ],
                    ),
                  ),
                )
            else
              TablaDesplazable(
                child: DataTable(
                  horizontalMargin: AppSizes.space16,
                  columnSpacing: AppSizes.space24,
                  dataRowMinHeight: AppSizes.space48,
                  dataRowMaxHeight: AppSizes.space48,
                  columns: [
                    DataColumn(label: Text(AppStrings.adminEstudiante)),
                    DataColumn(label: Text(AppStrings.deportes)),
                    DataColumn(label: Text(AppStrings.adminFecha)),
                    DataColumn(label: Text(AppStrings.adminEstado)),
                    DataColumn(label: Text(AppStrings.adminPago)),
                    DataColumn(label: Text(AppStrings.editar)),
                  ],
                  rows: [
                    for (final item in lista)
                      DataRow(
                        cells: [
                          DataCell(_nombreCelda(item, nombresEstudiantes)),
                          DataCell(Text(item.deporteNombre)),
                          DataCell(Text(_fecha(item.fecha))),
                          DataCell(Text(_estadoFila(item.estado))),
                          DataCell(Text(_pago(item.pagoId))),
                          DataCell(_Acciones(item: item, panel: inscripciones)),
                        ],
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

String _nombreEstudiante(Inscripcion inscripcion, Map<String, String> nombres) {
  final nombre = nombres[inscripcion.estudianteUid]?.trim();
  return nombre == null || nombre.isEmpty
      ? AppStrings.adminEstudianteSinNombre
      : nombre;
}

Widget _nombreCelda(Inscripcion inscripcion, Map<String, String> nombres) {
  final nombre = _nombreEstudiante(inscripcion, nombres);
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppSizes.columnaNombreTabla),
    child: Tooltip(
      message: nombre,
      child: Text(nombre, overflow: TextOverflow.ellipsis),
    ),
  );
}

String _pago(String? pagoId) {
  return pagoId == null || pagoId.trim().isEmpty
      ? AppStrings.adminSinDato
      : AppStrings.adminPagoRegistrado;
}

class _Acciones extends StatelessWidget {
  const _Acciones({required this.item, required this.panel});

  final Inscripcion item;
  final AdminInscripcionController panel;

  @override
  Widget build(BuildContext context) {
    final botones = <Widget>[
      if (item.estado == EstadoInscripcion.pendiente)
        _boton(
          AppStrings.adminConfirmar,
          AppColors.success,
          () => panel.cambiarEstado(item, EstadoInscripcion.confirmada.name),
        ),
      if (item.estado != EstadoInscripcion.cancelada)
        _boton(
          AppStrings.cancelar,
          AppColors.error,
          () => panel.cambiarEstado(item, EstadoInscripcion.cancelada.name),
        ),
      if (item.estado == EstadoInscripcion.cancelada)
        _boton(
          AppStrings.adminReactivar,
          null,
          () => panel.cambiarEstado(item, EstadoInscripcion.pendiente.name),
        ),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSizes.columnaAccionesInscripcion,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < botones.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSizes.space8),
              botones[i],
            ],
          ],
        ),
      ),
    );
  }
}

Widget _boton(String texto, Color? color, VoidCallback onPressed) {
  return TextButton(
    style: TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space8),
      minimumSize: const Size(0, AppSizes.botonTablaAlto),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: color,
    ),
    onPressed: onPressed,
    child: Text(texto),
  );
}

String _estadoFiltro(EstadoInscripcion estado) {
  return switch (estado) {
    EstadoInscripcion.pendiente => AppStrings.adminPendientes,
    EstadoInscripcion.confirmada => AppStrings.adminConfirmadas,
    EstadoInscripcion.cancelada => AppStrings.adminCancelados,
  };
}

String _estadoFila(EstadoInscripcion estado) {
  return switch (estado) {
    EstadoInscripcion.pendiente => AppStrings.estadoPendiente,
    EstadoInscripcion.confirmada => AppStrings.estadoConfirmada,
    EstadoInscripcion.cancelada => AppStrings.estadoCancelada,
  };
}

String _fecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}
