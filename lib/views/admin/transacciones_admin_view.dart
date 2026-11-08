import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_transaccion_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/transaccion.dart';
import 'package:saman_sports/views/widgets/boton_secundario.dart';

class TransaccionesAdminView extends StatelessWidget {
  const TransaccionesAdminView({super.key, required this.transacciones});

  final AdminTransaccionController transacciones;

  static const _roles = ['estudiante', 'entrenador', 'administrador'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: transacciones,
      builder: (context, _) {
        final movil = MediaQuery.sizeOf(context).width < AppSizes.mobile;
        final lista = transacciones.transaccionesFiltradas;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSizes.space8,
              runSpacing: AppSizes.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => _fecha(context, true),
                  child: Text(
                    transacciones.desde == null
                        ? AppStrings.adminDesde
                        : _dia(transacciones.desde!),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _fecha(context, false),
                  child: Text(
                    transacciones.hasta == null
                        ? AppStrings.adminHasta
                        : _dia(transacciones.hasta!),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('modulo-${transacciones.modulo}'),
                    initialValue: transacciones.modulo,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.adminModulo,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.adminTodos),
                      ),
                      for (final modulo in AdminTransaccionController.modulos)
                        DropdownMenuItem(value: modulo, child: Text(modulo)),
                    ],
                    onChanged: (valor) => transacciones.filtrar(
                      desde: transacciones.desde,
                      hasta: transacciones.hasta,
                      modulo: valor,
                      rol: transacciones.rol,
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('rol-${transacciones.rol}'),
                    initialValue: transacciones.rol,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: AppStrings.adminRol),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(AppStrings.adminTodos),
                      ),
                      for (final rol in _roles)
                        DropdownMenuItem(value: rol, child: Text(_rol(rol))),
                    ],
                    onChanged: (valor) => transacciones.filtrar(
                      desde: transacciones.desde,
                      hasta: transacciones.hasta,
                      modulo: transacciones.modulo,
                      rol: valor,
                    ),
                  ),
                ),
                BotonSecundario(
                  texto: AppStrings.adminLimpiar,
                  onPressed: transacciones.limpiarFiltros,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (transacciones.error != null)
              Text(
                transacciones.error!,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            if (transacciones.cargando && lista.isEmpty)
              const CircularProgressIndicator()
            else if (lista.isEmpty)
              Text(AppStrings.adminSinTransacciones, style: AppTextStyles.body)
            else if (movil)
              for (final item in lista) _Tarjeta(item: item)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(AppStrings.adminFecha)),
                    DataColumn(label: Text(AppStrings.adminUsuario)),
                    DataColumn(label: Text(AppStrings.adminRol)),
                    DataColumn(label: Text(AppStrings.adminModulo)),
                    DataColumn(label: Text(AppStrings.adminAccion)),
                    DataColumn(label: Text(AppStrings.adminDescripcion)),
                  ],
                  rows: [
                    for (final item in lista)
                      DataRow(
                        cells: [
                          DataCell(Text(_diaHora(item.fecha))),
                          DataCell(Text(item.usuarioNombre)),
                          DataCell(Text(_rol(item.rol))),
                          DataCell(Text(item.modulo)),
                          DataCell(Text(item.accion)),
                          DataCell(Text(item.descripcion)),
                        ],
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSizes.space12),
            Text(AppStrings.adminUltimas200, style: AppTextStyles.bodySmall),
          ],
        );
      },
    );
  }

  Future<void> _fecha(BuildContext context, bool desde) async {
    final actual = desde ? transacciones.desde : transacciones.hasta;
    final elegida = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: actual ?? DateTime.now(),
    );
    if (elegida == null) return;
    transacciones.filtrar(
      desde: desde ? elegida : transacciones.desde,
      hasta: desde ? transacciones.hasta : elegida,
      modulo: transacciones.modulo,
      rol: transacciones.rol,
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.item});

  final Transaccion item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(item.accion),
        subtitle: Text(
          '${_diaHora(item.fecha)}\n${item.usuarioNombre} · ${_rol(item.rol)} · ${item.modulo}\n${item.descripcion}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

String _rol(String rol) {
  return switch (rol) {
    'estudiante' => AppStrings.adminRolEstudiante,
    'entrenador' => AppStrings.adminRolEntrenador,
    'administrador' => AppStrings.adminRolAdministrador,
    _ => rol,
  };
}

String _dia(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

String _diaHora(DateTime fecha) {
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '${_dia(fecha)} $hora:$minuto';
}
