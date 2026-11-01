import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/deporte.dart';

abstract interface class EntrenadorRepository {
  Future<List<Deporte>> disciplinas();
  Future<List<AlumnoInscrito>> inscritos(String deporteId);
}

/// Las asignaciones utilizan el UID de Auth, nunca el nombre del entrenador.
/// Las reglas de Firestore deben verificar el mismo vínculo en el servidor.
class FirebaseEntrenadorAdapter implements EntrenadorRepository {
  String get uid {
    final usuario = FirebaseServices.currentUser;
    if (usuario == null) throw StateError('Sesión requerida');
    return usuario.uid;
  }

  @override
  Future<List<Deporte>> disciplinas() async {
    final datos = await FirebaseServices.getDisciplinasEntrenador(
      entrenadorUid: uid,
    );
    final lista = datos.map(Deporte.fromMap).toList();
    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  @override
  Future<List<AlumnoInscrito>> inscritos(String deporteId) async {
    final entrenadorUid = uid;
    final asignada = await FirebaseServices.esDisciplinaAsignada(
      deporteId: deporteId,
      entrenadorUid: entrenadorUid,
    );
    if (!asignada) {
      throw StateError('Disciplina no asignada');
    }
    final confirmadas = await FirebaseServices.getInscripcionesConfirmadas(
      deporteId: deporteId,
    );
    final alumnos = await Future.wait(
      confirmadas.map((inscripcion) async {
        final estudianteUid = inscripcion['estudianteUid'];
        if (estudianteUid is! String || estudianteUid.isEmpty) {
          throw const FormatException('Inscripción sin estudiante');
        }
        final perfil = await FirebaseServices.getUserData(uid: estudianteUid);
        final nombre = [
          perfil?['nombre'],
          perfil?['apellido'],
        ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
        return AlumnoInscrito(
          inscripcionId: '${inscripcion['id'] ?? ''}',
          uid: estudianteUid,
          nombre: nombre.isEmpty ? 'Perfil no disponible' : nombre,
          carnet: '${perfil?['carnet'] ?? ''}',
          correo: '${perfil?['correo'] ?? ''}',
        );
      }),
    );
    alumnos.sort((a, b) => a.nombre.compareTo(b.nombre));
    return alumnos;
  }
}

/// Alias de compatibilidad para código que aún usa el nombre anterior.
@Deprecated('Usa FirebaseEntrenadorAdapter')
class FirestoreEntrenadorRepository extends FirebaseEntrenadorAdapter {
  FirestoreEntrenadorRepository();
}
