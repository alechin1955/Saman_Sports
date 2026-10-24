import 'package:saman_sports/models/persona.dart';

// Esquema Firestore usuarios/{uid} con rol 'estudiante':
// nombre, apellido, cedula, carnet, telefono, correo, rol, creadoEn,
// estado ('activo' | 'inactivo'; lo cambia el administrador; si falta = activo),
// solvente (bool; lo marca el administrador; si falta = false).

class Estudiante extends Persona {
  const Estudiante({
    required super.uid,
    required super.cedula,
    required super.nombre,
    required super.apellido,
    required super.correo,
    required this.carnet,
    required this.telefono,
    required this.activo,
    required this.solvente,
  });

  final String carnet;
  final String telefono;
  final bool activo;
  final bool solvente;

  factory Estudiante.fromMap(String uid, Map<String, dynamic> map) {
    return Estudiante(
      uid: uid,
      cedula: '${map['cedula'] ?? ''}',
      nombre: '${map['nombre'] ?? ''}',
      apellido: '${map['apellido'] ?? ''}',
      correo: '${map['correo'] ?? ''}',
      carnet: '${map['carnet'] ?? ''}',
      telefono: '${map['telefono'] ?? ''}',
      activo: '${map['estado'] ?? 'activo'}' != 'inactivo',
      solvente: map['solvente'] == true,
    );
  }

  /// Campos que el estudiante puede cambiar desde "Mi perfil".
  /// Cédula, carnet y correo no se editan; rol, estado y solvente
  /// solo los cambia el administrador.
  Map<String, dynamic> toMapEditable() {
    return {
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'telefono': telefono.trim(),
    };
  }

  Estudiante copiaCon({String? nombre, String? apellido, String? telefono}) {
    return Estudiante(
      uid: uid,
      cedula: cedula,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      correo: correo,
      carnet: carnet,
      telefono: telefono ?? this.telefono,
      activo: activo,
      solvente: solvente,
    );
  }
}
