enum EstadoAsistencia { presente, ausente }

String claveFecha(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

class SesionAsistencia {
  const SesionAsistencia({required this.fecha, required this.estados});
  final DateTime fecha;

  /// Clave: ID de inscripción. Un alumno sin entrada aún no está registrado.
  final Map<String, EstadoAsistencia> estados;
}
