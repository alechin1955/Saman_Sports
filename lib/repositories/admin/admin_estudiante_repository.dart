import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/estudiante.dart';

abstract interface class AdminEstudianteRepository {
  Stream<List<Estudiante>> estudiantes();
  Future<String?> cambiarEstado({required String uid, required bool activo});
  Future<String?> actualizarSolvencia({
    required String uid,
    required bool solvente,
  });
}

class FirebaseAdminEstudianteAdapter implements AdminEstudianteRepository {
  @override
  Stream<List<Estudiante>> estudiantes() {
    return FirebaseServices.streamEstudiantesAdmin().map(
      (lista) => lista
          .map((mapa) => Estudiante.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Future<String?> cambiarEstado({required String uid, required bool activo}) {
    return _texto(
      FirebaseServices.actualizarEstadoEstudiante(uid: uid, activo: activo),
    );
  }

  @override
  Future<String?> actualizarSolvencia({
    required String uid,
    required bool solvente,
  }) {
    return _texto(
      FirebaseServices.actualizarSolvencia(uid: uid, solvente: solvente),
    );
  }
}

Future<String?> _texto(Future<AuthResponse> respuesta) async {
  final resultado = await respuesta;
  if (resultado.isSuccess) return null;
  return resultado.errorMessage ?? 'Ocurrió un error. Inténtalo de nuevo.';
}
