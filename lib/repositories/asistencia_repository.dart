import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saman_sports/models/asistencia.dart';

abstract interface class AsistenciaRepository {
  Future<Map<String, EstadoAsistencia>> leer(String deporteId, DateTime fecha);
  Future<void> guardar(
    String deporteId,
    DateTime fecha,
    Map<String, EstadoAsistencia> estados,
  );
}

/// Una sesión por disciplina y fecha. La transacción comprueba asignación y
/// matrícula vigente antes de sobrescribir el registro completo de esa sesión.
class FirestoreAsistenciaRepository implements AsistenciaRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sesión requerida');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _sesion(
    String deporteId,
    DateTime fecha,
  ) => _db
      .collection('deportes')
      .doc(deporteId)
      .collection('asistencias')
      .doc(claveFecha(fecha));

  @override
  Future<Map<String, EstadoAsistencia>> leer(
    String deporteId,
    DateTime fecha,
  ) async {
    final uid = _uid;
    final deporte = await _db.collection('deportes').doc(deporteId).get();
    if (deporte.data()?['entrenadorUid'] != uid ||
        deporte.data()?['activo'] != true) {
      throw StateError('Disciplina no asignada');
    }
    final data = (await _sesion(deporteId, fecha).get()).data()?['estados'];
    if (data == null) return {};
    if (data is! Map) {
      throw const FormatException('Registro de asistencia inválido');
    }
    final estados = <String, EstadoAsistencia>{};
    for (final entrada in data.entries) {
      final estado = switch (entrada.value) {
        'presente' => EstadoAsistencia.presente,
        'ausente' => EstadoAsistencia.ausente,
        _ => throw const FormatException('Estado de asistencia inválido'),
      };
      estados[entrada.key.toString()] = estado;
    }
    return estados;
  }

  @override
  Future<void> guardar(
    String deporteId,
    DateTime fecha,
    Map<String, EstadoAsistencia> estados,
  ) async {
    final uid = _uid;
    if (estados.isEmpty || estados.length > 450) {
      throw StateError('Nómina vacía o demasiado grande');
    }
    final hoy = DateTime.now();
    if (DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    ).isAfter(DateTime(hoy.year, hoy.month, hoy.day))) {
      throw StateError('No se puede registrar asistencia futura');
    }
    await _db.runTransaction((tx) async {
      final deporte = await tx.get(_db.collection('deportes').doc(deporteId));
      if (deporte.data()?['entrenadorUid'] != uid ||
          deporte.data()?['activo'] != true) {
        throw StateError('Disciplina no asignada');
      }
      // Todas las lecturas preceden a la escritura en la transacción.
      for (final id in estados.keys) {
        final inscripcion = await tx.get(
          _db.collection('inscripciones').doc(id),
        );
        if (inscripcion.data()?['deporteId'] != deporteId ||
            inscripcion.data()?['estado'] != 'confirmada') {
          throw StateError('La nómina cambió. Actualiza antes de guardar');
        }
      }
      tx.set(_sesion(deporteId, fecha), {
        'fecha': claveFecha(fecha),
        'entrenadorUid': uid,
        'estados': estados.map((id, estado) => MapEntry(id, estado.name)),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }
}
