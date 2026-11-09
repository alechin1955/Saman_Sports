import 'package:saman_sports/controllers/historial_controller.dart';
import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/controllers/pagos_controller.dart';
import 'package:saman_sports/controllers/recordatorios_controller.dart';
import 'package:saman_sports/controllers/soporte_estudiante_controller.dart';

/// Agrupa los controladores extra del panel del estudiante: inscripciones,
/// pagos, historial, recordatorios y soporte. Lo crea y destruye
/// _SamanSportsAppState (app.dart), igual que AdminControladores.
class EstudianteControladores {
  EstudianteControladores({
    InscripcionesController? inscripciones,
    PagosController? pagos,
    HistorialController? historial,
    RecordatoriosController? recordatorios,
    SoporteEstudianteController? soporte,
  }) : this._(
         inscripciones ?? InscripcionesController(),
         pagos ?? PagosController(),
         historial,
         recordatorios ?? RecordatoriosController(),
         soporte ?? SoporteEstudianteController(),
       );

  EstudianteControladores._(
    this.inscripciones,
    this.pagos,
    HistorialController? historial,
    this.recordatorios,
    this.soporte,
  ) : historial = historial ?? HistorialController(inscripciones: inscripciones);

  final InscripcionesController inscripciones;
  final PagosController pagos;
  final RecordatoriosController recordatorios;
  final SoporteEstudianteController soporte;

  /// Escucha a [inscripciones] para calcular la asistencia (RF-14).
  final HistorialController historial;

  void dispose() {
    historial.dispose();
    inscripciones.dispose();
    pagos.dispose();
    recordatorios.dispose();
    soporte.dispose();
  }
}