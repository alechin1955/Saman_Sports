import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/entrenador_admin.dart';

abstract interface class AdminEntrenadorRepository {
  Stream<Map<String, Map<String, dynamic>>> entrenadoresPublicos();
  Stream<Map<String, Map<String, dynamic>>> perfilesPrivados();
  Future<String?> crearCuenta({
    required String correo,
    required String clave,
    required EntrenadorAdmin datos,
  });
  Future<String?> actualizar(EntrenadorAdmin datos);
  Future<String?> cambiarEstado({required String uid, required bool activo});
}

class FirebaseAdminEntrenadorAdapter implements AdminEntrenadorRepository {
  @override
  Stream<Map<String, Map<String, dynamic>>> entrenadoresPublicos() {
    return FirebaseServices.streamEntrenadoresAdmin().map(_porUid);
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> perfilesPrivados() {
    return FirebaseServices.streamPerfilesEntrenadoresAdmin().map(_porUid);
  }

  @override
  Future<String?> crearCuenta({
    required String correo,
    required String clave,
    required EntrenadorAdmin datos,
  }) {
    return _texto(
      FirebaseServices.crearCuentaEntrenador(
        correo: correo,
        clave: clave,
        privado: datos.toMapPrivado(),
        publico: datos.toMapPublico(),
      ),
    );
  }

  @override
  Future<String?> actualizar(EntrenadorAdmin datos) {
    return _texto(
      FirebaseServices.actualizarEntrenador(
        uid: datos.uid,
        publico: datos.toMapPublico(),
        privado: datos.toMapPrivado(),
      ),
    );
  }

  @override
  Future<String?> cambiarEstado({required String uid, required bool activo}) {
    return _texto(
      FirebaseServices.cambiarEstadoEntrenador(uid: uid, activo: activo),
    );
  }
}

Map<String, Map<String, dynamic>> _porUid(List<Map<String, dynamic>> lista) {
  return {for (final item in lista) '${item['id'] ?? ''}': item};
}

Future<String?> _texto(Future<AuthResponse> respuesta) async {
  final resultado = await respuesta;
  if (resultado.isSuccess) return null;
  return resultado.errorMessage ?? 'Ocurrió un error. Inténtalo de nuevo.';
}
