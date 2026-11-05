import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';

class EstudiantesAdminView extends StatefulWidget {
  const EstudiantesAdminView({super.key, required this.estudiantes});

  final AdminEstudianteController estudiantes;

  @override
  State<EstudiantesAdminView> createState() => _EstudiantesAdminViewState();
}

class _EstudiantesAdminViewState extends State<EstudiantesAdminView> {
  late final TextEditingController _busqueda;

  @override
  void initState() {
    super.initState();
    _busqueda = TextEditingController();
    _busqueda.addListener(() => widget.estudiantes.buscar(_busqueda.text));
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.estudiantes,
      builder: (context, _) {
        final panel = widget.estudiantes;
        final movil = MediaQuery.sizeOf(context).width < AppSizes.mobile;
        final lista = panel.estudiantesFiltrados;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSizes.space8,
              runSpacing: AppSizes.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: CampoTexto(
                    label: AppStrings.buscarDeportesHint,
                    controller: _busqueda,
                  ),
                ),
                for (final filtro in FiltroEstudiante.values)
                  ChoiceChip(
                    label: Text(_filtro(filtro)),
                    selected: panel.filtro == filtro,
                    onSelected: (_) => panel.cambiarFiltro(filtro),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (panel.error != null)
              Text(
                panel.error!,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            if (panel.cargando && lista.isEmpty)
              const CircularProgressIndicator()
            else if (lista.isEmpty)
              Text(AppStrings.adminSinEstudiantes, style: AppTextStyles.body)
            else if (movil)
              for (final item in lista)
                _Tarjeta(
                  estudiante: item,
                  onDetalle: () => _detalle(context, item),
                  onEstado: () => _estado(context, item),
                )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(AppStrings.nombre)),
                    DataColumn(label: Text(AppStrings.adminCarnet)),
                    DataColumn(label: Text(AppStrings.correoInstitucional)),
                    DataColumn(label: Text(AppStrings.telefono)),
                    DataColumn(label: Text(AppStrings.solvente)),
                    DataColumn(label: Text(AppStrings.adminEstado)),
                    DataColumn(label: Text(AppStrings.editar)),
                  ],
                  rows: [
                    for (final item in lista)
                      DataRow(
                        cells: [
                          DataCell(Text(item.nombreCompleto)),
                          DataCell(Text(item.carnet)),
                          DataCell(Text(item.correo)),
                          DataCell(Text(item.telefono)),
                          DataCell(_Solvencia(solvente: item.solvente)),
                          DataCell(Text(_activo(item.activo))),
                          DataCell(
                            _Acciones(
                              estudiante: item,
                              onDetalle: () => _detalle(context, item),
                              onEstado: () => _estado(context, item),
                            ),
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

  Future<void> _detalle(BuildContext context, Estudiante item) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.adminVerDetalle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.nombreCompleto),
            Text('${AppStrings.cedula}: ${item.cedula}'),
            Text('${AppStrings.adminCarnet}: ${item.carnet}'),
            Text('${AppStrings.correoInstitucional}: ${item.correo}'),
            Text('${AppStrings.telefono}: ${item.telefono}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancelar),
          ),
        ],
      ),
    );
  }

  Future<void> _estado(BuildContext context, Estudiante item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          item.activo
              ? AppStrings.adminConfirmarDesactivar
              : AppStrings.adminConfirmarActivar,
        ),
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
                  : AppStrings.adminActivar,
            ),
          ),
        ],
      ),
    );
    if (ok == true) await widget.estudiantes.cambiarEstado(item, !item.activo);
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.estudiante,
    required this.onDetalle,
    required this.onEstado,
  });

  final Estudiante estudiante;
  final VoidCallback onDetalle;
  final VoidCallback onEstado;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(estudiante.nombreCompleto, style: AppTextStyles.subtitle),
            Text(estudiante.carnet),
            Text(estudiante.correo),
            Text(estudiante.telefono),
            const SizedBox(height: AppSizes.space8),
            _Solvencia(solvente: estudiante.solvente),
            Text(_activo(estudiante.activo)),
            _Acciones(
              estudiante: estudiante,
              onDetalle: onDetalle,
              onEstado: onEstado,
            ),
          ],
        ),
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  const _Acciones({
    required this.estudiante,
    required this.onDetalle,
    required this.onEstado,
  });

  final Estudiante estudiante;
  final VoidCallback onDetalle;
  final VoidCallback onEstado;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.space8,
      children: [
        TextButton(
          onPressed: onDetalle,
          child: Text(AppStrings.adminVerDetalle),
        ),
        TextButton(
          onPressed: onEstado,
          child: Text(
            estudiante.activo
                ? AppStrings.adminDesactivar
                : AppStrings.adminActivar,
          ),
        ),
      ],
    );
  }
}

class _Solvencia extends StatelessWidget {
  const _Solvencia({required this.solvente});

  final bool solvente;

  @override
  Widget build(BuildContext context) {
    final color = solvente ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space8,
        vertical: AppSizes.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Text(
        solvente ? AppStrings.solvente : AppStrings.noSolvente,
        style: AppTextStyles.bodySmall.copyWith(color: color),
      ),
    );
  }
}

String _filtro(FiltroEstudiante filtro) {
  return switch (filtro) {
    FiltroEstudiante.todos => AppStrings.adminTodos,
    FiltroEstudiante.activos => AppStrings.adminActivos,
    FiltroEstudiante.inactivos => AppStrings.adminInactivos,
    FiltroEstudiante.solventes => AppStrings.adminSolventes,
    FiltroEstudiante.pendientes => AppStrings.adminPendientes,
  };
}

String _activo(bool activo) {
  return activo ? AppStrings.adminActivo : AppStrings.adminInactivo;
}
