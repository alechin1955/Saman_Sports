import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/historial_controller.dart';
import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/controllers/pagos_controller.dart';
import 'package:saman_sports/controllers/recordatorios_controller.dart';
import 'package:saman_sports/controllers/soporte_estudiante_controller.dart';

/// Lee `usuarios/{uid}.solvente`. Si no hay sesión o falla la lectura, no
/// deja inscribir. No se usa en las pruebas: esas inyectan su controlador.
Future<bool> _leerSolvenciaEstudiante() async {
  try {
    final uid = FirebaseServices.currentUser?.uid;
    if (uid == null) return false;
    final datos = await FirebaseServices.getUserData(uid: uid);
    return datos?['solvente'] == true;
  } catch (_) {
    return false;
  }
}

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
         inscripciones ??
             InscripcionesController(leerSolvencia: _leerSolvenciaEstudiante),
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