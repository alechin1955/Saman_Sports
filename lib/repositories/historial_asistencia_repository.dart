import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saman_sports/models/asistencia.dart';

abstract interface class HistorialAsistenciaRepository {
  Future<List<SesionAsistencia>> sesiones(String deporteId);
}

class FirestoreHistorialAsistenciaRepository
    implements HistorialAsistenciaRepository {
  @override
  Future<List<SesionAsistencia>> sesiones(String deporteId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sesión requerida');
    final deporte = FirebaseFirestore.instance
        .collection('deportes')
        .doc(deporteId);
    final asignacion = (await deporte.get()).data();
    if (asignacion?['entrenadorUid'] != uid || asignacion?['activo'] != true) {
      throw StateError('Disciplina no asignada');
    }
    final snapshot = await deporte.collection('asistencias').get();
    final sesiones = snapshot.docs.map((doc) {
      final fecha = DateTime.tryParse(doc.id);
      final estados = doc.data()['estados'];
      if (fecha == null || estados is! Map) {
        throw const FormatException('Historial de asistencia inválido');
      }
      return SesionAsistencia(
        fecha: fecha,
        estados: estados.map(
          (id, valor) => MapEntry(id.toString(), switch (valor) {
            'presente' => EstadoAsistencia.presente,
            'ausente' => EstadoAsistencia.ausente,
            _ => throw const FormatException('Estado de asistencia inválido'),
          }),
        ),
      );
    }).toList();
    sesiones.sort((a, b) => a.fecha.compareTo(b.fecha));
    return sesiones;
  }
}
