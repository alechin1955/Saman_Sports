import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/controllers/entrenador_panel_bridge.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/core/theme/app_colors.dart';
import 'package:saman_sports/core/theme/app_sizes.dart';
import 'package:saman_sports/core/theme/app_text_styles.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';
import 'package:saman_sports/views/entrenador/widgets/boton_exportar_asistencia.dart';
import 'package:saman_sports/views/entrenador/widgets/registro_asistencia.dart';
import 'package:saman_sports/views/estudiante/widgets/estado_vacio.dart';
import 'package:saman_sports/views/widgets/mensaje_error.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

class AsistenciaEntrenadorView extends StatefulWidget {
  const AsistenciaEntrenadorView({
    super.key,
    required this.auth,
    this.deporteInicialId,
    this.controller,
    this.asistencia,
  });

  final AuthController auth;
  final String? deporteInicialId;
  final EntrenadorController? controller;
  final AsistenciaController? asistencia;

  @override
  State<AsistenciaEntrenadorView> createState() =>
      _AsistenciaEntrenadorViewState();
}

class _AsistenciaEntrenadorViewState extends State<AsistenciaEntrenadorView> {
  late final EntrenadorPanelBridge panel = EntrenadorPanelBridge(
    entrenador: widget.controller,
    asistencia: widget.asistencia,
  );
  int _revisionSelector = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        panel.cargar(seleccionInicialId: widget.deporteInicialId);
      }
    });
  }

  @override
  void dispose() {
    panel.dispose();
    super.dispose();
  }

  Future<bool> _permitirSalida() async {
    if (panel.asistencia.guardando) return false;
    if (!panel.asistencia.cambios) return true;
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tienes asistencia sin guardar'),
        content: const Text(
          'Puedes continuar editando o salir y descartar los cambios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar y salir'),
          ),
        ],
      ),
    );
    if (salir == true) panel.descartarBorrador();
    return salir == true;
  }

  Future<void> _cambiarDisciplina(String? id) async {
    if (id == null || id == panel.entrenador.seleccionId) return;
    if (!await _permitirSalida()) {
      if (mounted) setState(() => _revisionSelector++);
      return;
    }
    await panel.entrenador.seleccionar(id);
  }

  Future<void> _cambiarFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: panel.asistencia.fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (elegida == null || !mounted) return;
    if (!await _permitirSalida()) return;
    final id = panel.entrenador.seleccionId;
    if (id == null) return;
    await panel.asistencia.abrir(
      id,
      elegida,
      panel.entrenador.alumnos,
      descartar: true,
    );
  }

  Future<void> _volverADisciplinas() async {
    if (!await _permitirSalida() || !mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.entrenadorDisciplinas);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: panel,
      builder: (context, _) => PopScope(
        canPop: !panel.bloqueaSalida,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (await _permitirSalida()) {
            await WidgetsBinding.instance.endOfFrame;
            if (context.mounted) Navigator.maybePop(context);
          }
        },
        child: PanelLayout(
          permitirSalida: _permitirSalida,
          auth: widget.auth,
          opciones: OpcionesEntrenador.menu,
          rutaActiva: AppRoutes.entrenadorAsistencia,
          subtituloPanel: 'Panel del entrenador',
          titulo: 'Asistencia',
          descripcion: 'Selecciona una disciplina y una fecha para pasar lista o exportar el historial.',
          child: _contenido(),
        ),
      ),
    );
  }

  Widget _contenido() {
    final entrenador = panel.entrenador;
    final asistencia = panel.asistencia;
    if (entrenador.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (entrenador.error != null && entrenador.disciplinas.isEmpty) {
      return MensajeError(texto: entrenador.error!);
    }
    if (entrenador.disciplinas.isEmpty) {
      return EstadoVacio(
        icono: Icons.fact_check_outlined,
        titulo: 'No hay una disciplina para registrar',
        texto: 'Primero necesitas una disciplina activa asignada.',
        textoAccion: 'Volver a disciplinas',
        onAccion: _volverADisciplinas,
      );
    }
    final seleccionada = entrenador.disciplinas
        .where((item) => item.id == entrenador.seleccionId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.space16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            spacing: AppSizes.space16,
            runSpacing: AppSizes.space12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('${entrenador.seleccionId}-$_revisionSelector'),
                  initialValue: entrenador.seleccionId,
                  decoration: const InputDecoration(
                    labelText: 'Disciplina',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final disciplina in entrenador.disciplinas)
                      DropdownMenuItem(
                        value: disciplina.id,
                        child: Text(disciplina.nombre),
                      ),
                  ],
                  onChanged: entrenador.cargandoNomina
                      ? null
                      : _cambiarDisciplina,
                ),
              ),
              OutlinedButton.icon(
                onPressed: entrenador.cargandoNomina ? null : _cambiarFecha,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_fecha(asistencia.fecha)),
              ),
              TextButton.icon(
                onPressed: _volverADisciplinas,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver a disciplinas'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.space24),
        if (entrenador.cargandoNomina || asistencia.cargando)
          const Center(child: CircularProgressIndicator())
        else if (entrenador.error != null)
          MensajeError(texto: entrenador.error!)
        else if (entrenador.alumnos.isEmpty)
          const EstadoVacio(
            icono: Icons.groups_outlined,
            titulo: 'No hay estudiantes confirmados',
            texto:
                'La lista aparecerá cuando existan inscripciones confirmadas.',
          )
        else ...[
          Text(
            '${seleccionada?.nombre ?? ''} · ${entrenador.alumnos.length} estudiantes',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: AppSizes.space16),
          RegistroAsistencia(controller: asistencia),
          const SizedBox(height: AppSizes.space16),
          BotonExportarAsistencia(
            controller: asistencia,
            disciplina: seleccionada?.nombre ?? 'disciplina',
          ),
        ],
      ],
    );
  }

  String _fecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}
