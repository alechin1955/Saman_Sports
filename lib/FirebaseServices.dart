import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/core/utils/solicitud_evento_entrenador.dart';
import 'package:saman_sports/models/reserva_horario.dart';

class FirebaseServices {
  static Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return AuthResponse(credential: credential, isSuccess: true);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(errorMessage: e.message, isSuccess: false);
    } catch (e) {
      return AuthResponse(errorMessage: 'Error desconocido', isSuccess: false);
    }
  }

  static Future<(UserCredential? credential, String? errorMessage)> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return (credential, null);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No existe ningún usuario registrado con ese correo.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'La contraseña o el usuario son incorrectos.';
          break;
        case 'invalid-email':
          message = 'El formato del correo electrónico no es válido.';
          break;
        default:
          message = e.message ?? 'Error de autenticación.';
      }
      return (null, message);
    } catch (e) {
      return (null, 'Ocurrió un error al intentar iniciar sesión.');
    }
  }

  // ---------------------------------------------------------------------------
  // Funciones agregadas por Ariadna (Home, Login, Registro, Recuperar contraseña)
  // ---------------------------------------------------------------------------

  /// Nombre de la colección de Firestore donde se guarda cada usuario
  /// (documento usuarios/{uid}).
  static const String usuariosCollection = 'usuarios';

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Envía el correo de Firebase con el ENLACE para restablecer la contraseña.
  /// Por seguridad, si el correo no está registrado se responde como éxito,
  /// así la pantalla muestra siempre el mismo mensaje genérico.
  static Future<AuthResponse> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.setLanguageCode('es');
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResponse(isSuccess: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return AuthResponse(isSuccess: true);
      return AuthResponse(errorMessage: _authErrorMessage(e), isSuccess: false);
    } catch (_) {
      return AuthResponse(
        errorMessage: 'No se pudo enviar el enlace. Intenta nuevamente.',
        isSuccess: false,
      );
    }
  }

  /// Cierra la sesión del usuario actual.
  static Future<void> signOut() => _auth.signOut();

  /// Usuario con sesión abierta, o null si no hay nadie.
  static User? get currentUser => _auth.currentUser;

  /// Emite el usuario cada vez que alguien inicia o cierra sesión.
  /// main.dart / app.dart lo usan para decidir si mostrar el Home o el dashboard.
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// "Recordar sesión" del login (solo aplica en web).
  /// true: la sesión se mantiene al cerrar el navegador. false: dura solo la pestaña.
  static Future<void> setRememberSession(bool remember) async {
    if (!kIsWeb) return;
    await _auth.setPersistence(
      remember ? Persistence.LOCAL : Persistence.SESSION,
    );
  }

  /// Guarda (o actualiza) los datos del usuario en usuarios/{uid}.
  /// [data] debe incluir el campo 'rol' ('estudiante', 'entrenador' o 'administrador').
  static Future<AuthResponse> saveUserData({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db
          .collection(usuariosCollection)
          .doc(uid)
          .set(data, SetOptions(merge: true));
      return AuthResponse(isSuccess: true);
    } on FirebaseException catch (e) {
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } catch (_) {
      return AuthResponse(
        errorMessage: 'No se pudieron guardar los datos. Intenta nuevamente.',
        isSuccess: false,
      );
    }
  }

  /// Lee los datos del usuario desde usuarios/{uid}.
  /// Devuelve null si el documento no existe o si hubo un error.
  static Future<Map<String, dynamic>?> getUserData({
    required String uid,
  }) async {
    try {
      final doc = await _db.collection(usuariosCollection).doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  /// Devuelve el rol guardado en usuarios/{uid}
  /// ('estudiante', 'entrenador' o 'administrador'), o null si no hay rol.
  static Future<String?> getUserRole({required String uid}) async {
    final data = await getUserData(uid: uid);
    final rol = data?['rol'];
    return rol is String ? rol : null;
  }

  /// Borra la cuenta recién creada en Auth. Se usa en el registro si la cuenta
  /// se creó pero no se pudieron guardar sus datos en Firestore, para no dejar
  /// cuentas a medias.
  static Future<({bool error, bool existe, String? rol})> consultarRol({
    required String uid,
  }) async {
    try {
      final doc = await _db.collection(usuariosCollection).doc(uid).get();
      if (!doc.exists) {
        return (error: false, existe: false, rol: null);
      }
      final rol = doc.data()?['rol'];
      return (error: false, existe: true, rol: rol is String ? rol : null);
    } catch (_) {
      return (error: true, existe: false, rol: null);
    }
  }

  static Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      // Si no se puede borrar, solo se cierra la sesión.
      await _auth.signOut();
    }
  }

  /// Traduce los códigos de error de Firebase Auth a mensajes en español.
  static String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'Ocurrió un error. Intenta nuevamente.';
    }
  }

  /// Traduce los errores de Firestore a mensajes en español.
  static String _firestoreErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permiso para realizar esta acción.';
      case 'unavailable':
        return 'Sin conexión. Revisa tu internet.';
      default:
        return 'No se pudieron guardar los datos. Intenta nuevamente.';
    }
  }

  static const String deportesCollection = 'deportes';
  static const String entrenadoresCollection = 'entrenadores';
  static const String resenasCollection = 'resenas';
  static const String inscripcionesCollection = 'inscripciones';
  static const String asistenciasCollection = 'asistencias';
  static const String canchasCollection = 'canchas';
  static const String reservasCollection = 'reservas';
  static const String transaccionesCollection = 'transacciones';
  static const String eventosCollection = 'eventos';
  static const String pagosCollection = 'pagos';
  static const String notificacionesCollection = 'notificaciones';
  static const String configuracionCollection = 'configuracion';
  static const String ticketsCollection = 'tickets';

  static Stream<List<Map<String, dynamic>>> streamDeportes() {
    return _streamConsulta(
      _db
          .collection(deportesCollection)
          .where('activo', isEqualTo: true)
          .orderBy('nombre'),
    );
  }

  static Stream<List<Map<String, dynamic>>> streamEntrenadores() {
    return _streamConsulta(
      _db
          .collection(entrenadoresCollection)
          .where('activo', isEqualTo: true)
          .orderBy('nombre'),
    );
  }

  static Stream<List<Map<String, dynamic>>> streamResenas({int limite = 6}) {
    return _streamConsulta(
      _db
          .collection(resenasCollection)
          .where('visible', isEqualTo: true)
          .orderBy('fecha', descending: true)
          .limit(limite),
    );
  }

  static Stream<List<Map<String, dynamic>>> _streamConsulta(
    Query<Map<String, dynamic>> consulta,
  ) {
    return consulta
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList();
        })
        .transform(
          StreamTransformer<
            List<Map<String, dynamic>>,
            List<Map<String, dynamic>>
          >.fromHandlers(
            handleError: (error, stack, sink) => sink.add(const []),
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // Funciones agregadas por Diego (panel del entrenador)
  // ---------------------------------------------------------------------------

  /// Consulta propia del panel entrenador. A diferencia del helper compartido,
  /// conserva los errores para que sus vistas no confundan un fallo con vacío.
  static Stream<List<Map<String, dynamic>>> _streamConsultaEntrenador(
    Query<Map<String, dynamic>> consulta,
  ) {
    return consulta.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Catálogo de canchas para solicitar eventos desde el panel entrenador.
  static Stream<List<Map<String, dynamic>>> streamCanchasEntrenador() {
    return _streamConsultaEntrenador(
      _db.collection(canchasCollection).orderBy('nombre'),
    );
  }

  /// Ocupación activa de una cancha. Propaga errores para impedir que el modal
  /// interprete un fallo de lectura como disponibilidad total.
  static Stream<List<Map<String, dynamic>>> streamReservasCanchaEntrenador(
    String canchaId,
  ) {
    return _streamConsultaEntrenador(
      _db
          .collection(reservasCollection)
          .where('canchaId', isEqualTo: canchaId)
          .where('activa', isEqualTo: true)
          .orderBy('dia')
          .orderBy('horaInicio'),
    );
  }

  /// Reseñas visibles de las disciplinas indicadas, sin depender del límite de
  /// la portada. Cada consulta usa una sola disciplina y las combina en vivo.
  static Stream<List<Map<String, dynamic>>> streamResenasDisciplinas({
    required List<String> deporteIds,
  }) {
    final ids = deporteIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return Stream.value(const []);

    late StreamController<List<Map<String, dynamic>>> controller;
    final ultimas = <String, List<Map<String, dynamic>>>{};
    final suscripciones = <StreamSubscription<List<Map<String, dynamic>>>>[];

    void emitir() {
      if (ultimas.length != ids.length || controller.isClosed) return;
      final unicas = <String, Map<String, dynamic>>{};
      for (final lista in ultimas.values) {
        for (final resena in lista) {
          unicas['${resena['id'] ?? ''}'] = resena;
        }
      }
      controller.add(unicas.values.toList(growable: false));
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        for (final id in ids) {
          final stream = _streamConsultaEntrenador(
            _db
                .collection(resenasCollection)
                .where('deporteId', isEqualTo: id)
                .where('visible', isEqualTo: true),
          );
          suscripciones.add(
            stream.listen((lista) {
              ultimas[id] = lista;
              emitir();
            }, onError: controller.addError),
          );
        }
      },
      onCancel: () async {
        await Future.wait(suscripciones.map((sub) => sub.cancel()));
      },
    );
    return controller.stream;
  }

  /// Disciplinas activas asignadas al entrenador identificado por su UID.
  static Future<List<Map<String, dynamic>>> getDisciplinasEntrenador({
    required String entrenadorUid,
  }) async {
    final snapshot = await _db
        .collection(deportesCollection)
        .where('entrenadorUid', isEqualTo: entrenadorUid)
        .get();
    return snapshot.docs
        .where((doc) => doc.data()['activo'] == true)
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
  }

  /// Confirma que una disciplina activa continúa asignada al entrenador.
  static Future<bool> esDisciplinaAsignada({
    required String deporteId,
    required String entrenadorUid,
  }) async {
    final deporte = await _db
        .collection(deportesCollection)
        .doc(deporteId)
        .get();
    return deporte.data()?['entrenadorUid'] == entrenadorUid &&
        deporte.data()?['activo'] == true;
  }

  /// Inscripciones confirmadas de una disciplina.
  /// Un solo filtro evita exigir un índice compuesto nuevo.
  static Future<List<Map<String, dynamic>>> getInscripcionesConfirmadas({
    required String deporteId,
  }) async {
    final snapshot = await _db
        .collection(inscripcionesCollection)
        .where('deporteId', isEqualTo: deporteId)
        .get();
    return snapshot.docs
        .where((doc) => doc.data()['estado'] == 'confirmada')
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
  }

  /// Estados guardados para una disciplina y fecha; null si no existe sesión.
  static Future<Map<String, dynamic>?> getAsistenciaSesion({
    required String deporteId,
    required DateTime fecha,
  }) async {
    final data = (await _sesionAsistencia(deporteId, fecha).get()).data();
    final estados = data?['estados'];
    if (estados == null) return null;
    if (estados is! Map) {
      throw const FormatException('Registro de asistencia inválido');
    }
    return estados.map((id, estado) => MapEntry(id.toString(), estado));
  }

  /// Guarda una sesión completa y valida asignación y matrícula en transacción.
  static Future<AuthResponse> guardarAsistenciaSesion({
    required String deporteId,
    required DateTime fecha,
    required String entrenadorUid,
    required Map<String, String> estados,
  }) async {
    try {
      if (estados.isEmpty || estados.length > 450) {
        throw StateError('Nómina vacía o demasiado grande');
      }
      final hoy = DateTime.now();
      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      if (dia.isAfter(DateTime(hoy.year, hoy.month, hoy.day))) {
        throw StateError('No se puede registrar asistencia futura');
      }

      await _db.runTransaction((tx) async {
        final deporte = await tx.get(
          _db.collection(deportesCollection).doc(deporteId),
        );
        if (deporte.data()?['entrenadorUid'] != entrenadorUid ||
            deporte.data()?['activo'] != true) {
          throw StateError('Disciplina no asignada');
        }

        // Firestore exige completar todas las lecturas antes de escribir.
        for (final id in estados.keys) {
          final inscripcion = await tx.get(
            _db.collection(inscripcionesCollection).doc(id),
          );
          if (inscripcion.data()?['deporteId'] != deporteId ||
              inscripcion.data()?['estado'] != 'confirmada') {
            throw StateError('La nómina cambió. Actualiza antes de guardar');
          }
        }

        tx.set(_sesionAsistencia(deporteId, fecha), {
          'fecha': _claveFecha(fecha),
          'entrenadorUid': entrenadorUid,
          'estados': estados,
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      });
      return AuthResponse(isSuccess: true);
    } on FirebaseException catch (e) {
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } on StateError catch (e) {
      return AuthResponse(errorMessage: e.message.toString(), isSuccess: false);
    } catch (_) {
      return AuthResponse(
        errorMessage: 'No se pudo guardar la asistencia. Intenta nuevamente.',
        isSuccess: false,
      );
    }
  }

  /// Todas las sesiones guardadas de una disciplina, con su ID de fecha.
  static Future<List<Map<String, dynamic>>> getAsistenciasDisciplina({
    required String deporteId,
  }) async {
    final snapshot = await _db
        .collection(deportesCollection)
        .doc(deporteId)
        .collection(asistenciasCollection)
        .get();
    return snapshot.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
  }

  /// Perfil del entrenador autenticado. Une su ficha pública con los datos de
  /// cuenta que solo necesita ver el propio usuario (correo y teléfono).
  static Future<Map<String, dynamic>?> getPerfilEntrenador({
    required String uid,
  }) async {
    final actual = _auth.currentUser?.uid;
    if (actual == null || actual != uid) {
      throw StateError('Sesión de entrenador requerida');
    }
    final documentos = await Future.wait([
      _db.collection(entrenadoresCollection).doc(uid).get(),
      _db.collection(usuariosCollection).doc(uid).get(),
    ]);
    final publico = documentos[0].data();
    if (publico == null) return null;
    return <String, dynamic>{...?documentos[1].data(), ...publico};
  }

  /// Solicitudes creadas por un entrenador. El filtro por UID evita exponer
  /// solicitudes de otros entrenadores y el orden se aplica en el controlador.
  static Stream<List<Map<String, dynamic>>> streamEventosEntrenador({
    required String uid,
  }) {
    final actual = _auth.currentUser?.uid;
    if (actual == null || actual != uid) {
      return Stream.error(StateError('Sesión de entrenador requerida'));
    }
    return _streamConsultaEntrenador(
      _db.collection(eventosCollection).where('creadoPorUid', isEqualTo: uid),
    );
  }

  /// Registra una solicitud pendiente; aprobarla y reservar la cancha sigue
  /// siendo responsabilidad exclusiva del flujo de administración.
  static Future<AuthResponse> solicitarEventoEntrenador({
    required String entrenadorUid,
    required Map<String, dynamic> datos,
  }) async {
    try {
      final actual = _auth.currentUser?.uid;
      if (actual == null || actual != entrenadorUid) {
        throw StateError('Sesión de entrenador requerida');
      }
      final deporteId = '${datos['deporteId'] ?? ''}'.trim();
      if (deporteId.isEmpty) throw StateError('Elige una disciplina.');
      final canchaId = '${datos['canchaId'] ?? ''}'.trim();
      if (canchaId.isEmpty) throw StateError('Elige una cancha.');

      final documentos = await Future.wait([
        _db.collection(deportesCollection).doc(deporteId).get(),
        _db.collection(canchasCollection).doc(canchaId).get(),
      ]);
      final deporte = documentos[0];
      final cancha = documentos[1];
      final deporteDatos = deporte.data() ?? const <String, dynamic>{};
      final solicitud = construirSolicitudEventoEntrenador(
        datos: datos,
        entrenadorUid: entrenadorUid,
        deporte: {'id': deporte.id, ...deporteDatos},
        cancha: {'id': cancha.id, ...?cancha.data()},
        reservasCancha: await _ocupadas(canchaId),
        ahora: DateTime.now(),
      );
      await _db.collection(eventosCollection).add({
        ...solicitud,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      return AuthResponse(isSuccess: true);
    } on FirebaseException catch (e) {
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } on StateError catch (e) {
      return AuthResponse(errorMessage: e.message.toString(), isSuccess: false);
    } catch (_) {
      return AuthResponse(
        errorMessage: 'No se pudo solicitar el evento. Intenta nuevamente.',
        isSuccess: false,
      );
    }
  }

  static DocumentReference<Map<String, dynamic>> _sesionAsistencia(
    String deporteId,
    DateTime fecha,
  ) => _db
      .collection(deportesCollection)
      .doc(deporteId)
      .collection(asistenciasCollection)
      .doc(_claveFecha(fecha));

  static String _claveFecha(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Funciones agregadas por Gonzalo (panel del estudiante: Comunidad)
  // ---------------------------------------------------------------------------

  /// Reseñas de un estudiante, en vivo y de la más nueva a la más vieja.
  /// Necesita el índice compuesto resenas: autorUid ↑ + fecha ↓.
  /// La usa ComunidadController.
  static Stream<List<Map<String, dynamic>>> streamMisResenas({
    required String uid,
  }) {
    return _streamConsulta(
      _db
          .collection(resenasCollection)
          .where('autorUid', isEqualTo: uid)
          .orderBy('fecha', descending: true),
    );
  }

  /// Crea una reseña en resenas/{id} con la fecha del servidor y visible.
  /// La usa ComunidadController.
  static Future<AuthResponse> crearResena({
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(resenasCollection).add({
        ...data,
        'fecha': FieldValue.serverTimestamp(),
        'visible': true,
      });
      return AuthResponse(isSuccess: true);
    } on FirebaseException catch (e) {
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } catch (_) {
      return AuthResponse(
        errorMessage: 'No se pudo publicar la reseña. Intenta nuevamente.',
        isSuccess: false,
      );
    }
  }

  /// Cambia las estrellas y el comentario de una reseña propia.
  /// La usa ComunidadController.
  static Future<AuthResponse> actualizarResena({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(resenasCollection).doc(id).update(data);
      return AuthResponse(isSuccess: true);
    } on FirebaseException catch (e) {
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } catch (_) {
      return AuthResponse(
        errorMessage: 'No se pudo actualizar la reseña. Intenta nuevamente.',
        isSuccess: false,
      );
    }
  }

  /// Elimina una reseña propia. La usa ComunidadController.
  static Future<AuthResponse> eliminarResena({required String id}) async {
    try {
      await _db.collection(resenasCollection).doc(id).delete();
      return AuthResponse(isSuccess: true);
    } on FirebaseException catch (e) {
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } catch (_) {
      return AuthResponse(
        errorMessage: 'No se pudo eliminar la reseña. Intenta nuevamente.',
        isSuccess: false,
      );
    }
  }

  // ===== ADMINISTRADOR (Andrés): canchas, reservas y deportes =====

  static Stream<List<Map<String, dynamic>>> streamCanchas() {
    return _streamConsulta(_db.collection(canchasCollection).orderBy('nombre'));
  }

  static Future<AuthResponse> crearCancha({
    required Map<String, dynamic> datos,
  }) {
    return _ejecutarAdmin(() async {
      final nombre = '${datos['nombre'] ?? ''}'.trim();
      if (nombre.isEmpty) {
        throw StateError('El nombre de la cancha es obligatorio.');
      }
      final existentes = await _db
          .collection(canchasCollection)
          .where('nombre', isEqualTo: nombre)
          .limit(1)
          .get();
      if (existentes.docs.isNotEmpty) {
        throw StateError('Ya existe una cancha con ese nombre.');
      }
      await _db.collection(canchasCollection).add({
        ...datos,
        'nombre': nombre,
        'activa': true,
        'version': 0,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      await registrarTransaccion(
        accion: 'crear',
        modulo: 'canchas',
        descripcion: 'Creó la cancha $nombre',
      );
    });
  }

  static Future<AuthResponse> actualizarCancha({
    required String id,
    required Map<String, dynamic> datos,
  }) {
    return _ejecutarAdmin(() async {
      final cambios = <String, dynamic>{};
      for (final clave in ['nombre', 'ubicacion', 'descripcion', 'activa']) {
        if (datos.containsKey(clave)) cambios[clave] = datos[clave];
      }
      if (cambios.isEmpty) {
        throw StateError('No hay datos para actualizar la cancha.');
      }
      if (cambios['activa'] == false) {
        final reservadas = await _db
            .collection(reservasCollection)
            .where('canchaId', isEqualTo: id)
            .where('activa', isEqualTo: true)
            .limit(1)
            .get();
        if (reservadas.docs.isNotEmpty) {
          throw StateError(
            'La cancha tiene horarios reservados; libéralos primero',
          );
        }
      }
      await _db.collection(canchasCollection).doc(id).update(cambios);
      await registrarTransaccion(
        accion: 'actualizar',
        modulo: 'canchas',
        descripcion: 'Actualizó la cancha $id',
      );
    });
  }

  /// Requiere índice compuesto canchaId + activa + dia + horaInicio.
  static Stream<List<Map<String, dynamic>>> streamReservasCancha(
    String canchaId,
  ) {
    return _streamConsulta(
      _db
          .collection(reservasCollection)
          .where('canchaId', isEqualTo: canchaId)
          .where('activa', isEqualTo: true)
          .orderBy('dia')
          .orderBy('horaInicio'),
    );
  }

  static Future<Map<String, dynamic>?> hayChoqueHorario({
    required String canchaId,
    required List<Map<String, dynamic>> franjas,
    String? fecha,
    String? ignorarRefId,
  }) async {
    final snapshot = await _db
        .collection(reservasCollection)
        .where('canchaId', isEqualTo: canchaId)
        .where('activa', isEqualTo: true)
        .get();
    final existentes = snapshot.docs
        .map((doc) => ReservaHorario.fromMap(doc.id, doc.data()))
        .toList();
    final nuevas = franjas.map((franja) {
      final modelo = FranjaHorario.fromMap(franja);
      return ReservaHorario(
        id: '',
        canchaId: canchaId,
        canchaNombre: '',
        dia: modelo.dia,
        horaInicio: modelo.horaInicio,
        horaFin: modelo.horaFin,
        fecha: fecha,
        tipo: fecha == null ? TipoReserva.deporte : TipoReserva.evento,
        refId: '',
        refNombre: '',
        activa: true,
      );
    }).toList();
    final choque = buscarChoque(
      nuevas: nuevas,
      existentes: existentes,
      ignorarRefId: ignorarRefId,
    );
    if (choque == null) return null;
    return {'id': choque.id, ...choque.toMap()};
  }

  static Stream<List<Map<String, dynamic>>> streamDeportesAdmin() {
    return _streamConsulta(
      _db.collection(deportesCollection).orderBy('nombre'),
    );
  }

  static Future<AuthResponse> crearDeporte({
    required Map<String, dynamic> datos,
    required String canchaId,
    required List<Map<String, dynamic>> franjas,
  }) {
    return _ejecutarAdmin(() async {
      final nombre = '${datos['nombre'] ?? ''}'.trim();
      if (nombre.isEmpty) {
        throw StateError('El nombre del deporte es obligatorio.');
      }
      final cupos = _enteroAdmin(datos['cupos']);
      if (cupos <= 0) {
        throw StateError('Los cupos deben ser mayores que cero.');
      }
      final modelo = _validarFranjas(franjas);
      final canchaRef = _db.collection(canchasCollection).doc(canchaId);
      final deporteRef = _db.collection(deportesCollection).doc();
      await _db.runTransaction((tx) async {
        final cancha = await tx.get(canchaRef);
        if (!cancha.exists || cancha.data()?['activa'] != true) {
          throw StateError('La cancha no existe o está inactiva');
        }
        final canchaNombre = '${cancha.data()?['nombre'] ?? ''}';
        final ocupadas = await _db
            .collection(reservasCollection)
            .where('canchaId', isEqualTo: canchaId)
            .where('activa', isEqualTo: true)
            .get();
        final existentes = ocupadas.docs
            .map((doc) => ReservaHorario.fromMap(doc.id, doc.data()))
            .toList();
        final nuevas = _reservasDe(
          franjas: modelo,
          canchaId: canchaId,
          canchaNombre: canchaNombre,
          refId: deporteRef.id,
          refNombre: nombre,
        );
        final choque = buscarChoque(nuevas: nuevas, existentes: existentes);
        if (choque != null) throw StateError(mensajeChoque(choque));

        tx.set(deporteRef, {
          ...datos,
          'nombre': nombre,
          'cupos': cupos,
          'canchaId': canchaId,
          'canchaNombre': canchaNombre,
          'horarios': franjas,
          'horario': textoHorario(modelo, cancha: canchaNombre),
          'inscritos': 0,
          'activo': true,
          'creadoEn': FieldValue.serverTimestamp(),
        });
        for (final reserva in nuevas) {
          tx.set(_db.collection(reservasCollection).doc(), {
            ...reserva.toMap(),
            'creadoEn': FieldValue.serverTimestamp(),
          });
        }
        // Las transacciones del SDK cliente no bloquean consultas, solo
        // documentos leídos con tx.get. Como TODA escritura de reservas de
        // esta cancha actualiza canchas/{id}.version, dos administradores que
        // reservan a la vez chocan en ese documento: Firestore reintenta el
        // callback de uno de ellos, que vuelve a consultar las reservas y
        // detecta el choque.
        tx.update(canchaRef, {'version': FieldValue.increment(1)});
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: 'crear',
            modulo: 'deportes',
            descripcion: 'Creó el deporte $nombre',
          ),
        );
      });
    });
  }

  static Future<AuthResponse> actualizarDeporte({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    List<Map<String, dynamic>>? franjas,
  }) {
    return _ejecutarAdmin(() async {
      final deporteRef = _db.collection(deportesCollection).doc(id);
      await _db.runTransaction((tx) async {
        final deporte = await tx.get(deporteRef);
        if (!deporte.exists) throw StateError('El deporte no existe.');
        final actual = deporte.data() ?? {};
        final inscritos = _enteroAdmin(actual['inscritos']);
        final cuposNuevos = datos.containsKey('cupos')
            ? _enteroAdmin(datos['cupos'])
            : _enteroAdmin(actual['cupos']);
        if (cuposNuevos < inscritos) {
          throw StateError(
            'No puedes dejar menos cupos que inscritos ($inscritos)',
          );
        }
        final canchaActual = '${actual['canchaId'] ?? ''}';
        final canchaNueva = canchaId ?? canchaActual;
        final cambiaCancha = canchaId != null && canchaId != canchaActual;
        final cambiaFranjas = franjas != null;
        final nombreActual = '${actual['nombre'] ?? ''}';
        final nombreNuevo = datos.containsKey('nombre')
            ? '${datos['nombre']}'.trim()
            : nombreActual;
        if (datos.containsKey('nombre') && nombreNuevo.isEmpty) {
          throw StateError('El nombre del deporte es obligatorio.');
        }
        final cambiaNombre = nombreNuevo != nombreActual;
        final activo = actual['activo'] == true;

        DocumentSnapshot<Map<String, dynamic>>? canchaVieja;
        DocumentSnapshot<Map<String, dynamic>>? canchaDestino;
        QuerySnapshot<Map<String, dynamic>>? reservasDeporte;
        var modelo = <FranjaHorario>[];
        var canchaNombre = '${actual['canchaNombre'] ?? ''}';

        if (cambiaCancha || cambiaFranjas) {
          if (canchaNueva.isEmpty) {
            throw StateError('La cancha no existe o está inactiva');
          }
          if (canchaActual.isNotEmpty) {
            canchaVieja = await tx.get(
              _db.collection(canchasCollection).doc(canchaActual),
            );
          }
          canchaDestino = await tx.get(
            _db.collection(canchasCollection).doc(canchaNueva),
          );
          if (!canchaDestino.exists ||
              canchaDestino.data()?['activa'] != true) {
            throw StateError('La cancha no existe o está inactiva');
          }
          canchaNombre = '${canchaDestino.data()?['nombre'] ?? ''}';
          final mapas = franjas ?? _mapas(actual['horarios']);
          modelo = _validarFranjas(mapas);
          final ocupadas = await _db
              .collection(reservasCollection)
              .where('canchaId', isEqualTo: canchaNueva)
              .where('activa', isEqualTo: true)
              .get();
          final choque = buscarChoque(
            nuevas: _reservasDe(
              franjas: modelo,
              canchaId: canchaNueva,
              canchaNombre: canchaNombre,
              refId: id,
              refNombre: nombreNuevo,
            ),
            existentes: ocupadas.docs
                .map((doc) => ReservaHorario.fromMap(doc.id, doc.data()))
                .toList(),
            ignorarRefId: id,
          );
          if (choque != null) throw StateError(mensajeChoque(choque));
          reservasDeporte = await _db
              .collection(reservasCollection)
              .where('refId', isEqualTo: id)
              .where('tipo', isEqualTo: TipoReserva.deporte.valor)
              .get();
        } else if (cambiaNombre) {
          reservasDeporte = await _db
              .collection(reservasCollection)
              .where('refId', isEqualTo: id)
              .where('tipo', isEqualTo: TipoReserva.deporte.valor)
              .get();
        }

        final cambios = Map<String, dynamic>.from(datos)
          ..remove('inscritos')
          ..remove('version')
          ..remove('id');
        cambios['cupos'] = cuposNuevos;
        if (datos.containsKey('nombre')) cambios['nombre'] = nombreNuevo;
        if (cambiaCancha || cambiaFranjas) {
          cambios['canchaId'] = canchaNueva;
          cambios['canchaNombre'] = canchaNombre;
          cambios['horarios'] = franjas ?? actual['horarios'];
          cambios['horario'] = textoHorario(modelo, cancha: canchaNombre);
          for (final doc in reservasDeporte!.docs) {
            tx.delete(doc.reference);
          }
          if (activo) {
            for (final reserva in _reservasDe(
              franjas: modelo,
              canchaId: canchaNueva,
              canchaNombre: canchaNombre,
              refId: id,
              refNombre: nombreNuevo,
            )) {
              tx.set(_db.collection(reservasCollection).doc(), {
                ...reserva.toMap(),
                'creadoEn': FieldValue.serverTimestamp(),
              });
            }
          }
          tx.update(canchaDestino!.reference, {
            'version': FieldValue.increment(1),
          });
          if (cambiaCancha &&
              canchaVieja != null &&
              canchaVieja.exists &&
              canchaVieja.id != canchaDestino.id) {
            tx.update(canchaVieja.reference, {
              'version': FieldValue.increment(1),
            });
          }
        } else if (cambiaNombre) {
          for (final doc in reservasDeporte!.docs) {
            tx.update(doc.reference, {'refNombre': nombreNuevo});
          }
        }
        tx.update(deporteRef, cambios);
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: 'actualizar',
            modulo: 'deportes',
            descripcion: 'Actualizó el deporte $nombreNuevo',
          ),
        );
      });
    });
  }

  static Future<AuthResponse> cambiarEstadoDeporte({
    required String id,
    required bool activo,
  }) {
    return _ejecutarAdmin(() async {
      final deporteRef = _db.collection(deportesCollection).doc(id);
      await _db.runTransaction((tx) async {
        final deporte = await tx.get(deporteRef);
        if (!deporte.exists) throw StateError('El deporte no existe.');
        final actual = deporte.data() ?? {};
        final inscritos = _enteroAdmin(actual['inscritos']);
        final canchaId = '${actual['canchaId'] ?? ''}';
        final canchaRef = canchaId.isEmpty
            ? null
            : _db.collection(canchasCollection).doc(canchaId);
        final cancha = canchaRef == null ? null : await tx.get(canchaRef);
        final propias = await _db
            .collection(reservasCollection)
            .where('refId', isEqualTo: id)
            .where('tipo', isEqualTo: TipoReserva.deporte.valor)
            .get();
        if (!activo && inscritos > 0) {
          throw StateError(
            'Tiene $inscritos inscritos; cancela sus inscripciones antes de desactivarlo',
          );
        }
        if (activo) {
          if (cancha == null ||
              !cancha.exists ||
              cancha.data()?['activa'] != true) {
            throw StateError('La cancha no existe o está inactiva');
          }
          final ocupadas = await _db
              .collection(reservasCollection)
              .where('canchaId', isEqualTo: canchaId)
              .where('activa', isEqualTo: true)
              .get();
          final modelo = _validarFranjas(_mapas(actual['horarios']));
          final canchaNombre =
              '${actual['canchaNombre'] ?? cancha.data()?['nombre'] ?? ''}';
          final choque = buscarChoque(
            nuevas: _reservasDe(
              franjas: modelo,
              canchaId: canchaId,
              canchaNombre: canchaNombre,
              refId: id,
              refNombre: '${actual['nombre'] ?? ''}',
            ),
            existentes: ocupadas.docs
                .map((doc) => ReservaHorario.fromMap(doc.id, doc.data()))
                .toList(),
            ignorarRefId: id,
          );
          if (choque != null) throw StateError(mensajeChoque(choque));
        }

        tx.update(deporteRef, {'activo': activo});
        if (propias.docs.isEmpty && activo) {
          final modelo = _validarFranjas(_mapas(actual['horarios']));
          final canchaNombre =
              '${actual['canchaNombre'] ?? cancha?.data()?['nombre'] ?? ''}';
          for (final reserva in _reservasDe(
            franjas: modelo,
            canchaId: canchaId,
            canchaNombre: canchaNombre,
            refId: id,
            refNombre: '${actual['nombre'] ?? ''}',
          )) {
            tx.set(_db.collection(reservasCollection).doc(), {
              ...reserva.toMap(),
              'creadoEn': FieldValue.serverTimestamp(),
            });
          }
        } else {
          for (final doc in propias.docs) {
            tx.update(doc.reference, {'activa': activo});
          }
        }
        if (cancha != null && cancha.exists) {
          tx.update(cancha.reference, {'version': FieldValue.increment(1)});
        }
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: activo ? 'activar' : 'desactivar',
            modulo: 'deportes',
            descripcion:
                '${activo ? 'Activó' : 'Desactivó'} el deporte ${actual['nombre'] ?? id}',
          ),
        );
      });
    });
  }

  static Future<AuthResponse> asignarEntrenadorDisciplina({
    required String deporteId,
    required String entrenadorUid,
    required String entrenadorNombre,
  }) {
    return _ejecutarAdmin(() async {
      final deporteRef = _db.collection(deportesCollection).doc(deporteId);
      await _db.runTransaction((tx) async {
        final deporte = await tx.get(deporteRef);
        if (!deporte.exists) throw StateError('El deporte no existe.');
        if (entrenadorUid.isNotEmpty) {
          final entrenador = await tx.get(
            _db.collection(entrenadoresCollection).doc(entrenadorUid),
          );
          if (!entrenador.exists || entrenador.data()?['activo'] != true) {
            throw StateError('El entrenador no existe o está inactivo.');
          }
        }
        tx.update(deporteRef, {
          'entrenadorUid': entrenadorUid,
          'entrenadorNombre': entrenadorUid.isEmpty ? '' : entrenadorNombre,
        });
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: entrenadorUid.isEmpty ? 'desasignar' : 'asignar',
            modulo: 'entrenadores',
            descripcion: entrenadorUid.isEmpty
                ? 'Desasignó el entrenador del deporte $deporteId'
                : 'Asignó a $entrenadorNombre al deporte $deporteId',
          ),
        );
      });
    });
  }

  static Future<void> registrarTransaccion({
    required String accion,
    required String modulo,
    required String descripcion,
  }) async {
    await _db
        .collection(transaccionesCollection)
        .add(
          _datosTransaccion(
            accion: accion,
            modulo: modulo,
            descripcion: descripcion,
          ),
        );
  }

  static Map<String, dynamic> _datosTransaccion({
    required String accion,
    required String modulo,
    required String descripcion,
  }) {
    return {
      'fecha': FieldValue.serverTimestamp(),
      'usuarioUid': _auth.currentUser?.uid ?? '',
      'rol': 'administrador',
      'usuarioNombre': _auth.currentUser?.email ?? '',
      'accion': accion,
      'modulo': modulo,
      'descripcion': descripcion,
    };
  }

  static Future<AuthResponse> _ejecutarAdmin(
    Future<void> Function() accion,
  ) async {
    try {
      await accion();
      return AuthResponse(isSuccess: true);
    } on FirebaseException catch (e) {
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } on StateError catch (e) {
      return AuthResponse(errorMessage: e.message, isSuccess: false);
    } catch (_) {
      return AuthResponse(
        errorMessage: AppStrings.errorInesperado,
        isSuccess: false,
      );
    }
  }

  static List<FranjaHorario> _validarFranjas(
    List<Map<String, dynamic>> franjas,
  ) {
    if (franjas.isEmpty) {
      throw StateError('Agrega al menos un horario.');
    }
    final modelo = franjas.map(FranjaHorario.fromMap).toList();
    for (final franja in modelo) {
      final error = validarFranja(franja);
      if (error != null) throw StateError(error);
    }
    return modelo;
  }

  static List<Map<String, dynamic>> _mapas(dynamic valor) {
    if (valor is! List) return const [];
    return valor.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  static List<ReservaHorario> _reservasDe({
    required List<FranjaHorario> franjas,
    required String canchaId,
    required String canchaNombre,
    required String refId,
    required String refNombre,
  }) {
    return franjas
        .map(
          (franja) => ReservaHorario(
            id: '',
            canchaId: canchaId,
            canchaNombre: canchaNombre,
            dia: franja.dia,
            horaInicio: franja.horaInicio,
            horaFin: franja.horaFin,
            tipo: TipoReserva.deporte,
            refId: refId,
            refNombre: refNombre,
            activa: true,
          ),
        )
        .toList();
  }

  static int _enteroAdmin(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse('$valor') ?? 0;
  }

  // ===== ADMINISTRADOR (Andrés): entrenadores =====
  //
  // createUserWithEmailAndPassword en la instancia por defecto INICIA SESIÓN
  // con el usuario nuevo y reemplaza la sesión del administrador. authStateChanges
  // dispara, GuardiaRol ve rol 'entrenador' y saca al admin del panel. Con una
  // app secundaria la cuenta nueva se crea en otra instancia de Auth y la sesión
  // del admin no se toca. El Admin SDK no se puede usar desde Flutter web.

  static const String _appCuentas = 'crearCuentasAdmin';

  static Future<FirebaseAuth> _authSecundaria() async {
    final FirebaseApp app = Firebase.apps.any((a) => a.name == _appCuentas)
        ? Firebase.app(_appCuentas)
        : await Firebase.initializeApp(
            name: _appCuentas,
            options: Firebase.app().options,
          );
    final auth = FirebaseAuth.instanceFor(app: app);
    if (kIsWeb) await auth.setPersistence(Persistence.NONE);
    return auth;
  }

  static Future<AuthResponse> crearCuentaEntrenador({
    required String correo,
    required String clave,
    required Map<String, dynamic> privado,
    required Map<String, dynamic> publico,
  }) async {
    FirebaseAuth? authSec;
    UserCredential? credencial;
    try {
      authSec = await _authSecundaria();
      credencial = await authSec.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: clave,
      );
      final uid = credencial.user?.uid;
      if (uid == null) {
        throw StateError('No se pudo crear la cuenta del entrenador.');
      }
      final batch = _db.batch();
      batch.set(_db.collection(usuariosCollection).doc(uid), {
        ..._sinClave(privado),
        'correo': correo.trim(),
        'rol': 'entrenador',
        'estado': 'activo',
        'creadoEn': FieldValue.serverTimestamp(),
      });
      batch.set(_db.collection(entrenadoresCollection).doc(uid), {
        ..._perfilPublico(publico),
        'activo': true,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      batch.set(
        _db.collection(transaccionesCollection).doc(),
        _datosTransaccion(
          accion: 'crear',
          modulo: 'entrenadores',
          descripcion:
              'Creó la cuenta del entrenador ${publico['nombre'] ?? ''} ${publico['apellido'] ?? ''}'
                  .trim(),
        ),
      );
      try {
        await batch.commit();
      } catch (error) {
        try {
          await credencial.user?.delete();
        } catch (_) {}
        rethrow;
      }
      return AuthResponse(isSuccess: true, credential: null);
    } on FirebaseAuthException catch (e) {
      return AuthResponse(errorMessage: _authErrorMessage(e), isSuccess: false);
    } on FirebaseException catch (e) {
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } on StateError catch (e) {
      return AuthResponse(errorMessage: e.message, isSuccess: false);
    } catch (_) {
      return AuthResponse(
        errorMessage: AppStrings.errorInesperado,
        isSuccess: false,
      );
    } finally {
      await authSec?.signOut();
    }
  }

  static Stream<List<Map<String, dynamic>>> streamEntrenadoresAdmin() {
    return _streamConsulta(
      _db.collection(entrenadoresCollection).orderBy('nombre'),
    );
  }

  static Stream<List<Map<String, dynamic>>> streamPerfilesEntrenadoresAdmin() {
    return _streamConsulta(
      _db.collection(usuariosCollection).where('rol', isEqualTo: 'entrenador'),
    );
  }

  static Future<AuthResponse> actualizarEntrenador({
    required String uid,
    required Map<String, dynamic> publico,
    required Map<String, dynamic> privado,
  }) {
    return _ejecutarAdmin(() async {
      final perfil = await _db
          .collection(entrenadoresCollection)
          .doc(uid)
          .get();
      if (!perfil.exists) throw StateError('El entrenador no existe.');
      final actual = perfil.data() ?? {};
      final nombreNuevo = publico.containsKey('nombre')
          ? '${publico['nombre']}'.trim()
          : '${actual['nombre'] ?? ''}';
      final apellidoNuevo = publico.containsKey('apellido')
          ? '${publico['apellido']}'.trim()
          : '${actual['apellido'] ?? ''}';
      final cambiaNombre =
          nombreNuevo != '${actual['nombre'] ?? ''}' ||
          apellidoNuevo != '${actual['apellido'] ?? ''}';
      final publicoLimpio = _perfilPublico(publico);
      final batch = _db.batch();
      if (publicoLimpio.isNotEmpty) {
        batch.update(
          _db.collection(entrenadoresCollection).doc(uid),
          publicoLimpio,
        );
      }
      final cambiosPrivados = <String, dynamic>{};
      for (final clave in ['nombre', 'apellido', 'telefono']) {
        if (privado.containsKey(clave)) cambiosPrivados[clave] = privado[clave];
      }
      if (cambiosPrivados.isNotEmpty) {
        batch.update(
          _db.collection(usuariosCollection).doc(uid),
          cambiosPrivados,
        );
      }
      if (cambiaNombre) {
        final asignados = await _db
            .collection(deportesCollection)
            .where('entrenadorUid', isEqualTo: uid)
            .get();
        final visible = '$nombreNuevo $apellidoNuevo'.trim();
        for (final doc in asignados.docs) {
          batch.update(doc.reference, {'entrenadorNombre': visible});
        }
      }
      batch.set(
        _db.collection(transaccionesCollection).doc(),
        _datosTransaccion(
          accion: 'actualizar',
          modulo: 'entrenadores',
          descripcion: 'Actualizó al entrenador $nombreNuevo $apellidoNuevo',
        ),
      );
      await batch.commit();
    });
  }

  /// La cuenta de Auth sigue habilitada. Deshabilitarla requiere Admin SDK
  /// (Cloud Function, tarea de Giancarlo). AuthController no revisa `estado`
  /// al iniciar sesión: queda pendiente fuera de este módulo.
  static Future<AuthResponse> cambiarEstadoEntrenador({
    required String uid,
    required bool activo,
  }) {
    return _ejecutarAdmin(() async {
      if (!activo) {
        final asignados = await _db
            .collection(deportesCollection)
            .where('entrenadorUid', isEqualTo: uid)
            .get();
        final activos = asignados.docs
            .where((doc) => doc.data()['activo'] == true)
            .toList();
        if (activos.isNotEmpty) {
          final nombres = activos
              .map((doc) => '${doc.data()['nombre'] ?? doc.id}')
              .join(', ');
          throw StateError(
            'Reasigna sus disciplinas ($nombres) antes de desactivarlo',
          );
        }
      }
      final batch = _db.batch();
      batch.update(_db.collection(entrenadoresCollection).doc(uid), {
        'activo': activo,
      });
      batch.update(_db.collection(usuariosCollection).doc(uid), {
        'estado': activo ? 'activo' : 'inactivo',
      });
      batch.set(
        _db.collection(transaccionesCollection).doc(),
        _datosTransaccion(
          accion: activo ? 'activar' : 'desactivar',
          modulo: 'entrenadores',
          descripcion: '${activo ? 'Activó' : 'Desactivó'} al entrenador $uid',
        ),
      );
      await batch.commit();
    });
  }

  static Map<String, dynamic> _perfilPublico(Map<String, dynamic> publico) {
    return Map<String, dynamic>.from(publico)
      ..remove('cedula')
      ..remove('correo')
      ..remove('telefono')
      ..remove('clave')
      ..remove('password');
  }

  static Map<String, dynamic> _sinClave(Map<String, dynamic> datos) {
    return Map<String, dynamic>.from(datos)
      ..remove('clave')
      ..remove('password');
  }

  // ===== ADMINISTRADOR (Andrés): eventos, estudiantes, reseñas, inscripciones =====

  static Stream<List<Map<String, dynamic>>> streamEventos() {
    return _streamConsulta(
      _db.collection(eventosCollection).orderBy('fecha', descending: true),
    );
  }

  static Future<AuthResponse> crearEvento({
    required Map<String, dynamic> datos,
    required String canchaId,
    required String fecha,
    required int horaInicio,
    required int horaFin,
  }) {
    return _ejecutarAdmin(() async {
      final titulo = '${datos['titulo'] ?? ''}'.trim();
      if (titulo.isEmpty) {
        throw StateError('El título del evento es obligatorio.');
      }
      _validarFechaEvento(fecha);
      final dia = DateTime.parse(fecha).weekday;
      final error = validarFranja(
        FranjaHorario(dia: dia, horaInicio: horaInicio, horaFin: horaFin),
      );
      if (error != null) throw StateError(error);
      final canchaRef = _db.collection(canchasCollection).doc(canchaId);
      final eventoRef = _db.collection(eventosCollection).doc();
      await _db.runTransaction((tx) async {
        final cancha = await tx.get(canchaRef);
        if (!cancha.exists || cancha.data()?['activa'] != true) {
          throw StateError('La cancha no existe o está inactiva');
        }
        final canchaNombre = '${cancha.data()?['nombre'] ?? ''}';
        final existentes = await _ocupadas(canchaId);
        final nueva = _reservaEvento(
          canchaId: canchaId,
          canchaNombre: canchaNombre,
          fecha: fecha,
          horaInicio: horaInicio,
          horaFin: horaFin,
          refId: eventoRef.id,
          refNombre: titulo,
        );
        _exigirSinChoque(existentes, nueva);
        tx.set(eventoRef, {
          ...datos,
          'titulo': titulo,
          'canchaId': canchaId,
          'canchaNombre': canchaNombre,
          'fecha': fecha,
          'horaInicio': horaInicio,
          'horaFin': horaFin,
          'estado': 'aprobado',
          'creadoPorUid': _auth.currentUser?.uid ?? '',
          'creadoEn': FieldValue.serverTimestamp(),
        });
        tx.set(_db.collection(reservasCollection).doc(), {
          ...nueva.toMap(),
          'creadoEn': FieldValue.serverTimestamp(),
        });
        tx.update(canchaRef, {'version': FieldValue.increment(1)});
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: 'crear',
            modulo: 'eventos',
            descripcion: 'Creó el evento $titulo',
          ),
        );
      });
    });
  }

  static Future<AuthResponse> actualizarEvento({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    String? fecha,
    int? horaInicio,
    int? horaFin,
  }) {
    return _ejecutarAdmin(() async {
      final eventoRef = _db.collection(eventosCollection).doc(id);
      await _db.runTransaction((tx) async {
        final evento = await tx.get(eventoRef);
        if (!evento.exists) throw StateError('El evento no existe.');
        final actual = evento.data() ?? {};
        final titulo = datos.containsKey('titulo')
            ? '${datos['titulo']}'.trim()
            : '${actual['titulo'] ?? ''}';
        if (datos.containsKey('titulo') && titulo.isEmpty) {
          throw StateError('El título del evento es obligatorio.');
        }
        final canchaNueva = canchaId ?? '${actual['canchaId'] ?? ''}';
        final fechaNueva = fecha ?? '${actual['fecha'] ?? ''}';
        final inicioNuevo = horaInicio ?? _enteroAdmin(actual['horaInicio']);
        final finNuevo = horaFin ?? _enteroAdmin(actual['horaFin']);
        final cambiaHorario =
            canchaId != null ||
            fecha != null ||
            horaInicio != null ||
            horaFin != null;
        final estado = '${actual['estado'] ?? ''}';
        DocumentSnapshot<Map<String, dynamic>>? cancha;
        QuerySnapshot<Map<String, dynamic>>? reservas;
        var canchaNombre = '${actual['canchaNombre'] ?? ''}';
        if (cambiaHorario) {
          if (fecha != null) _validarFechaEvento(fechaNueva);
          final error = validarFranja(
            FranjaHorario(
              dia: DateTime.parse(fechaNueva).weekday,
              horaInicio: inicioNuevo,
              horaFin: finNuevo,
            ),
          );
          if (error != null) throw StateError(error);
          cancha = await tx.get(
            _db.collection(canchasCollection).doc(canchaNueva),
          );
          if (!cancha.exists || cancha.data()?['activa'] != true) {
            throw StateError('La cancha no existe o está inactiva');
          }
          canchaNombre = '${cancha.data()?['nombre'] ?? ''}';
          if (estado == 'aprobado') {
            _exigirSinChoque(
              await _ocupadas(canchaNueva),
              _reservaEvento(
                canchaId: canchaNueva,
                canchaNombre: canchaNombre,
                fecha: fechaNueva,
                horaInicio: inicioNuevo,
                horaFin: finNuevo,
                refId: id,
                refNombre: titulo,
              ),
              ignorarRefId: id,
            );
          }
          reservas = await _reservasDelEvento(id);
        } else if (titulo != '${actual['titulo'] ?? ''}') {
          reservas = await _reservasDelEvento(id);
        }

        final cambios = Map<String, dynamic>.from(datos)
          ..remove('estado')
          ..remove('id');
        if (datos.containsKey('titulo')) cambios['titulo'] = titulo;
        if (cambiaHorario) {
          cambios['canchaId'] = canchaNueva;
          cambios['canchaNombre'] = canchaNombre;
          cambios['fecha'] = fechaNueva;
          cambios['horaInicio'] = inicioNuevo;
          cambios['horaFin'] = finNuevo;
          for (final doc in reservas!.docs) {
            tx.delete(doc.reference);
          }
          if (estado == 'aprobado') {
            tx.set(_db.collection(reservasCollection).doc(), {
              ..._reservaEvento(
                canchaId: canchaNueva,
                canchaNombre: canchaNombre,
                fecha: fechaNueva,
                horaInicio: inicioNuevo,
                horaFin: finNuevo,
                refId: id,
                refNombre: titulo,
              ).toMap(),
              'creadoEn': FieldValue.serverTimestamp(),
            });
          }
          tx.update(cancha!.reference, {'version': FieldValue.increment(1)});
        } else if (reservas != null) {
          for (final doc in reservas.docs) {
            tx.update(doc.reference, {'refNombre': titulo});
          }
        }
        if (cambios.isNotEmpty) tx.update(eventoRef, cambios);
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: 'actualizar',
            modulo: 'eventos',
            descripcion: 'Actualizó el evento $titulo',
          ),
        );
      });
    });
  }

  static Future<AuthResponse> cambiarEstadoEvento({
    required String id,
    required String estado,
  }) {
    return _ejecutarAdmin(() async {
      const validos = ['pendiente', 'aprobado', 'rechazado', 'cancelado'];
      if (!validos.contains(estado)) {
        throw StateError('El estado del evento no es válido.');
      }
      final eventoRef = _db.collection(eventosCollection).doc(id);
      await _db.runTransaction((tx) async {
        final evento = await tx.get(eventoRef);
        if (!evento.exists) throw StateError('El evento no existe.');
        final actual = evento.data() ?? {};
        final canchaId = '${actual['canchaId'] ?? ''}';
        final cancha = canchaId.isEmpty
            ? null
            : await tx.get(_db.collection(canchasCollection).doc(canchaId));
        final reservas = await _reservasDelEvento(id);
        if (estado == 'aprobado') {
          if (cancha == null ||
              !cancha.exists ||
              cancha.data()?['activa'] != true) {
            throw StateError('La cancha no existe o está inactiva');
          }
          final fecha = '${actual['fecha'] ?? ''}';
          final inicio = _enteroAdmin(actual['horaInicio']);
          final fin = _enteroAdmin(actual['horaFin']);
          final canchaNombre =
              '${actual['canchaNombre'] ?? cancha.data()?['nombre'] ?? ''}';
          _exigirSinChoque(
            await _ocupadas(canchaId),
            _reservaEvento(
              canchaId: canchaId,
              canchaNombre: canchaNombre,
              fecha: fecha,
              horaInicio: inicio,
              horaFin: fin,
              refId: id,
              refNombre: '${actual['titulo'] ?? ''}',
            ),
            ignorarRefId: id,
          );
          tx.update(eventoRef, {'estado': estado});
          if (reservas.docs.isEmpty) {
            tx.set(_db.collection(reservasCollection).doc(), {
              ..._reservaEvento(
                canchaId: canchaId,
                canchaNombre: canchaNombre,
                fecha: fecha,
                horaInicio: inicio,
                horaFin: fin,
                refId: id,
                refNombre: '${actual['titulo'] ?? ''}',
              ).toMap(),
              'creadoEn': FieldValue.serverTimestamp(),
            });
          } else {
            for (final doc in reservas.docs) {
              tx.update(doc.reference, {'activa': true});
            }
          }
          tx.update(cancha.reference, {'version': FieldValue.increment(1)});
        } else {
          tx.update(eventoRef, {'estado': estado});
          if (estado == 'rechazado' || estado == 'cancelado') {
            for (final doc in reservas.docs) {
              tx.update(doc.reference, {'activa': false});
            }
            if (cancha != null && cancha.exists) {
              tx.update(cancha.reference, {'version': FieldValue.increment(1)});
            }
          }
        }
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: estado,
            modulo: 'eventos',
            descripcion: 'Cambió a $estado el evento ${actual['titulo'] ?? id}',
          ),
        );
      });
    });
  }

  static Stream<List<Map<String, dynamic>>> streamEstudiantesAdmin() {
    return _streamConsulta(
      _db.collection(usuariosCollection).where('rol', isEqualTo: 'estudiante'),
    );
  }

  static Future<AuthResponse> actualizarEstadoEstudiante({
    required String uid,
    required bool activo,
  }) {
    return _ejecutarAdmin(() async {
      final batch = _db.batch();
      batch.update(_db.collection(usuariosCollection).doc(uid), {
        'estado': activo ? 'activo' : 'inactivo',
      });
      batch.set(
        _db.collection(transaccionesCollection).doc(),
        _datosTransaccion(
          accion: activo ? 'activar' : 'desactivar',
          modulo: 'estudiantes',
          descripcion: '${activo ? 'Activó' : 'Desactivó'} al estudiante $uid',
        ),
      );
      await batch.commit();
    });
  }

  static Stream<List<Map<String, dynamic>>> streamResenasAdmin() {
    return _streamConsulta(
      _db.collection(resenasCollection).orderBy('fecha', descending: true),
    );
  }

  static Future<AuthResponse> cambiarVisibilidadResena({
    required String id,
    required bool visible,
  }) {
    return _ejecutarAdmin(() async {
      await _db.collection(resenasCollection).doc(id).update({
        'visible': visible,
      });
      await registrarTransaccion(
        accion: visible ? 'mostrar' : 'ocultar',
        modulo: 'resenas',
        descripcion: '${visible ? 'Mostró' : 'Ocultó'} la reseña $id',
      );
    });
  }

  static Stream<List<Map<String, dynamic>>> streamInscripcionesAdmin() {
    return _streamConsulta(
      _db
          .collection(inscripcionesCollection)
          .orderBy('fecha', descending: true),
    );
  }

  static Future<AuthResponse> cambiarEstadoInscripcion({
    required String id,
    required String estado,
  }) {
    return _ejecutarAdmin(() async {
      const validos = ['pendiente', 'confirmada', 'cancelada'];
      if (!validos.contains(estado)) {
        throw StateError('El estado de la inscripción no es válido.');
      }
      final inscripcionRef = _db.collection(inscripcionesCollection).doc(id);
      await _db.runTransaction((tx) async {
        final inscripcion = await tx.get(inscripcionRef);
        if (!inscripcion.exists) throw StateError('La inscripción no existe.');
        final datos = inscripcion.data() ?? {};
        final deporteRef = _db
            .collection(deportesCollection)
            .doc('${datos['deporteId'] ?? ''}');
        final deporte = await tx.get(deporteRef);
        if (!deporte.exists) throw StateError('El deporte no existe.');
        final antes = '${datos['estado'] ?? ''}';
        final ocupaba = antes == 'pendiente' || antes == 'confirmada';
        final ocupara = estado == 'pendiente' || estado == 'confirmada';
        var inscritos = _enteroAdmin(deporte.data()?['inscritos']);
        final cupos = _enteroAdmin(deporte.data()?['cupos']);
        if (ocupaba && !ocupara) {
          inscritos = inscritos > 0 ? inscritos - 1 : 0;
          tx.update(deporteRef, {'inscritos': inscritos});
        } else if (!ocupaba && ocupara) {
          if (inscritos >= cupos) {
            throw StateError('El deporte no tiene cupos disponibles');
          }
          tx.update(deporteRef, {'inscritos': inscritos + 1});
        }
        tx.update(inscripcionRef, {'estado': estado});
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: estado,
            modulo: 'inscripciones',
            descripcion: 'Cambió a $estado la inscripción $id',
          ),
        );
      });
    });
  }

  static Future<List<ReservaHorario>> _ocupadas(String canchaId) async {
    final snapshot = await _db
        .collection(reservasCollection)
        .where('canchaId', isEqualTo: canchaId)
        .where('activa', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => ReservaHorario.fromMap(doc.id, doc.data()))
        .toList();
  }

  static Future<QuerySnapshot<Map<String, dynamic>>> _reservasDelEvento(
    String id,
  ) {
    return _db
        .collection(reservasCollection)
        .where('refId', isEqualTo: id)
        .where('tipo', isEqualTo: TipoReserva.evento.valor)
        .get();
  }

  static ReservaHorario _reservaEvento({
    required String canchaId,
    required String canchaNombre,
    required String fecha,
    required int horaInicio,
    required int horaFin,
    required String refId,
    required String refNombre,
  }) {
    return ReservaHorario(
      id: '',
      canchaId: canchaId,
      canchaNombre: canchaNombre,
      dia: DateTime.parse(fecha).weekday,
      horaInicio: horaInicio,
      horaFin: horaFin,
      fecha: fecha,
      tipo: TipoReserva.evento,
      refId: refId,
      refNombre: refNombre,
      activa: true,
    );
  }

  static void _exigirSinChoque(
    List<ReservaHorario> existentes,
    ReservaHorario nueva, {
    String? ignorarRefId,
  }) {
    final choque = buscarChoque(
      nuevas: [nueva],
      existentes: existentes,
      ignorarRefId: ignorarRefId,
    );
    if (choque != null) throw StateError(mensajeChoque(choque));
  }

  static void _validarFechaEvento(String fecha) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fecha)) {
      throw StateError('La fecha no es válida.');
    }
    final parseada = DateTime.tryParse(fecha);
    if (parseada == null) throw StateError('La fecha no es válida.');
    final dia = DateTime(parseada.year, parseada.month, parseada.day);
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    if (dia.isBefore(hoy)) {
      throw StateError('La fecha no puede ser anterior a hoy.');
    }
  }

  // ===== ADMINISTRADOR (Andrés): pagos, soporte, historial, resumen =====

  static Stream<List<Map<String, dynamic>>> streamPagosAdmin() {
    return _streamConsulta(
      _db.collection(pagosCollection).orderBy('fecha', descending: true),
    );
  }

  static Future<AuthResponse> registrarPagoPaypal({
    required String pagoId,
    required String paypalOrderId,
    required DateTime fechaPago,
    required bool verificado,
    required String verificadoPor,
  }) {
    return _ejecutarAdmin(() async {
      await _db.collection(pagosCollection).doc(pagoId).update({
        'paypalOrderId': paypalOrderId,
        'idTransaccion': paypalOrderId,
        'fechaPago': fechaPago,
        'verificado': verificado,
        'verificadoPor': verificadoPor,
        'verificadoEn': FieldValue.serverTimestamp(),
        'estado': verificado ? 'realizado' : 'pendiente',
      });
      await registrarTransaccion(
        accion: verificado ? 'verificar' : 'rechazar',
        modulo: 'pagos',
        descripcion:
            'Registró el pago $pagoId como ${verificadoPor == 'simulado' ? 'simulado' : verificadoPor}',
      );
    });
  }

  static Stream<Map<String, dynamic>?> streamConfiguracionPagos() {
    return _db
        .collection(configuracionCollection)
        .doc('pagos')
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return <String, dynamic>{'id': doc.id, ...doc.data()!};
        })
        .transform(
          StreamTransformer<
            Map<String, dynamic>?,
            Map<String, dynamic>?
          >.fromHandlers(handleError: (error, stack, sink) => sink.add(null)),
        );
  }

  static Future<AuthResponse> guardarFechaCorte({
    required String periodo,
    required DateTime fechaInicio,
    required DateTime fechaCorte,
    required double monto,
  }) {
    return _ejecutarAdmin(() async {
      if (!fechaInicio.isBefore(fechaCorte)) {
        throw StateError('La fecha de inicio debe ser anterior a la de corte.');
      }
      if (monto <= 0) {
        throw StateError('El monto debe ser mayor que cero.');
      }
      final batch = _db.batch();
      batch.set(_db.collection(configuracionCollection).doc('pagos'), {
        'periodo': periodo.trim(),
        'fechaInicio': fechaInicio,
        'fechaCorte': fechaCorte,
        'monto': monto,
      }, SetOptions(merge: true));
      batch.set(
        _db.collection(transaccionesCollection).doc(),
        _datosTransaccion(
          accion: 'guardar',
          modulo: 'pagos',
          descripcion: 'Guardó la fecha de corte del período ${periodo.trim()}',
        ),
      );
      await batch.commit();
    });
  }

  static Future<AuthResponse> actualizarSolvencia({
    required String uid,
    required bool solvente,
  }) {
    return _ejecutarAdmin(() async {
      await _db.collection(usuariosCollection).doc(uid).update({
        'solvente': solvente,
      });
      await registrarTransaccion(
        accion: solvente ? 'marcar_solvente' : 'marcar_insolvente',
        modulo: 'estudiantes',
        descripcion:
            '${solvente ? 'Marcó solvente' : 'Marcó insolvente'} al estudiante $uid',
      );
    });
  }

  static Future<AuthResponse> crearNotificacionPago({
    required String uid,
    required String periodo,
    required DateTime fechaCorte,
  }) {
    return _ejecutarAdmin(() async {
      final id = 'pago-$periodo-$uid';
      final ref = _db.collection(notificacionesCollection).doc(id);
      await _db.runTransaction((tx) async {
        final actual = await tx.get(ref);
        if (actual.exists) return;
        final dia = fechaCorte.day.toString().padLeft(2, '0');
        final mes = fechaCorte.month.toString().padLeft(2, '0');
        tx.set(ref, {
          'destinatarioUid': uid,
          'tipo': 'pago_pendiente',
          'titulo': 'Pago pendiente',
          'mensaje':
              'No registramos tu pago del período $periodo antes de la fecha de corte ($dia/$mes/${fechaCorte.year}). Regulariza tu pago para seguir solvente.',
          'periodo': periodo,
          'leida': false,
          'fecha': FieldValue.serverTimestamp(),
        });
      });
    });
  }

  static Stream<List<Map<String, dynamic>>> streamTickets() {
    return _streamConsulta(
      _db.collection(ticketsCollection).orderBy('fecha', descending: true),
    );
  }

  static Future<AuthResponse> responderTicket({
    required String id,
    required String respuesta,
    bool resolver = true,
  }) {
    return _ejecutarAdmin(() async {
      final texto = respuesta.trim();
      if (texto.isEmpty) {
        throw StateError('La respuesta es obligatoria.');
      }
      final cambios = <String, dynamic>{'respuesta': texto};
      if (resolver) {
        cambios['estado'] = 'resuelto';
        cambios['resueltoEn'] = FieldValue.serverTimestamp();
      }
      await _db.collection(ticketsCollection).doc(id).update(cambios);
      await registrarTransaccion(
        accion: resolver ? 'resolver' : 'responder',
        modulo: 'soporte',
        descripcion: 'Respondió el ticket $id',
      );
    });
  }

  static Stream<List<Map<String, dynamic>>> streamTransacciones({
    int limite = 200,
  }) {
    return _streamConsulta(
      _db
          .collection(transaccionesCollection)
          .orderBy('fecha', descending: true)
          .limit(limite),
    );
  }

  static Future<Map<String, num>> contarResumenAdmin() async {
    final resultados = await Future.wait<num>([
      _contar(
        _db
            .collection(usuariosCollection)
            .where('rol', isEqualTo: 'estudiante'),
      ),
      _contar(
        _db.collection(entrenadoresCollection).where('activo', isEqualTo: true),
      ),
      _contar(
        _db.collection(deportesCollection).where('activo', isEqualTo: true),
      ),
      _contar(
        _db.collection(canchasCollection).where('activa', isEqualTo: true),
      ),
      _contar(
        _db
            .collection(inscripcionesCollection)
            .where('estado', isEqualTo: 'confirmada'),
      ),
      _contar(
        _db
            .collection(inscripcionesCollection)
            .where('estado', isEqualTo: 'pendiente'),
      ),
      _contar(
        _db.collection(pagosCollection).where('estado', isEqualTo: 'pendiente'),
      ),
      _contar(
        _db.collection(pagosCollection).where('estado', isEqualTo: 'realizado'),
      ),
      _contar(
        _db.collection(resenasCollection).where('visible', isEqualTo: false),
      ),
      _contar(
        _db.collection(ticketsCollection).where('estado', isEqualTo: 'abierto'),
      ),
      _contar(
        _db
            .collection(eventosCollection)
            .where('estado', isEqualTo: 'aprobado'),
      ),
      _sumarIngresos(),
    ]);
    return {
      'estudiantes': resultados[0],
      'entrenadoresActivos': resultados[1],
      'deportesActivos': resultados[2],
      'canchasActivas': resultados[3],
      'inscripcionesConfirmadas': resultados[4],
      'inscripcionesPendientes': resultados[5],
      'pagosPendientes': resultados[6],
      'pagosRealizados': resultados[7],
      'resenasOcultas': resultados[8],
      'ticketsAbiertos': resultados[9],
      'eventosAprobados': resultados[10],
      'ingresos': resultados[11],
    };
  }

  static Future<num> _contar(Query<Map<String, dynamic>> consulta) async {
    try {
      final snapshot = await consulta.count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<num> _sumarIngresos() async {
    try {
      final snapshot = await _db
          .collection(pagosCollection)
          .where('estado', isEqualTo: 'realizado')
          .aggregate(sum('monto'))
          .get();
      return snapshot.getSum('monto') ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

class AuthResponse {
  final UserCredential? credential;
  final String? errorMessage;
  final bool isSuccess;

  AuthResponse({this.credential, this.errorMessage, required this.isSuccess});
}
