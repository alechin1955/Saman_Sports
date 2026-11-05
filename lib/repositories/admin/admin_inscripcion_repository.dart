import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/inscripcion.dart';

abstract interface class AdminInscripcionRepository {
  Stream<List<Inscripcion>> inscripciones();
  Future<String?> cambiarEstado({required String id, required String estado});
}

class FirebaseAdminInscripcionAdapter implements AdminInscripcionRepository {
  @override
  Stream<List<Inscripcion>> inscripciones() {
    return FirebaseServices.streamInscripcionesAdmin().map(
      (lista) => lista.map(Inscripcion.fromMap).toList(),
    );
  }

  @override
  Future<String?> cambiarEstado({required String id, required String estado}) {
    return _texto(
      FirebaseServices.cambiarEstadoInscripcion(id: id, estado: estado),
    );
  }
}

Future<String?> _texto(Future<AuthResponse> respuesta) async {
  final resultado = await respuesta;
  if (resultado.isSuccess) return null;
  return resultado.errorMessage ?? 'Ocurrió un error. Inténtalo de nuevo.';
}
