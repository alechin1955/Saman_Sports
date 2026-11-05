import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/views/admin/cancha_form_dialog.dart';
import 'package:saman_sports/views/admin/deporte_form_dialog.dart';
import 'package:saman_sports/views/widgets/boton_primario.dart';
import 'package:saman_sports/views/widgets/campo_texto.dart';

class DeportesAdminView extends StatefulWidget {
  const DeportesAdminView({
    super.key,
    required this.deportes,
    required this.entrenadores,
  });

  final AdminDeporteController deportes;
  final AdminEntrenadorController entrenadores;

  @override
  State<DeportesAdminView> createState() => _DeportesAdminViewState();
}

class _DeportesAdminViewState extends State<DeportesAdminView> {
  var _canchas = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.deportes,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSizes.space8,
              children: [
                ChoiceChip(
                  label: Text(AppStrings.deportes),
                  selected: !_canchas,
                  onSelected: (_) => setState(() => _canchas = false),
                ),
                ChoiceChip(
                  label: Text(AppStrings.adminCanchas),
                  selected: _canchas,
                  onSelected: (_) => setState(() => _canchas = true),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            if (_canchas)
              _Canchas(deportes: widget.deportes)
            else
              _Deportes(
                deportes: widget.deportes,
                entrenadores: widget.entrenadores,
              ),
          ],
        );
      },
    );
  }
}

class _Deportes extends StatelessWidget {
  const _Deportes({required this.deportes, required this.entrenadores});

  final AdminDeporteController deportes;
  final AdminEntrenadorController entrenadores;

  @override
  Widget build(BuildContext context) {
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
                onFieldSubmitted: deportes.buscar,
              ),
            ),
            for (final filtro in FiltroDeporte.values)
              ChoiceChip(
                label: Text(_filtro(filtro)),
                selected: deportes.filtro == filtro,
                onSelected: (_) => deportes.cambiarFiltro(filtro),
              ),
            BotonPrimario(
              texto: AppStrings.adminNuevoDeporte,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => DeporteFormDialog(
                  deportes: deportes,
                  entrenadores: entrenadores,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.space16),
        if (deportes.error != null)
          Text(
            deportes.error!,
            style: AppTextStyles.body.copyWith(color: AppColors.error),
          ),
        if (movil)
          for (final deporte in deportes.deportesFiltrados)
            _TarjetaDeporte(
              deporte: deporte,
              deportes: deportes,
              entrenadores: entrenadores,
            )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(AppStrings.deportes)),
                DataColumn(label: Text(AppStrings.entrenador)),
                DataColumn(label: Text(AppStrings.adminCancha)),
                DataColumn(label: Text(AppStrings.horario)),
                DataColumn(label: Text(AppStrings.adminInscritos)),
                DataColumn(label: Text(AppStrings.adminDisponibles)),
                DataColumn(label: Text(AppStrings.adminEstado)),
                DataColumn(label: Text(AppStrings.editar)),
              ],
              rows: [
                for (final deporte in deportes.deportesFiltrados)
                  DataRow(
                    cells: [
                      DataCell(Text(deporte.nombre)),
                      DataCell(Text(deporte.entrenadorNombre)),
                      DataCell(Text(deporte.canchaNombre)),
                      DataCell(Text(deporte.horario)),
                      DataCell(Text('${deporte.inscritos}')),
                      DataCell(Text('${deporte.disponibles}')),
                      DataCell(Text(_estado(deporte))),
                      DataCell(
                        _AccionesDeporte(
                          deporte: deporte,
                          deportes: deportes,
                          entrenadores: entrenadores,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AccionesDeporte extends StatelessWidget {
  const _AccionesDeporte({
    required this.deporte,
    required this.deportes,
    required this.entrenadores,
  });

  final Deporte deporte;
  final AdminDeporteController deportes;
  final AdminEntrenadorController entrenadores;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.space8,
      children: [
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => DeporteFormDialog(
              deportes: deportes,
              entrenadores: entrenadores,
              deporte: deporte,
            ),
          ),
          child: Text(AppStrings.editar),
        ),
        TextButton(
          onPressed: () => _asignar(context),
          child: Text(AppStrings.adminAsignarEntrenador),
        ),
        TextButton(
          onPressed: () => _cambiarEstado(context),
          child: Text(
            deporte.activo
                ? AppStrings.adminDesactivar
                : AppStrings.adminReactivar,
          ),
        ),
      ],
    );
  }

  Future<void> _asignar(BuildContext context) async {
    String? uid;
    final elegido = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.adminAsignarEntrenador),
          content: DropdownButtonFormField<String?>(
            initialValue: null,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(AppStrings.adminSinAsignar),
              ),
              for (final item in entrenadores.entrenadoresActivos)
                DropdownMenuItem(
                  value: item.uid,
                  child: Text(item.nombreCompleto),
                ),
            ],
            onChanged: (valor) => uid = valor,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.cancelar),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.guardar),
            ),
          ],
        );
      },
    );
    if (elegido != true) return;
    await deportes.asignarEntrenador(
      deporte,
      uid == null
          ? null
          : entrenadores.entrenadoresActivos.firstWhere(
              (item) => item.uid == uid,
            ),
    );
  }

  Future<void> _cambiarEstado(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.adminConfirmarDesactivar),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              deporte.activo
                  ? AppStrings.adminDesactivar
                  : AppStrings.adminReactivar,
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await deportes.cambiarEstadoDeporte(deporte, !deporte.activo);
  }
}

class _TarjetaDeporte extends StatelessWidget {
  const _TarjetaDeporte({
    required this.deporte,
    required this.deportes,
    required this.entrenadores,
  });

  final Deporte deporte;
  final AdminDeporteController deportes;
  final AdminEntrenadorController entrenadores;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(deporte.nombre),
        subtitle: Text('${deporte.horario}\n${_estado(deporte)}'),
        isThreeLine: true,
        trailing: _AccionesDeporte(
          deporte: deporte,
          deportes: deportes,
          entrenadores: entrenadores,
        ),
      ),
    );
  }
}

class _Canchas extends StatelessWidget {
  const _Canchas({required this.deportes});

  final AdminDeporteController deportes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BotonPrimario(
          texto: AppStrings.adminNuevaCancha,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => CanchaFormDialog(deportes: deportes),
          ),
        ),
        const SizedBox(height: AppSizes.space12),
        for (final cancha in deportes.canchas)
          ListTile(
            title: Text(cancha.nombre),
            subtitle: Text(
              '${cancha.ubicacion} · ${cancha.activa ? AppStrings.adminActivo : AppStrings.adminInactivo}',
            ),
            trailing: Wrap(
              children: [
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        CanchaFormDialog(deportes: deportes, cancha: cancha),
                  ),
                  child: Text(AppStrings.editar),
                ),
                TextButton(
                  onPressed: () =>
                      deportes.cambiarEstadoCancha(cancha, !cancha.activa),
                  child: Text(
                    cancha.activa
                        ? AppStrings.adminDesactivar
                        : AppStrings.adminReactivar,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _filtro(FiltroDeporte filtro) {
  return switch (filtro) {
    FiltroDeporte.todos => AppStrings.adminTodos,
    FiltroDeporte.activos => AppStrings.adminActivos,
    FiltroDeporte.inactivos => AppStrings.adminInactivos,
  };
}

String _estado(Deporte deporte) {
  if (!deporte.activo) return AppStrings.adminInactivo;
  return switch (deporte.estadoCupos) {
    EstadoCupos.disponible => AppStrings.adminDisponible,
    EstadoCupos.pocosCupos => AppStrings.adminLimitado,
    EstadoCupos.completo => AppStrings.adminCompleto,
  };
}
