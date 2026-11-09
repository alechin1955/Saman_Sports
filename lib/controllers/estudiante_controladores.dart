import 'package:saman_sports/controllers/historial_controller.dart';
import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/controllers/pagos_controller.dart';

/// Agrupa los controladores extra del panel del estudiante (inscripciones,
/// pagos, historial y, en los siguientes pasos, soporte y recordatorios).
/// Lo crea y destruye _SamanSportsAppState (app.dart), igual que
/// AdminControladores.
class EstudianteControladores {
  EstudianteControladores({
    InscripcionesController? inscripciones,
    PagosController? pagos,
    HistorialController? historial,
  }) : this._(
         inscripciones ?? InscripcionesController(),
         pagos ?? PagosController(),
         historial,
       );

  EstudianteControladores._(
    this.inscripciones,
    this.pagos,
    HistorialController? historial,
  ) : historial = historial ?? HistorialController(inscripciones: inscripciones);

  final InscripcionesController inscripciones;
  final PagosController pagos;

  /// Escucha a [inscripciones] para calcular la asistencia (RF-14).
  final HistorialController historial;

  void dispose() {
    historial.dispose();
    inscripciones.dispose();
    pagos.dispose();
  }
}