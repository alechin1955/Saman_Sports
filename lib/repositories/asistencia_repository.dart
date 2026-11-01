import 'package:saman_sports/FirebaseServices.dart';
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
class FirebaseAsistenciaAdapter implements AsistenciaRepository {
  String get _uid {
    final uid = FirebaseServices.currentUser?.uid;
    if (uid == null) throw StateError('Sesión requerida');
    return uid;
  }

  @override
  Future<Map<String, EstadoAsistencia>> leer(
    String deporteId,
    DateTime fecha,
  ) async {
    final uid = _uid;
    final asignada = await FirebaseServices.esDisciplinaAsignada(
      deporteId: deporteId,
      entrenadorUid: uid,
    );
    if (!asignada) {
      throw StateError('Disciplina no asignada');
    }
    final data = await FirebaseServices.getAsistenciaSesion(
      deporteId: deporteId,
      fecha: fecha,
    );
    if (data == null) return {};
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
    final respuesta = await FirebaseServices.guardarAsistenciaSesion(
      deporteId: deporteId,
      fecha: fecha,
      entrenadorUid: uid,
      estados: estados.map((id, estado) => MapEntry(id, estado.name)),
    );
    if (!respuesta.isSuccess) {
      throw StateError(respuesta.errorMessage ?? 'No se pudo guardar');
    }
  }
}

/// Alias de compatibilidad para código que aún usa el nombre anterior.
@Deprecated('Usa FirebaseAsistenciaAdapter')
class FirestoreAsistenciaRepository extends FirebaseAsistenciaAdapter {}
