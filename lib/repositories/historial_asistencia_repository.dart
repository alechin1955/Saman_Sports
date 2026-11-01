import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/asistencia.dart';

abstract interface class HistorialAsistenciaRepository {
  Future<List<SesionAsistencia>> sesiones(String deporteId);
}

class FirebaseHistorialAsistenciaAdapter
    implements HistorialAsistenciaRepository {
  @override
  Future<List<SesionAsistencia>> sesiones(String deporteId) async {
    final uid = FirebaseServices.currentUser?.uid;
    if (uid == null) throw StateError('Sesión requerida');
    final asignada = await FirebaseServices.esDisciplinaAsignada(
      deporteId: deporteId,
      entrenadorUid: uid,
    );
    if (!asignada) {
      throw StateError('Disciplina no asignada');
    }
    final registros = await FirebaseServices.getAsistenciasDisciplina(
      deporteId: deporteId,
    );
    final sesiones = registros.map((registro) {
      final fecha = DateTime.tryParse('${registro['id'] ?? ''}');
      final estados = registro['estados'];
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

/// Alias de compatibilidad para código que aún usa el nombre anterior.
@Deprecated('Usa FirebaseHistorialAsistenciaAdapter')
class FirestoreHistorialAsistenciaRepository
    extends FirebaseHistorialAsistenciaAdapter {}
