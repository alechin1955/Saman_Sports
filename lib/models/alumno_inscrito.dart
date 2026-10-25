/// Estudiante con inscripción confirmada en la disciplina seleccionada.
class AlumnoInscrito {
  const AlumnoInscrito({
    required this.inscripcionId,
    required this.uid,
    required this.nombre,
    required this.carnet,
    required this.correo,
  });
  final String inscripcionId;
  final String uid;
  final String nombre;
  final String carnet;
  final String correo;
}
