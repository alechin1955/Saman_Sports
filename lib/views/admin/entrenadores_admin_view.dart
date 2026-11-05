import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/models/entrenador_admin.dart';
import 'package:saman_sports/views/admin/entrenador_form_dialog.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';

class EntrenadoresAdminView extends StatelessWidget {
  const EntrenadoresAdminView({
    super.key,
    required this.entrenadores,
    required this.deportes,
  });

  final AdminEntrenadorController entrenadores;
  final AdminDeporteController deportes;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([entrenadores, deportes]),
      builder: (context, _) {
        final movil = MediaQuery.sizeOf(context).width < AppSizes.mobile;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSizes.space8,
              runSpacing: AppSizes.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: CampoTexto(
                    label: AppStrings.buscarDeportesHint,
                    onFieldSubmitted: entrenadores.buscar,
                  ),
                ),
                for (final filtro in FiltroEntrenador.values)
                  ChoiceChip(
                    label: Text(_filtro(filtro)),
                    selected: entrenadores.filtro == filtro,
                    onSelected: (_) => entrenadores.cambiarFiltro(filtro),
                  ),
                BotonPrimario(
                  texto: AppStrings.adminNuevoEntrenador,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        EntrenadorFormDialog(entrenadores: entrenadores),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (movil)
              for (final item in entrenadores.entrenadoresFiltrados)
                ListTile(
                  title: Text(item.nombreCompleto),
                  subtitle: Text(item.correo),
                  trailing: _Acciones(item: item, entrenadores: entrenadores),
                )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(AppStrings.nombre)),
                    DataColumn(label: Text(AppStrings.adminEspecialidad)),
                    DataColumn(label: Text(AppStrings.adminExperiencia)),
                    DataColumn(label: Text(AppStrings.adminDisciplina)),
                    DataColumn(label: Text(AppStrings.adminDeportesAsignados)),
                    DataColumn(label: Text(AppStrings.correoInstitucional)),
                    DataColumn(label: Text(AppStrings.adminEstado)),
                    DataColumn(label: Text(AppStrings.editar)),
                  ],
                  rows: [
                    for (final item in entrenadores.entrenadoresFiltrados)
                      DataRow(
                        cells: [
                          DataCell(Text(item.nombreCompleto)),
                          DataCell(Text(item.especialidad)),
                          DataCell(
                            Text(
                              '${item.anosExperiencia} ${AppStrings.adminAnos}',
                            ),
                          ),
                          DataCell(Text(item.disciplina)),
                          DataCell(Text('${_asignados(item, deportes)}')),
                          DataCell(Text(item.correo)),
                          DataCell(
                            Text(
                              item.activo
                                  ? AppStrings.adminActivo
                                  : AppStrings.adminInactivo,
                            ),
                          ),
                          DataCell(
                            _Acciones(item: item, entrenadores: entrenadores),
                          ),
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
  const _Acciones({required this.item, required this.entrenadores});

  final EntrenadorAdmin item;
  final AdminEntrenadorController entrenadores;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => EntrenadorFormDialog(
              entrenadores: entrenadores,
              entrenador: item,
            ),
          ),
          child: Text(AppStrings.editar),
        ),
        TextButton(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                content: Text(AppStrings.adminNoEliminaEntrenador),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppStrings.cancelar),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      item.activo
                          ? AppStrings.adminDesactivar
                          : AppStrings.adminReactivar,
                    ),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await entrenadores.cambiarEstado(item, !item.activo);
            }
          },
          child: Text(
            item.activo
                ? AppStrings.adminDesactivar
                : AppStrings.adminReactivar,
          ),
        ),
      ],
    );
  }
}

int _asignados(EntrenadorAdmin item, AdminDeporteController deportes) {
  return deportes.deportes
      .where((deporte) => deporte.entrenadorUid == item.uid)
      .length;
}

String _filtro(FiltroEntrenador filtro) {
  return switch (filtro) {
    FiltroEntrenador.todos => AppStrings.adminTodos,
    FiltroEntrenador.activos => AppStrings.adminActivos,
    FiltroEntrenador.inactivos => AppStrings.adminInactivos,
  };
}
