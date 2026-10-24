// Clase base del dominio (enunciado del proyecto y diagrama de clases del
// Hito 1): toda persona del sistema tiene cédula, nombre y correo.
// En Firestore son los campos comunes de usuarios/{uid}; el uid es el mismo
// de Firebase Authentication.

abstract class Persona {
  const Persona({
    required this.uid,
    required this.cedula,
    required this.nombre,
    required this.apellido,
    required this.correo,
  });

  final String uid;
  final String cedula;
  final String nombre;
  final String apellido;
  final String correo;

  String get nombreCompleto => '$nombre $apellido'.trim();

  String get iniciales {
    final n = nombre.trim();
    final a = apellido.trim();
    final primera = n.isEmpty ? '' : n[0];
    final segunda = a.isEmpty ? '' : a[0];
    return '$primera$segunda'.toUpperCase();
  }
}
