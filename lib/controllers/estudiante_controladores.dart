import 'package:saman_sports/controllers/inscripciones_controller.dart';

/// Agrupa los controladores extra del panel del estudiante (inscripciones,
/// y en los siguientes pasos pagos, soporte y recordatorios). Lo crea y
/// destruye _SamanSportsAppState (app.dart), igual que AdminControladores.
class EstudianteControladores {
  EstudianteControladores({InscripcionesController? inscripciones})
    : inscripciones = inscripciones ?? InscripcionesController();

  final InscripcionesController inscripciones;

  void dispose() {
    inscripciones.dispose();
  }
}