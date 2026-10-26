import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/repositories/historial_asistencia_repository.dart';
import 'package:saman_sports/services/exportacion/csv_asistencia.dart';
import 'package:saman_sports/services/exportacion/descarga.dart';

class BotonExportarAsistencia extends StatefulWidget {
  const BotonExportarAsistencia({
    super.key,
    required this.controller,
    required this.disciplina,
    this.repository,
    this.entregar,
  });
  final AsistenciaController controller;
  final String disciplina;
  final HistorialAsistenciaRepository? repository;
  final Future<void> Function(String nombre, String contenido)? entregar;
  @override
  State<BotonExportarAsistencia> createState() =>
      _BotonExportarAsistenciaState();
}

class _BotonExportarAsistenciaState extends State<BotonExportarAsistencia> {
  bool _exportando = false;
  String? _mensaje;

  Future<void> _exportar() async {
    final c = widget.controller;
    if (_exportando ||
        c.deporteId == null ||
        c.cambios ||
        c.guardando ||
        c.cargando ||
        c.error != null) {
      return;
    }
    final id = c.deporteId!;
    final fecha = c.fecha;
    final alumnos = List<AlumnoInscrito>.of(c.alumnos);
    final disciplina = widget.disciplina;
    setState(() {
      _exportando = true;
      _mensaje = null;
    });
    try {
      final sesiones =
          await (widget.repository ?? FirestoreHistorialAsistenciaRepository())
              .sesiones(id)
              .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      final csv = generarCsvAsistencia(
        disciplina: disciplina,
        fecha: fecha,
        alumnos: alumnos,
        sesiones: sesiones,
      );
      final idSeguro = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await (widget.entregar ?? entregarCsv)(
        'asistencia_${idSeguro}_${claveFecha(fecha)}.csv',
        csv,
      );
      if (!mounted) return;
      setState(
        () => _mensaje = kIsWeb
            ? 'Descarga CSV solicitada al navegador.'
            : 'CSV copiado al portapapeles.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _mensaje = 'No se pudo exportar el listado. Intenta nuevamente.',
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final habilitado =
          !_exportando &&
          c.deporteId != null &&
          c.alumnos.isNotEmpty &&
          !c.cambios &&
          !c.guardando &&
          !c.cargando &&
          c.error == null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: habilitado ? _exportar : null,
            icon: const Icon(Icons.download_outlined),
            label: Text(
              _exportando
                  ? 'Preparando listado…'
                  : kIsWeb
                  ? 'Descargar listado CSV'
                  : 'Copiar listado CSV',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Incluye toda la nómina y el porcentaje acumulado hasta la fecha seleccionada. Guarda tus cambios antes de exportar.',
          ),
          if (_mensaje != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_mensaje!),
            ),
        ],
      );
    },
  );
}
