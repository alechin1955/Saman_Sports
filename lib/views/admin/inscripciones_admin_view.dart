import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_inscripcion_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/inscripcion.dart';

class InscripcionesAdminView extends StatelessWidget {
  const InscripcionesAdminView({super.key, required this.inscripciones});

  final AdminInscripcionController inscripciones;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: inscripciones,
      builder: (context, _) {
        final movil = MediaQuery.sizeOf(context).width < AppSizes.mobile;
        final lista = inscripciones.inscripcionesFiltradas;
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
                    label: Text(_estado(estado)),
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
                        Text(item.estudianteUid, style: AppTextStyles.subtitle),
                        Text(item.deporteNombre),
                        Text('${_fecha(item.fecha)} · ${_estado(item.estado)}'),
                        Text(item.pagoId ?? AppStrings.adminSinDato),
                        _Acciones(item: item, panel: inscripciones),
                      ],
                    ),
                  ),
                )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
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
                          DataCell(Text(item.estudianteUid)),
                          DataCell(Text(item.deporteNombre)),
                          DataCell(Text(_fecha(item.fecha))),
                          DataCell(Text(_estado(item.estado))),
                          DataCell(
                            Text(item.pagoId ?? AppStrings.adminSinDato),
                          ),
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

class _Acciones extends StatelessWidget {
  const _Acciones({required this.item, required this.panel});

  final Inscripcion item;
  final AdminInscripcionController panel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.space8,
      children: [
        if (item.estado == EstadoInscripcion.pendiente)
          TextButton(
            onPressed: () =>
                panel.cambiarEstado(item, EstadoInscripcion.confirmada.name),
            child: Text(AppStrings.adminConfirmar),
          ),
        if (item.estado != EstadoInscripcion.cancelada)
          TextButton(
            onPressed: () =>
                panel.cambiarEstado(item, EstadoInscripcion.cancelada.name),
            child: Text(AppStrings.cancelar),
          ),
        if (item.estado == EstadoInscripcion.cancelada)
          TextButton(
            onPressed: () =>
                panel.cambiarEstado(item, EstadoInscripcion.pendiente.name),
            child: Text(AppStrings.adminReactivar),
          ),
      ],
    );
  }
}

String _estado(EstadoInscripcion estado) {
  return switch (estado) {
    EstadoInscripcion.pendiente => AppStrings.adminPendientes,
    EstadoInscripcion.confirmada => AppStrings.adminConfirmadas,
    EstadoInscripcion.cancelada => AppStrings.adminCancelados,
  };
}

String _fecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}
