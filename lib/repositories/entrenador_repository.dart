import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/deporte.dart';

abstract interface class EntrenadorRepository {
  Future<List<Deporte>> disciplinas();
  Future<List<AlumnoInscrito>> inscritos(String deporteId);
}

/// Las asignaciones utilizan el UID de Auth, nunca el nombre del entrenador.
/// Las reglas de Firestore deben verificar el mismo vínculo en el servidor.
class FirestoreEntrenadorRepository implements EntrenadorRepository {
  FirestoreEntrenadorRepository({this.firestore, this.auth});
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  FirebaseFirestore get db => firestore ?? FirebaseFirestore.instance;
  String get uid {
    final usuario = (auth ?? FirebaseAuth.instance).currentUser;
    if (usuario == null) throw StateError('Sesión requerida');
    return usuario.uid;
  }

  @override
  Future<List<Deporte>> disciplinas() async {
    final snapshot = await db
        .collection('deportes')
        .where('entrenadorUid', isEqualTo: uid)
        .get();
    final lista = snapshot.docs
        .where((d) => d.data()['activo'] == true)
        .map((d) => Deporte.fromMap({...d.data(), 'id': d.id}))
        .toList();
    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  @override
  Future<List<AlumnoInscrito>> inscritos(String deporteId) async {
    final entrenadorUid = uid;
    final deporte = await db.collection('deportes').doc(deporteId).get();
    if (deporte.data()?['entrenadorUid'] != entrenadorUid ||
        deporte.data()?['activo'] != true) {
      throw StateError('Disciplina no asignada');
    }
    // Un solo filtro evita exigir un índice compuesto nuevo.
    final snapshot = await db
        .collection('inscripciones')
        .where('deporteId', isEqualTo: deporteId)
        .get();
    final confirmadas = snapshot.docs.where(
      (d) => d.data()['estado'] == 'confirmada',
    );
    final alumnos = await Future.wait(
      confirmadas.map((inscripcion) async {
        final estudianteUid = inscripcion.data()['estudianteUid'];
        if (estudianteUid is! String || estudianteUid.isEmpty) {
          throw const FormatException('Inscripción sin estudiante');
        }
        final perfil =
            (await db.collection('usuarios').doc(estudianteUid).get()).data();
        final nombre = [
          perfil?['nombre'],
          perfil?['apellido'],
        ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
        return AlumnoInscrito(
          inscripcionId: inscripcion.id,
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
