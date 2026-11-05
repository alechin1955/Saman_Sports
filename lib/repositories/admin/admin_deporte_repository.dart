import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/reserva_horario.dart';

abstract interface class AdminDeporteRepository {
  Stream<List<Deporte>> deportes();
  Stream<List<Cancha>> canchas();
  Stream<List<ReservaHorario>> reservasCancha(String canchaId);
  Future<String?> crearCancha({
    required String nombre,
    required String ubicacion,
    required String descripcion,
  });
  Future<String?> actualizarCancha({
    required String id,
    required String nombre,
    required String ubicacion,
    required String descripcion,
    required bool activa,
  });
  Future<String?> crearDeporte({
    required Map<String, dynamic> datos,
    required String canchaId,
    required List<Map<String, dynamic>> franjas,
  });
  Future<String?> actualizarDeporte({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    List<Map<String, dynamic>>? franjas,
  });
  Future<String?> cambiarEstadoDeporte({
    required String id,
    required bool activo,
  });
  Future<String?> asignarEntrenador({
    required String deporteId,
    required String entrenadorUid,
    required String entrenadorNombre,
  });
}

class FirebaseAdminDeporteAdapter implements AdminDeporteRepository {
  @override
  Stream<List<Deporte>> deportes() {
    return FirebaseServices.streamDeportesAdmin().map(
      (lista) => lista.map(Deporte.fromMap).toList(),
    );
  }

  @override
  Stream<List<Cancha>> canchas() {
    return FirebaseServices.streamCanchas().map(
      (lista) => lista
          .map((mapa) => Cancha.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) {
    return FirebaseServices.streamReservasCancha(canchaId).map(
      (lista) => lista
          .map((mapa) => ReservaHorario.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Future<String?> crearCancha({
    required String nombre,
    required String ubicacion,
    required String descripcion,
  }) {
    return _texto(
      FirebaseServices.crearCancha(
        datos: {
          'nombre': nombre,
          'ubicacion': ubicacion,
          'descripcion': descripcion,
        },
      ),
    );
  }

  @override
  Future<String?> actualizarCancha({
    required String id,
    required String nombre,
    required String ubicacion,
    required String descripcion,
    required bool activa,
  }) {
    return _texto(
      FirebaseServices.actualizarCancha(
        id: id,
        datos: {
          'nombre': nombre,
          'ubicacion': ubicacion,
          'descripcion': descripcion,
          'activa': activa,
        },
      ),
    );
  }

  @override
  Future<String?> crearDeporte({
    required Map<String, dynamic> datos,
    required String canchaId,
    required List<Map<String, dynamic>> franjas,
  }) {
    return _texto(
      FirebaseServices.crearDeporte(
        datos: datos,
        canchaId: canchaId,
        franjas: franjas,
      ),
    );
  }

  @override
  Future<String?> actualizarDeporte({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    List<Map<String, dynamic>>? franjas,
  }) {
    return _texto(
      FirebaseServices.actualizarDeporte(
        id: id,
        datos: datos,
        canchaId: canchaId,
        franjas: franjas,
      ),
    );
  }

  @override
  Future<String?> cambiarEstadoDeporte({
    required String id,
    required bool activo,
  }) {
    return _texto(
      FirebaseServices.cambiarEstadoDeporte(id: id, activo: activo),
    );
  }

  @override
  Future<String?> asignarEntrenador({
    required String deporteId,
    required String entrenadorUid,
    required String entrenadorNombre,
  }) {
    return _texto(
      FirebaseServices.asignarEntrenadorDisciplina(
        deporteId: deporteId,
        entrenadorUid: entrenadorUid,
        entrenadorNombre: entrenadorNombre,
      ),
    );
  }
}

Future<String?> _texto(Future<AuthResponse> respuesta) async {
  final resultado = await respuesta;
  if (resultado.isSuccess) return null;
  return resultado.errorMessage ?? 'Ocurrió un error. Inténtalo de nuevo.';
}
