import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_entrenador_controller.dart';
import 'package:saman_sports/controllers/admin/admin_estudiante_controller.dart';
import 'package:saman_sports/controllers/admin/admin_evento_controller.dart';
import 'package:saman_sports/controllers/admin/admin_inscripcion_controller.dart';
import 'package:saman_sports/controllers/admin/admin_pago_controller.dart';
import 'package:saman_sports/controllers/admin/admin_resena_controller.dart';
import 'package:saman_sports/controllers/admin/admin_resumen_controller.dart';
import 'package:saman_sports/controllers/admin/admin_soporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_transaccion_controller.dart';

/// Agrupa los controladores del panel de administrador. Lo crea y destruye
/// _SamanSportsAppState (app.dart) y se inyecta en AdminDashboardView.
class AdminControladores {
  AdminControladores({
    AdminResumenController? resumen,
    AdminDeporteController? deportes,
    AdminEntrenadorController? entrenadores,
    AdminEstudianteController? estudiantes,
    AdminResenaController? resenas,
    AdminPagoController? pagos,
    AdminInscripcionController? inscripciones,
    AdminEventoController? eventos,
    AdminSoporteController? soporte,
    AdminTransaccionController? transacciones,
  }) : resumen = resumen ?? AdminResumenController(),
       deportes = deportes ?? AdminDeporteController(),
       entrenadores = entrenadores ?? AdminEntrenadorController(),
       estudiantes = estudiantes ?? AdminEstudianteController(),
       resenas = resenas ?? AdminResenaController(),
       pagos = pagos ?? AdminPagoController(),
       inscripciones = inscripciones ?? AdminInscripcionController(),
       eventos = eventos ?? AdminEventoController(),
       soporte = soporte ?? AdminSoporteController(),
       transacciones = transacciones ?? AdminTransaccionController();

  final AdminResumenController resumen;
  final AdminDeporteController deportes;
  final AdminEntrenadorController entrenadores;
  final AdminEstudianteController estudiantes;
  final AdminResenaController resenas;
  final AdminPagoController pagos;
  final AdminInscripcionController inscripciones;
  final AdminEventoController eventos;
  final AdminSoporteController soporte;
  final AdminTransaccionController transacciones;

  void dispose() {
    resumen.dispose();
    deportes.dispose();
    entrenadores.dispose();
    estudiantes.dispose();
    resenas.dispose();
    pagos.dispose();
    inscripciones.dispose();
    eventos.dispose();
    soporte.dispose();
    transacciones.dispose();
  }
}
