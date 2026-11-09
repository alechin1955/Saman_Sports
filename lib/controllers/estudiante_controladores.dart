import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/controllers/pagos_controller.dart';

/// Agrupa los controladores extra del panel del estudiante (inscripciones,
/// pagos y, en los siguientes pasos, soporte y recordatorios). Lo crea y
/// destruye _SamanSportsAppState (app.dart), igual que AdminControladores.
class EstudianteControladores {
  EstudianteControladores({
    InscripcionesController? inscripciones,
    PagosController? pagos,
  }) : inscripciones = inscripciones ?? InscripcionesController(),
       pagos = pagos ?? PagosController();

  final InscripcionesController inscripciones;
  final PagosController pagos;

  void dispose() {
    inscripciones.dispose();
    pagos.dispose();
  }
}