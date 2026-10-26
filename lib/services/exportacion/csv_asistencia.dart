import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';

/// Los porcentajes solo incluyen sesiones con estado explícito para el alumno.
/// No considera sesiones previas a su inscripción ni pendientes como ausencias.
String generarCsvAsistencia({
  required String disciplina,
  required DateTime fecha,
  required List<AlumnoInscrito> alumnos,
  required List<SesionAsistencia> sesiones,
}) {
  final filas = <List<String>>[
    [
      'Disciplina',
      'Fecha',
      'Nombre',
      'Carnet',
      'Correo',
      'Asistencia de la fecha',
      'Sesiones registradas',
      'Presencias acumuladas',
      'Porcentaje de asistencia',
    ],
  ];
  final hastaFecha = sesiones.where(
    (s) => !s.fecha.isAfter(DateTime(fecha.year, fecha.month, fecha.day)),
  );
  for (final alumno in alumnos) {
    final registros = hastaFecha
        .map((s) => s.estados[alumno.inscripcionId])
        .whereType<EstadoAsistencia>()
        .toList();
    final presentes = registros
        .where((e) => e == EstadoAsistencia.presente)
        .length;
    EstadoAsistencia? estadoFecha;
    for (final sesion in hastaFecha) {
      if (claveFecha(sesion.fecha) == claveFecha(fecha)) {
        estadoFecha = sesion.estados[alumno.inscripcionId];
      }
    }
    filas.add([
      disciplina,
      claveFecha(fecha),
      alumno.nombre,
      alumno.carnet,
      alumno.correo,
      estadoFecha?.name ?? 'sin registrar',
      '${registros.length}',
      '$presentes',
      registros.isEmpty
          ? 'Sin registros'
          : '${(100 * presentes / registros.length).toStringAsFixed(1)}%',
    ]);
  }
  return '\uFEFF${filas.map((f) => f.map(_celdaSegura).join(',')).join('\r\n')}\r\n';
}

String _celdaSegura(String valor) {
  // Evita interpretar nombres o correos como fórmulas al abrir el CSV.
  final texto = RegExp(r'^\s*[=+@\-\t\r\n]').hasMatch(valor)
      ? "'$valor"
      : valor;
  return '"${texto.replaceAll('"', '""')}"';
}
