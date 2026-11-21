import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/identificadores.dart';
import 'package:saman_sports/core/utils/validators.dart';
import 'package:saman_sports/core/utils/choque_horario.dart';
import 'package:saman_sports/core/utils/solicitud_evento_entrenador.dart';
import 'package:saman_sports/core/utils/ticket_soporte_entrenador.dart';
import 'package:saman_sports/core/utils/ticket_soporte_estudiante.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/admin/admin_solvencia.dart';

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
  static const String identificadoresCollection = 'identificadores';

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

  static Future<AuthResponse> crearPerfilEstudiante({
    required String uid,
    required Map<String, dynamic> datos,
  }) async {
    try {
      final cedula = cedulaNormalizada('${datos['cedula'] ?? ''}');
      final carnet = carnetNormalizado('${datos['carnet'] ?? ''}');
      final cedulaRef = _db
          .collection(identificadoresCollection)
          .doc('cedula_$cedula');
      final carnetRef = _db
          .collection(identificadoresCollection)
          .doc('carnet_$carnet');
      await _db.runTransaction((tx) async {
        final cedulaDoc = await tx.get(cedulaRef);
        if (cedulaDoc.exists) {
          throw StateError(AppStrings.cedulaYaRegistrada);
        }
        final carnetDoc = await tx.get(carnetRef);
        if (carnetDoc.exists) {
          throw StateError(AppStrings.carnetYaRegistrado);
        }
        tx.set(_db.collection(usuariosCollection).doc(uid), {
          ...datos,
          'cedula': cedula,
          'carnet': carnet,
        });
        tx.set(cedulaRef, {
          'uid': uid,
          'tipo': 'cedula',
          'creadoEn': FieldValue.serverTimestamp(),
        });
        tx.set(carnetRef, {
          'uid': uid,
          'tipo': 'carnet',
          'creadoEn': FieldValue.serverTimestamp(),
        });
        tx.set(
          _db.collection(notificacionesCollection).doc(),
          _aviso(
            destinatarioUid: '',
            destinatarioRol: 'administrador',
            origenUid: uid,
            tipo: 'registro_estudiante',
            titulo: AppStrings.tituloAvisoRegistro,
            mensaje: AppStrings.avisoRegistroEstudiante(_nombrePersona(datos)),
          ),
        );
      });
      return AuthResponse(isSuccess: true);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return AuthResponse(
          errorMessage: AppStrings.cedulaOCarnetYaRegistrado,
          isSuccess: false,
        );
      }
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } on StateError catch (e) {
      return AuthResponse(errorMessage: e.message.toString(), isSuccess: false);
    } catch (_) {
      return AuthResponse(
        errorMessage: AppStrings.errorInesperado,
        isSuccess: false,
      );
    }
  }

  static Future<List<String>> indexarIdentificadoresEstudiantes() async {
    final consulta = await consultarRol(uid: _auth.currentUser?.uid ?? '');
    if (consulta.rol != 'administrador') {
      throw StateError('Solo el administrador puede revisar identificadores.');
    }
    final estudiantes = await _db
        .collection(usuariosCollection)
        .where('rol', isEqualTo: 'estudiante')
        .get();
    final alumnos = [
      for (final doc in estudiantes.docs)
        AlumnoIdentificador(
          uid: doc.id,
          nombre: '${doc.data()['nombre'] ?? ''}',
          apellido: '${doc.data()['apellido'] ?? ''}',
          cedula: '${doc.data()['cedula'] ?? ''}',
          carnet: '${doc.data()['carnet'] ?? ''}',
        ),
    ];
    final ocupados = await _ocupadosIdentificadores(alumnos);
    final plan = planificarIdentificadores(alumnos: alumnos, ocupados: ocupados);
    var lote = _db.batch();
    var operaciones = 0;
    Future<void> cerrar() async {
      if (operaciones == 0) return;
      await lote.commit();
      lote = _db.batch();
      operaciones = 0;
    }

    for (final item in plan.crear) {
      lote.set(_db.collection(identificadoresCollection).doc(item.id), {
        'uid': item.uid,
        'tipo': item.tipo,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      operaciones++;
      if (operaciones >= 400) await cerrar();
    }
    await cerrar();
    return plan.informe;
  }

  /// Crea los índices que faltan del estudiante con sesión abierta.
  /// Si el índice ya es suyo, no escribe. Si lo tiene otro uid, no escribe
  /// y no interrumpe el inicio de sesión.
  static Future<void> asegurarIdentificadoresEstudiante({
    required String uid,
  }) async {
    try {
      if (_auth.currentUser?.uid != uid) return;
      final doc = await _db.collection(usuariosCollection).doc(uid).get();
      final datos = doc.data();
      if (datos == null || datos['rol'] != 'estudiante') return;
      if ('${datos['estado'] ?? 'activo'}' == 'inactivo') return;
      final alumno = AlumnoIdentificador(
        uid: uid,
        nombre: '${datos['nombre'] ?? ''}',
        apellido: '${datos['apellido'] ?? ''}',
        cedula: '${datos['cedula'] ?? ''}',
        carnet: '${datos['carnet'] ?? ''}',
      );
      final ocupados = await _ocupadosIdentificadores([alumno]);
      final plan = planificarIdentificadores(
        alumnos: [alumno],
        ocupados: ocupados,
      );
      for (final item in plan.crear) {
        try {
          await _db.collection(identificadoresCollection).doc(item.id).set({
            'uid': uid,
            'tipo': item.tipo,
            'creadoEn': FieldValue.serverTimestamp(),
          });
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied' || e.code == 'already-exists') {
            continue;
          }
        }
      }
    } catch (_) {
      // Un índice duplicado o un fallo de red no puede tumbar la sesión.
    }
  }

  static Future<Map<String, String>> _ocupadosIdentificadores(
    List<AlumnoIdentificador> alumnos,
  ) async {
    final ocupados = <String, String>{};
    for (final alumno in alumnos) {
      for (final item in [
        ('cedula', cedulaNormalizada(alumno.cedula)),
        ('carnet', carnetNormalizado(alumno.carnet)),
      ]) {
        if (item.$2.isEmpty) continue;
        final id = idIdentificador(item.$1, item.$2);
        final actual = await _db
            .collection(identificadoresCollection)
            .doc(id)
            .get();
        final dueno = actual.data()?['uid'];
        if (actual.exists && dueno is String && dueno.isNotEmpty) {
          ocupados[id] = dueno;
        }
      }
    }
    return ocupados;
  }

  static Future<AuthResponse> cambiarClave({
    required String claveActual,
    required String claveNueva,
  }) async {
    try {
      final usuario = _auth.currentUser;
      final correo = usuario?.email;
      if (usuario == null || correo == null) {
        return AuthResponse(
          errorMessage: AppStrings.sesionNoIniciada,
          isSuccess: false,
        );
      }
      final credencial = EmailAuthProvider.credential(
        email: correo,
        password: claveActual,
      );
      await usuario.reauthenticateWithCredential(credencial);
      await usuario.updatePassword(claveNueva);
      return AuthResponse(isSuccess: true);
    } on FirebaseAuthException catch (e) {
      final codigo = e.code;
      final mensaje = codigo == 'wrong-password' || codigo == 'invalid-credential'
          ? AppStrings.claveActualIncorrecta
          : codigo == 'weak-password'
          ? AppStrings.claveDebil
          : codigo == 'requires-recent-login'
          ? AppStrings.reiniciaSesionParaClave
          : AppStrings.errorInesperado;
      return AuthResponse(errorMessage: mensaje, isSuccess: false);
    } catch (_) {
      return AuthResponse(
        errorMessage: AppStrings.errorInesperado,
        isSuccess: false,
      );
    }
  }

  static Future<AuthResponse> actualizarPerfilEntrenador({
    required String uid,
    required String telefono,
    required String biografia,
    required int anosExperiencia,
    required List<String> certificaciones,
  }) async {
    try {
      if (_auth.currentUser?.uid != uid) {
        throw StateError(AppStrings.sesionNoIniciada);
      }
      final telefonoError = Validators.telefono(telefono);
      if (telefonoError != null) throw StateError(telefonoError);
      if (anosExperiencia < 0 || anosExperiencia > 60) {
        throw StateError(AppStrings.entAnosInvalidos);
      }
      if (biografia.trim().length > 500) {
        throw StateError(AppStrings.entBiografiaLarga);
      }
      if (certificaciones.length > 10) {
        throw StateError(AppStrings.entCertificacionesMaximo);
      }
      final lote = _db.batch();
      lote.update(_db.collection(usuariosCollection).doc(uid), {
        'telefono': telefono.trim(),
      });
      lote.update(_db.collection(entrenadoresCollection).doc(uid), {
        'biografia': biografia.trim(),
        'anosExperiencia': anosExperiencia,
        'certificaciones': certificaciones,
      });
      await lote.commit();
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
        errorMessage: AppStrings.errorInesperado,
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

  static Future<({bool error, bool existe, String? rol, String estado})>
  consultarRol({required String uid}) async {
    try {
      final doc = await _db.collection(usuariosCollection).doc(uid).get();
      if (!doc.exists) {
        return (error: false, existe: false, rol: null, estado: 'activo');
      }
      final datos = doc.data();
      final rol = datos?['rol'];
      final estado = datos?['estado'];
      return (
        error: false,
        existe: true,
        rol: rol is String ? rol : null,
        estado: estado is String && estado.isNotEmpty ? estado : 'activo',
      );
    } catch (_) {
      return (error: true, existe: false, rol: null, estado: 'activo');
    }
  }

  /// Borra la cuenta recién creada en Auth. Se usa en el registro si la cuenta
  /// se creó pero no se pudieron guardar sus datos en Firestore, para no dejar
  /// cuentas a medias.
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
      _db.collection(deportesCollection).where('activo', isEqualTo: true),
    ).map((lista) => _ordenarPorTexto(lista, 'nombre'));
  }

  static Stream<List<Map<String, dynamic>>> streamEntrenadores() {
    return _streamConsulta(
      _db.collection(entrenadoresCollection).where('activo', isEqualTo: true),
    ).map((lista) => _ordenarPorTexto(lista, 'nombre'));
  }

  static Stream<List<Map<String, dynamic>>> streamResenas({int limite = 6}) {
    return _streamConsulta(
      _db.collection(resenasCollection).where('visible', isEqualTo: true),
    ).map((lista) {
      final ordenada = [...lista]
        ..sort((a, b) => _milis(b['fecha']).compareTo(_milis(a['fecha'])));
      return ordenada.take(limite).toList();
    });
  }

  static List<Map<String, dynamic>> _ordenarPorTexto(
    List<Map<String, dynamic>> lista,
    String campo,
  ) {
    return [...lista]
      ..sort((a, b) => '${a[campo] ?? ''}'
          .toLowerCase()
          .compareTo('${b[campo] ?? ''}'.toLowerCase()));
  }

  static int _milis(dynamic valor) {
    if (valor is Timestamp) return valor.millisecondsSinceEpoch;
    if (valor is DateTime) return valor.millisecondsSinceEpoch;
    if (valor is String) {
      return DateTime.tryParse(valor)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
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

  /// Avisos del usuario actual. Sin orderBy: el controlador ordena en Dart.
  static Stream<List<Map<String, dynamic>>> streamNotificacionesDe(String uid) {
    return _streamConsultaEntrenador(
      _db
          .collection(notificacionesCollection)
          .where('destinatarioUid', isEqualTo: uid),
    );
  }

  static Future<AuthResponse> marcarNotificacionLeida({required String id}) {
    return _ejecutarAdmin(() async {
      final uid = _auth.currentUser?.uid ?? '';
      final ref = _db.collection(notificacionesCollection).doc(id);
      final doc = await ref.get();
      if (!doc.exists) throw StateError('La notificación no existe.');
      if ('${doc.data()?['destinatarioUid'] ?? ''}' != uid) {
        throw StateError('No puedes marcar esta notificación.');
      }
      await ref.update({'leida': true});
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
          .where('activa', isEqualTo: true),
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
      final eventoRef = _db.collection(eventosCollection).doc();
      final batch = _db.batch();
      batch.set(eventoRef, {
        ...solicitud,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      batch.set(
        _db.collection(notificacionesCollection).doc(),
        _aviso(
          destinatarioUid: '',
          destinatarioRol: 'administrador',
          origenUid: entrenadorUid,
          tipo: 'solicitud_evento',
          titulo: AppStrings.tituloAvisoEvento,
          mensaje: AppStrings.avisoSolicitudEvento('${solicitud['titulo'] ?? ''}'),
          eventoId: eventoRef.id,
          deporteId: deporteId,
        ),
      );
      await batch.commit();
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

  static Future<AuthResponse> cancelarSolicitudEventoEntrenador({
    required String entrenadorUid,
    required String eventoId,
  }) async {
    try {
      final actual = _auth.currentUser?.uid;
      if (actual == null || actual != entrenadorUid) {
        throw StateError('Sesión de entrenador requerida');
      }
      final ref = _db.collection(eventosCollection).doc(eventoId);
      final evento = await ref.get();
      final datos = evento.data();
      if (!evento.exists ||
          datos == null ||
          datos['creadoPorUid'] != entrenadorUid ||
          datos['estado'] != 'pendiente') {
        throw StateError(AppStrings.entSolicitudNoCancelable);
      }
      await ref.update({
        'estado': 'cancelado',
        'actualizadoEn': FieldValue.serverTimestamp(),
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

  static Future<AuthResponse> editarSolicitudEventoEntrenador({
    required String entrenadorUid,
    required String eventoId,
    required Map<String, dynamic> datos,
  }) async {
    try {
      final actual = _auth.currentUser?.uid;
      if (actual == null || actual != entrenadorUid) {
        throw StateError('Sesión de entrenador requerida');
      }
      final ref = _db.collection(eventosCollection).doc(eventoId);
      final evento = await ref.get();
      final actualDatos = evento.data();
      if (!evento.exists ||
          actualDatos == null ||
          actualDatos['creadoPorUid'] != entrenadorUid ||
          actualDatos['estado'] != 'pendiente') {
        throw StateError(AppStrings.entSolicitudNoCancelable);
      }
      final deporteId = '${actualDatos['deporteId'] ?? ''}'.trim();
      final canchaId = '${datos['canchaId'] ?? actualDatos['canchaId'] ?? ''}'
          .trim();
      if (deporteId.isEmpty) throw StateError('Elige una disciplina.');
      if (canchaId.isEmpty) throw StateError('Elige una cancha.');
      final documentos = await Future.wait([
        _db.collection(deportesCollection).doc(deporteId).get(),
        _db.collection(canchasCollection).doc(canchaId).get(),
      ]);
      final deporte = documentos[0];
      final cancha = documentos[1];
      final solicitud = construirSolicitudEventoEntrenador(
        datos: {...datos, 'deporteId': deporteId},
        entrenadorUid: entrenadorUid,
        deporte: {'id': deporte.id, ...?deporte.data()},
        cancha: {'id': cancha.id, ...?cancha.data()},
        reservasCancha: await _ocupadas(canchaId),
        ahora: DateTime.now(),
      );
      await ref.update({
        'titulo': solicitud['titulo'],
        'descripcion': solicitud['descripcion'],
        'fecha': solicitud['fecha'],
        'horaInicio': solicitud['horaInicio'],
        'horaFin': solicitud['horaFin'],
        'capacidad': solicitud['capacidad'],
        'canchaId': solicitud['canchaId'],
        'canchaNombre': solicitud['canchaNombre'],
        'ubicacion': solicitud['ubicacion'],
        'actualizadoEn': FieldValue.serverTimestamp(),
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

  /// Tickets creados por el entrenador autenticado. El filtro por autor es
  /// parte del contrato que también deben exigir las reglas de Firestore.
  static Stream<List<Map<String, dynamic>>> streamTicketsEntrenador({
    required String entrenadorUid,
  }) {
    final actual = _auth.currentUser?.uid;
    if (actual == null || actual != entrenadorUid) {
      return Stream.error(StateError('Sesión de entrenador requerida'));
    }
    return _streamConsultaEntrenador(
      _db
          .collection(ticketsCollection)
          .where('autorUid', isEqualTo: entrenadorUid),
    );
  }

  /// Crea un ticket abierto con la identidad tomada de la sesión y del perfil,
  /// nunca de campos enviados por la interfaz.
  static Future<AuthResponse> crearTicketEntrenador({
    required String entrenadorUid,
    required String categoria,
    required String asunto,
    required String descripcion,
  }) async {
    try {
      final actual = _auth.currentUser?.uid;
      if (actual == null || actual != entrenadorUid) {
        throw StateError('Sesión de entrenador requerida');
      }
      final perfil = await getUserData(uid: entrenadorUid);
      final ticketRef = _db.collection(ticketsCollection).doc();
      final batch = _db.batch();
      batch.set(
        ticketRef,
        construirTicketSoporteEntrenador(
          entrenadorUid: entrenadorUid,
          perfil: perfil,
          categoria: categoria,
          asunto: asunto,
          descripcion: descripcion,
          fechaServidor: FieldValue.serverTimestamp(),
        ),
      );
      batch.set(
        _db.collection(notificacionesCollection).doc(),
        _aviso(
          destinatarioUid: '',
          destinatarioRol: 'administrador',
          origenUid: entrenadorUid,
          tipo: 'ticket_nuevo',
          titulo: AppStrings.tituloAvisoTicket,
          mensaje: AppStrings.avisoTicketNuevo(asunto),
          ticketId: ticketRef.id,
        ),
      );
      await batch.commit();
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
        errorMessage: 'No se pudo enviar la solicitud. Intenta nuevamente.',
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
  // ---------------------------------------------------------------------------
  // Funciones agregadas por Gonzalo (panel del estudiante: inscripciones)
  // ---------------------------------------------------------------------------

  /// Inscripciones del estudiante, en vivo. Sin orderBy para no necesitar
  /// un índice compuesto: el controlador las ordena por fecha.
  /// La usa InscripcionesController.
  static Stream<List<Map<String, dynamic>>> streamMisInscripciones({
    required String estudianteUid,
  }) {
    return _streamConsulta(
      _db
          .collection(inscripcionesCollection)
          .where('estudianteUid', isEqualTo: estudianteUid),
    );
  }

  /// Inscribe al estudiante con sesión abierta en un deporte (RF-04).
  ///
  /// En una transacción: revisa que la cuenta esté activa, que el deporte
  /// esté activo y tenga cupo, que no esté ya inscrito, suma 1 a
  /// `inscritos` y deja la inscripción en 'pendiente'. El id es
  /// `{uid}_{deporteId}` para que no se pueda inscribir dos veces.
  static Future<AuthResponse> inscribirseEnDeporte({
    required String deporteId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return AuthResponse(
        errorMessage: AppStrings.sesionNoIniciada,
        isSuccess: false,
      );
    }
    try {
      final usuario = await _db.collection(usuariosCollection).doc(uid).get();
      if (usuario.data()?['estado'] == 'inactivo') {
        throw StateError(AppStrings.inscripcionCuentaInactiva);
      }
      final usuarioRef = _db.collection(usuariosCollection).doc(uid);
      final deporteRef = _db.collection(deportesCollection).doc(deporteId);
      final inscripcionRef = _db
          .collection(inscripcionesCollection)
          .doc('${uid}_$deporteId');
      await _db.runTransaction((tx) async {
        final usuarioTx = await tx.get(usuarioRef);
        final deporte = await tx.get(deporteRef);
        final inscripcion = await tx.get(inscripcionRef);
        if (usuarioTx.data()?['solvente'] != true) {
          throw StateError(AppStrings.debesEstarSolvente);
        }
        final datos = deporte.data();
        if (!deporte.exists || datos == null || datos['activo'] == false) {
          throw StateError(AppStrings.inscripcionDeporteNoDisponible);
        }
        final estadoActual = inscripcion.data()?['estado'];
        if (inscripcion.exists && estadoActual != 'cancelada') {
          throw StateError(AppStrings.inscripcionYaExiste);
        }
        final cupos = _enteroAdmin(datos['cupos']);
        final inscritos = _enteroAdmin(datos['inscritos']);
        if (inscritos >= cupos) {
          throw StateError(AppStrings.inscripcionSinCupos);
        }
        tx.update(deporteRef, {'inscritos': inscritos + 1});
        final deporteNombre = '${datos['nombre'] ?? ''}';
        tx.set(inscripcionRef, {
          'estudianteUid': uid,
          'deporteId': deporteId,
          'deporteNombre': deporteNombre,
          'estado': 'pendiente',
          'fecha': FieldValue.serverTimestamp(),
        });
        tx.set(
          _db.collection(notificacionesCollection).doc(),
          _aviso(
            destinatarioUid: uid,
            destinatarioRol: 'estudiante',
            origenUid: uid,
            tipo: 'inscripcion_creada',
            titulo: AppStrings.tituloAvisoInscripcion,
            mensaje: AppStrings.avisoInscripcionCreada(deporteNombre),
            inscripcionId: '${uid}_$deporteId',
            deporteId: deporteId,
          ),
        );
        tx.set(
          _db.collection(notificacionesCollection).doc(),
          _aviso(
            destinatarioUid: '',
            destinatarioRol: 'administrador',
            origenUid: uid,
            tipo: 'inscripcion_pendiente',
            titulo: AppStrings.tituloAvisoInscripcion,
            mensaje: AppStrings.avisoInscripcionPendienteAdmin(
              _nombrePersona(usuarioTx.data()),
              deporteNombre,
            ),
            inscripcionId: '${uid}_$deporteId',
            deporteId: deporteId,
          ),
        );
      });
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

  /// Cancela una inscripción del estudiante con sesión abierta (RF-05).
  /// En una transacción la marca 'cancelada' y libera el cupo (inscritos - 1).
  static Future<AuthResponse> cancelarInscripcion({
    required String inscripcionId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return AuthResponse(
        errorMessage: AppStrings.sesionNoIniciada,
        isSuccess: false,
      );
    }
    try {
      final inscripcionRef = _db
          .collection(inscripcionesCollection)
          .doc(inscripcionId);
      await _db.runTransaction((tx) async {
        final inscripcion = await tx.get(inscripcionRef);
        final datos = inscripcion.data();
        if (!inscripcion.exists ||
            datos == null ||
            datos['estudianteUid'] != uid) {
          throw StateError(AppStrings.inscripcionNoEncontrada);
        }
        if (datos['estado'] == 'cancelada') {
          throw StateError(AppStrings.inscripcionYaCancelada);
        }
        final deporteRef = _db
            .collection(deportesCollection)
            .doc('${datos['deporteId'] ?? ''}');
        final deporte = await tx.get(deporteRef);
        if (deporte.exists) {
          final inscritos = _enteroAdmin(deporte.data()?['inscritos']);
          // Si inscritos ya es 0 no se escribe el deporte: la regla lo permite.
          if (inscritos > 0) {
            tx.update(deporteRef, {'inscritos': inscritos - 1});
          }
        }
        tx.update(inscripcionRef, {'estado': 'cancelada'});
        tx.set(
          _db.collection(notificacionesCollection).doc(),
          _aviso(
            destinatarioUid: uid,
            destinatarioRol: 'estudiante',
            origenUid: uid,
            tipo: 'inscripcion_cancelada',
            titulo: AppStrings.tituloAvisoInscripcion,
            mensaje: AppStrings.avisoInscripcionCancelada(
              '${datos['deporteNombre'] ?? ''}',
            ),
            inscripcionId: inscripcionId,
            deporteId: '${datos['deporteId'] ?? ''}',
          ),
        );
      });
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
  
  // ---------------------------------------------------------------------------
  // Funciones agregadas por Gonzalo (panel del estudiante: pagos)
  // ---------------------------------------------------------------------------

  /// Pagos del estudiante, en vivo. Sin orderBy para no necesitar un
  /// índice compuesto: PagosController los ordena por fecha.
  static Stream<List<Map<String, dynamic>>> streamMisPagos({
    required String estudianteUid,
  }) {
    return _streamConsulta(
      _db
          .collection(pagosCollection)
          .where('estudianteUid', isEqualTo: estudianteUid),
    );
  }

  /// Registra el pago del período hecho con PayPal (simulado, RF-15).
  ///
  /// Queda 'pendiente' y sin verificar: el administrador lo verifica desde
  /// su panel con el `paypalOrderId`. El estudiante nunca escribe
  /// `verificado`, `verificadoPor` ni `fechaPago`.
  static Future<AuthResponse> registrarPagoEstudiante({
    required double monto,
    required String periodo,
    required String paypalOrderId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return AuthResponse(
        errorMessage: AppStrings.sesionNoIniciada,
        isSuccess: false,
      );
    }
    try {
      final pagoRef = _db.collection(pagosCollection).doc();
      final batch = _db.batch();
      batch.set(pagoRef, {
        'estudianteUid': uid,
        'inscripcionId': '',
        'monto': monto,
        'periodo': periodo,
        'paypalOrderId': paypalOrderId,
        'idTransaccion': paypalOrderId,
        'estado': 'pendiente',
        'verificado': false,
        'fecha': FieldValue.serverTimestamp(),
      });
      batch.set(
        _db.collection(notificacionesCollection).doc(),
        _aviso(
          destinatarioUid: '',
          destinatarioRol: 'administrador',
          origenUid: uid,
          tipo: 'pago_enviado',
          titulo: AppStrings.tituloAvisoPago,
          mensaje: AppStrings.avisoPagoEnviado(periodo),
          pagoId: pagoRef.id,
        ),
      );
      await batch.commit();
      return AuthResponse(isSuccess: true);
    } on FirebaseException catch (e) {
      return AuthResponse(
        errorMessage: _firestoreErrorMessage(e),
        isSuccess: false,
      );
    } catch (_) {
      return AuthResponse(
        errorMessage: AppStrings.errorInesperado,
        isSuccess: false,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Funciones agregadas por Gonzalo (panel del estudiante: recordatorios)
  // ---------------------------------------------------------------------------

  /// Avisos del estudiante (pago pendiente, eventos de sus disciplinas), en
  /// vivo. Para marcarlos como leídos se usa marcarNotificacionLeida.
  static Stream<List<Map<String, dynamic>>> streamMisNotificaciones({
    required String uid,
  }) {
    return _streamConsulta(
      _db
          .collection(notificacionesCollection)
          .where('destinatarioUid', isEqualTo: uid),
    );
  }

  // ---------------------------------------------------------------------------
  // Funciones agregadas por Gonzalo (panel del estudiante: soporte)
  // ---------------------------------------------------------------------------

  /// Tickets que creó el estudiante, en vivo, con la respuesta del admin.
  static Stream<List<Map<String, dynamic>>> streamMisTickets({
    required String uid,
  }) {
    return _streamConsulta(
      _db.collection(ticketsCollection).where('autorUid', isEqualTo: uid),
    );
  }

  /// Crea un ticket abierto del estudiante con la sesión actual. El nombre
  /// y el rol salen de su perfil, no de lo que escribe en el formulario.
  static Future<AuthResponse> crearTicketEstudiante({
    required String categoria,
    required String asunto,
    required String descripcion,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return AuthResponse(
        errorMessage: AppStrings.sesionNoIniciada,
        isSuccess: false,
      );
    }
    try {
      final perfil = await getUserData(uid: uid);
      final ticketRef = _db.collection(ticketsCollection).doc();
      final batch = _db.batch();
      batch.set(
        ticketRef,
        construirTicketEstudiante(
          estudianteUid: uid,
          perfil: perfil,
          categoria: categoria,
          asunto: asunto,
          descripcion: descripcion,
          fechaServidor: FieldValue.serverTimestamp(),
        ),
      );
      batch.set(
        _db.collection(notificacionesCollection).doc(),
        _aviso(
          destinatarioUid: '',
          destinatarioRol: 'administrador',
          origenUid: uid,
          tipo: 'ticket_nuevo',
          titulo: AppStrings.tituloAvisoTicket,
          mensaje: AppStrings.avisoTicketNuevo(asunto),
          ticketId: ticketRef.id,
        ),
      );
      await batch.commit();
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
        descripcion: AppStrings.txCanchaCreada(nombre),
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
      final actual = await _db.collection(canchasCollection).doc(id).get();
      final nombre = _textoODesconocido(
        '${cambios['nombre'] ?? actual.data()?['nombre'] ?? ''}',
      );
      await _db.collection(canchasCollection).doc(id).update(cambios);
      await registrarTransaccion(
        accion: 'actualizar',
        modulo: 'canchas',
        descripcion: AppStrings.txCanchaActualizada(nombre),
      );
    });
  }

  /// Sin orderBy para no exigir índice compuesto; se ordena en Dart.
  static Stream<List<Map<String, dynamic>>> streamReservasCancha(
    String canchaId,
  ) {
    return _streamConsulta(
      _db
          .collection(reservasCollection)
          .where('canchaId', isEqualTo: canchaId)
          .where('activa', isEqualTo: true),
    ).map((lista) {
      return [...lista]..sort((a, b) {
        final dia = _enteroAdmin(a['dia']).compareTo(_enteroAdmin(b['dia']));
        if (dia != 0) return dia;
        return _enteroAdmin(a['horaInicio'])
            .compareTo(_enteroAdmin(b['horaInicio']));
      });
    });
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
            descripcion: AppStrings.txDeporteCreado(nombre),
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
            descripcion: AppStrings.txDeporteActualizado(nombreNuevo),
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
            descripcion: AppStrings.txDeporteEstado(
              activo ? 'Activó' : 'Desactivó',
              _textoODesconocido('${actual['nombre'] ?? ''}'),
            ),
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
                ? AppStrings.txEntrenadorDesasignado(
                    _textoODesconocido('${deporte.data()?['nombre'] ?? ''}'),
                  )
                : AppStrings.txEntrenadorAsignado(
                    entrenadorNombre,
                    _textoODesconocido('${deporte.data()?['nombre'] ?? ''}'),
                  ),
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
      'legible': true,
    };
  }

  static String _nombrePersona(Map<String, dynamic>? datos) {
    final nombre = '${datos?['nombre'] ?? ''}'.trim();
    final apellido = '${datos?['apellido'] ?? ''}'.trim();
    final completo = '$nombre $apellido'.trim();
    if (completo.isNotEmpty) return completo;
    final correo = '${datos?['correo'] ?? ''}'.trim();
    if (correo.isNotEmpty) return correo;
    return AppStrings.adminUsuarioDesconocido;
  }

  static String _textoODesconocido(String valor) {
    final limpio = valor.trim();
    return limpio.isEmpty ? AppStrings.adminRegistroNoDisponible : limpio;
  }

  static String _estadoInscripcionLegible(String estado) {
    return switch (estado) {
      'confirmada' => AppStrings.estadoConfirmada,
      'cancelada' => AppStrings.estadoCancelada,
      _ => AppStrings.estadoPendiente,
    };
  }

  static String _estadoEventoLegible(String estado) {
    return switch (estado) {
      'aprobado' => AppStrings.adminEventoAprobado,
      'rechazado' => AppStrings.adminEventoRechazado,
      'cancelado' => AppStrings.adminEventoCancelado,
      _ => AppStrings.estadoPendiente,
    };
  }

  static String _estadoPagoLegible(String estado) {
    return switch (estado) {
      'realizado' => AppStrings.adminPagoRealizado,
      'rechazado' => AppStrings.adminPagoRechazado,
      _ => AppStrings.adminPagoPendienteEtiqueta,
    };
  }

  static Future<Map<String, dynamic>?> leerDocumentoAdmin({
    required String coleccion,
    required String id,
  }) async {
    try {
      final doc = await _db.collection(coleccion).doc(id).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
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
          descripcion: AppStrings.txEntrenadorCreado(
            _nombrePersona(publico),
          ),
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
          descripcion: AppStrings.txEntrenadorActualizado(
            '$nombreNuevo $apellidoNuevo'.trim(),
          ),
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
      final perfil = await _db.collection(entrenadoresCollection).doc(uid).get();
      final usuario = await _db.collection(usuariosCollection).doc(uid).get();
      final nombre = _nombrePersona(usuario.data() ?? perfil.data());
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
          descripcion: AppStrings.txEntrenadorEstado(
            activo ? 'Activó' : 'Desactivó',
            nombre,
          ),
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
      final deporteId = '${datos['deporteId'] ?? ''}'.trim();
      var canchaNombre = '';
      var ignoroPractica = false;
      await _db.runTransaction((tx) async {
        final cancha = await tx.get(canchaRef);
        if (!cancha.exists || cancha.data()?['activa'] != true) {
          throw StateError('La cancha no existe o está inactiva');
        }
        canchaNombre = '${cancha.data()?['nombre'] ?? ''}';
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
        final choque = _exigirChoqueEvento(
          existentes,
          nueva,
          deporteId: deporteId,
        );
        ignoroPractica = choque.ignoroPractica;
        tx.set(eventoRef, {
          ...datos,
          'titulo': titulo,
          'deporteId': deporteId.isEmpty ? null : deporteId,
          'canchaId': canchaId,
          'canchaNombre': canchaNombre,
          'fecha': fecha,
          'horaInicio': horaInicio,
          'horaFin': horaFin,
          'estado': 'aprobado',
          'reemplazaPractica': ignoroPractica,
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
            descripcion: AppStrings.txEventoCreado(titulo),
          ),
        );
        tx.set(
          _db.collection('eventosPublicos').doc(eventoRef.id),
          _datosEventoPublico({
            ...datos,
            'titulo': titulo,
            'deporteId': deporteId,
            'canchaNombre': canchaNombre,
            'fecha': fecha,
            'horaInicio': horaInicio,
            'horaFin': horaFin,
          }),
        );
      });
      await _escribirNotificacionesEvento(
        eventoId: eventoRef.id,
        deporteId: deporteId,
        titulo: titulo,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        canchaNombre: canchaNombre,
        reemplazaPractica: ignoroPractica,
      );
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
      var estadoEvento = '';
      var cambioHorario = false;
      var deporteEvento = '';
      var tituloEvento = '';
      await _db.runTransaction((tx) async {
        final evento = await tx.get(eventoRef);
        if (!evento.exists) throw StateError('El evento no existe.');
        final actual = evento.data() ?? {};
        estadoEvento = '${actual['estado'] ?? ''}';
        deporteEvento = '${actual['deporteId'] ?? ''}';
        final titulo = datos.containsKey('titulo')
            ? '${datos['titulo']}'.trim()
            : '${actual['titulo'] ?? ''}';
        if (datos.containsKey('titulo') && titulo.isEmpty) {
          throw StateError('El título del evento es obligatorio.');
        }
        tituloEvento = titulo;
        final canchaNueva = canchaId ?? '${actual['canchaId'] ?? ''}';
        final fechaNueva = fecha ?? '${actual['fecha'] ?? ''}';
        final inicioNuevo = horaInicio ?? _enteroAdmin(actual['horaInicio']);
        final finNuevo = horaFin ?? _enteroAdmin(actual['horaFin']);
        final cambiaHorario =
            canchaId != null ||
            fecha != null ||
            horaInicio != null ||
            horaFin != null;
        cambioHorario = cambiaHorario;
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
            descripcion: AppStrings.txEventoActualizado(titulo),
          ),
        );
        if (estado == 'aprobado') {
          tx.set(
            _db.collection('eventosPublicos').doc(id),
            _datosEventoPublico({
              ...actual,
              ...cambios,
              'titulo': titulo,
              'canchaNombre': canchaNombre,
              'fecha': fechaNueva,
              'horaInicio': inicioNuevo,
              'horaFin': finNuevo,
            }),
          );
        }
      });
      if (estadoEvento == 'aprobado' && cambioHorario) {
        await _avisarInscritos(
          deporteId: deporteEvento,
          tipo: 'evento_modificado',
          titulo: AppStrings.tituloAvisoEvento,
          mensaje: AppStrings.avisoEventoModificado(tituloEvento),
          eventoId: id,
        );
      }
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
      var deporteAprobado = '';
      var tituloEvento = '';
      await _db.runTransaction((tx) async {
        final evento = await tx.get(eventoRef);
        if (!evento.exists) throw StateError('El evento no existe.');
        final actual = evento.data() ?? {};
        deporteAprobado = '${actual['deporteId'] ?? ''}'.trim();
        tituloEvento = '${actual['titulo'] ?? ''}';
        final creador = '${actual['creadoPorUid'] ?? ''}';
        final creadorDoc = creador.isEmpty
            ? null
            : await tx.get(_db.collection(usuariosCollection).doc(creador));
        final esEntrenador = creadorDoc?.data()?['rol'] == 'entrenador';
        final canchaId = '${actual['canchaId'] ?? ''}';
        final cancha = canchaId.isEmpty
            ? null
            : await tx.get(_db.collection(canchasCollection).doc(canchaId));
        final reservas = await _reservasDelEvento(id);
        final tituloAprobado = tituloEvento;
        if (estado == 'aprobado') {
          if (canchaId.isEmpty ||
              cancha == null ||
              !cancha.exists ||
              cancha.data()?['activa'] != true) {
            throw StateError(AppStrings.adminAsignaCancha);
          }
          final fecha = '${actual['fecha'] ?? ''}';
          final inicio = _enteroAdmin(actual['horaInicio']);
          final fin = _enteroAdmin(actual['horaFin']);
          final canchaNombre =
              '${actual['canchaNombre'] ?? cancha.data()?['nombre'] ?? ''}';
          final choque = _exigirChoqueEvento(
            await _ocupadas(canchaId),
            _reservaEvento(
              canchaId: canchaId,
              canchaNombre: canchaNombre,
              fecha: fecha,
              horaInicio: inicio,
              horaFin: fin,
              refId: id,
              refNombre: tituloAprobado,
            ),
            ignorarRefId: id,
            deporteId: deporteAprobado,
          );
          tx.update(eventoRef, {
            'estado': estado,
            'reemplazaPractica': choque.ignoroPractica,
          });
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
            descripcion: AppStrings.txEventoEstado(
              _estadoEventoLegible(estado),
              _textoODesconocido('${actual['titulo'] ?? ''}'),
            ),
          ),
        );
        final publico = _db.collection('eventosPublicos').doc(id);
        if (estado == 'aprobado') {
          tx.set(publico, _datosEventoPublico({...actual, 'estado': estado}));
        } else {
          tx.delete(publico);
        }
        if (esEntrenador &&
            creador != (_auth.currentUser?.uid ?? '') &&
            (estado == 'aprobado' || estado == 'rechazado')) {
          tx.set(
            _db.collection(notificacionesCollection).doc(),
            _aviso(
              destinatarioUid: creador,
              destinatarioRol: 'entrenador',
              tipo: estado == 'aprobado' ? 'evento_aprobado' : 'evento_rechazado',
              titulo: AppStrings.tituloAvisoEvento,
              mensaje: estado == 'aprobado'
                  ? AppStrings.avisoEventoAprobado('${actual['titulo'] ?? ''}')
                  : AppStrings.avisoEventoRechazado('${actual['titulo'] ?? ''}'),
              eventoId: id,
              deporteId: deporteAprobado,
            ),
          );
        }
      });
      if (estado == 'cancelado') {
        await _avisarInscritos(
          deporteId: deporteAprobado,
          tipo: 'evento_cancelado',
          titulo: AppStrings.tituloAvisoEvento,
          mensaje: AppStrings.avisoEventoCancelado(tituloEvento),
          eventoId: id,
          incluirEntrenador: true,
        );
      }
    });
  }

  static Future<AuthResponse> notificarInscritosEvento({
    required String deporteId,
    required String titulo,
    required String fecha,
    required int horaInicio,
    required int horaFin,
    required String canchaNombre,
    required bool reemplazaPractica,
    String eventoId = '',
  }) {
    return _ejecutarAdmin(
      () => _escribirNotificacionesEvento(
        eventoId: eventoId,
        deporteId: deporteId,
        titulo: titulo,
        fecha: fecha,
        horaInicio: horaInicio,
        horaFin: horaFin,
        canchaNombre: canchaNombre,
        reemplazaPractica: reemplazaPractica,
      ),
    );
  }

  static Future<void> _escribirNotificacionesEvento({
    required String eventoId,
    String? deporteId,
    required String titulo,
    required String fecha,
    required int horaInicio,
    required int horaFin,
    required String canchaNombre,
    required bool reemplazaPractica,
  }) async {
    final disciplina = (deporteId ?? '').trim();
    final inscritos = <String>{};
    if (disciplina.isNotEmpty) {
      final lista = await _db
          .collection(inscripcionesCollection)
          .where('deporteId', isEqualTo: disciplina)
          .get();
      for (final doc in lista.docs) {
        final estado = '${doc.data()['estado'] ?? ''}';
        if (estado != 'pendiente' && estado != 'confirmada') continue;
        final uid = '${doc.data()['estudianteUid'] ?? ''}';
        if (uid.isNotEmpty) inscritos.add(uid);
      }
    }
    final estudiantes = await _db
        .collection(usuariosCollection)
        .where('rol', isEqualTo: 'estudiante')
        .get();
    final avisos = <Map<String, dynamic>>[];
    for (final doc in estudiantes.docs) {
      if ('${doc.data()['estado'] ?? 'activo'}' == 'inactivo') continue;
      final propio = inscritos.contains(doc.id);
      avisos.add(
        _aviso(
          destinatarioUid: doc.id,
          destinatarioRol: 'estudiante',
          tipo: propio ? 'evento_confirmar' : 'evento_info',
          titulo: AppStrings.tituloAvisoEvento,
          mensaje: propio
              ? '${AppStrings.avisoEventoConfirmar(titulo, fecha)} ${AppStrings.avisoEventoConfirmaParticipacion}'
              : AppStrings.avisoEventoInfo(titulo, fecha),
          eventoId: eventoId,
          deporteId: disciplina,
        ),
      );
    }
    await _guardarAvisos(avisos);
  }

  static Map<String, dynamic> _aviso({
    required String destinatarioUid,
    required String destinatarioRol,
    required String tipo,
    required String titulo,
    required String mensaje,
    String origenUid = '',
    String inscripcionId = '',
    String pagoId = '',
    String eventoId = '',
    String ticketId = '',
    String deporteId = '',
  }) {
    return {
      'destinatarioUid': destinatarioUid,
      'destinatarioRol': destinatarioRol,
      'origenUid': origenUid,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'leida': false,
      'fecha': FieldValue.serverTimestamp(),
      'inscripcionId': inscripcionId,
      'pagoId': pagoId,
      'eventoId': eventoId,
      'ticketId': ticketId,
      'deporteId': deporteId,
    };
  }

  static Map<String, dynamic> _datosEventoPublico(Map<String, dynamic> datos) {
    return {
      'titulo': '${datos['titulo'] ?? ''}',
      'tipo': '${datos['tipo'] ?? 'evento'}',
      'deporteId': '${datos['deporteId'] ?? ''}',
      'deporteNombre': '${datos['deporteNombre'] ?? ''}',
      'canchaNombre': '${datos['canchaNombre'] ?? ''}',
      'fecha': '${datos['fecha'] ?? ''}',
      'horaInicio': _enteroAdmin(datos['horaInicio']),
      'horaFin': _enteroAdmin(datos['horaFin']),
      'descripcion': '${datos['descripcion'] ?? ''}',
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
  }

  static Future<void> _guardarAvisos(List<Map<String, dynamic>> avisos) async {
    if (avisos.isEmpty) return;
    var batch = _db.batch();
    var escritos = 0;
    for (final aviso in avisos) {
      batch.set(_db.collection(notificacionesCollection).doc(), aviso);
      escritos++;
      if (escritos == 400) {
        await batch.commit();
        batch = _db.batch();
        escritos = 0;
      }
    }
    if (escritos > 0) await batch.commit();
  }

  static Future<void> _avisarInscritos({
    required String deporteId,
    required String tipo,
    required String titulo,
    required String mensaje,
    required String eventoId,
    bool incluirEntrenador = false,
  }) async {
    final disciplina = deporteId.trim();
    if (disciplina.isEmpty) return;
    final avisos = <Map<String, dynamic>>[];
    final lista = await _db
        .collection(inscripcionesCollection)
        .where('deporteId', isEqualTo: disciplina)
        .get();
    for (final doc in lista.docs) {
      final estado = '${doc.data()['estado'] ?? ''}';
      if (estado != 'pendiente' && estado != 'confirmada') continue;
      final uid = '${doc.data()['estudianteUid'] ?? ''}';
      if (uid.isEmpty) continue;
      avisos.add(
        _aviso(
          destinatarioUid: uid,
          destinatarioRol: 'estudiante',
          tipo: tipo,
          titulo: titulo,
          mensaje: mensaje,
          eventoId: eventoId,
          deporteId: disciplina,
        ),
      );
    }
    if (incluirEntrenador) {
      final deporte = await _db.collection(deportesCollection).doc(disciplina).get();
      final entrenador = '${deporte.data()?['entrenadorUid'] ?? ''}';
      if (entrenador.isNotEmpty) {
        avisos.add(
          _aviso(
            destinatarioUid: entrenador,
            destinatarioRol: 'entrenador',
            tipo: tipo,
            titulo: titulo,
            mensaje: mensaje,
            eventoId: eventoId,
            deporteId: disciplina,
          ),
        );
      }
    }
    await _guardarAvisos(avisos);
  }

  static Stream<List<Map<String, dynamic>>> streamEventosPublicos({
    required String desdeFecha,
    int limite = 20,
  }) {
    return _streamConsultaEntrenador(
      _db
          .collection('eventosPublicos')
          .where('fecha', isGreaterThanOrEqualTo: desdeFecha)
          .orderBy('fecha')
          .limit(limite),
    );
  }

  static Stream<List<Map<String, dynamic>>> streamNotificacionesAdmin() {
    return _streamConsultaEntrenador(
      _db
          .collection(notificacionesCollection)
          .where('destinatarioRol', isEqualTo: 'administrador'),
    );
  }

  static Future<void> marcarAvisoAdminLeido({required String id}) async {
    await _db.collection(notificacionesCollection).doc(id).update({'leida': true});
  }

  static Future<void> responderParticipacionEvento({
    required String eventoId,
    required bool asistira,
    String? notificacionId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError(AppStrings.sesionNoIniciada);
    final batch = _db.batch();
    batch.set(
      _db.collection(eventosCollection).doc(eventoId).collection('participantes').doc(uid),
      {
        'estudianteUid': uid,
        'estado': asistira ? 'confirmado' : 'rechazado',
        'fecha': FieldValue.serverTimestamp(),
      },
    );
    if (notificacionId != null && notificacionId.isNotEmpty) {
      batch.update(
        _db.collection(notificacionesCollection).doc(notificacionId),
        {'leida': true},
      );
    }
    await batch.commit();
  }

  static Stream<String> streamParticipacion({
    required String eventoId,
    required String uid,
  }) {
    return _db
        .collection(eventosCollection)
        .doc(eventoId)
        .collection('participantes')
        .doc(uid)
        .snapshots()
        .map((doc) => '${doc.data()?['estado'] ?? ''}');
  }

  static Stream<List<Map<String, dynamic>>> streamParticipantesEvento({
    required String eventoId,
  }) {
    return _streamConsultaEntrenador(
      _db.collection(eventosCollection).doc(eventoId).collection('participantes'),
    );
  }

  static Future<void> sincronizarEventosPublicos() async {
    final hoy = DateTime.now();
    final desde =
        '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    final eventos = await _db
        .collection(eventosCollection)
        .where('estado', isEqualTo: 'aprobado')
        .get();
    final espejo = await _db.collection('eventosPublicos').get();
    final aprobados = <String>{};
    var batch = _db.batch();
    var escritos = 0;
    Future<void> cerrar() async {
      if (escritos == 0) return;
      await batch.commit();
      batch = _db.batch();
      escritos = 0;
    }

    for (final doc in eventos.docs) {
      final datos = doc.data();
      if ('${datos['fecha'] ?? ''}'.compareTo(desde) < 0) continue;
      aprobados.add(doc.id);
      batch.set(
        _db.collection('eventosPublicos').doc(doc.id),
        _datosEventoPublico(datos),
      );
      escritos++;
      if (escritos == 400) await cerrar();
    }
    for (final doc in espejo.docs) {
      if (aprobados.contains(doc.id)) continue;
      batch.delete(doc.reference);
      escritos++;
      if (escritos == 400) await cerrar();
    }
    await cerrar();
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
      final usuario = await _db.collection(usuariosCollection).doc(uid).get();
      final nombre = _nombrePersona(usuario.data());
      final batch = _db.batch();
      batch.update(_db.collection(usuariosCollection).doc(uid), {
        'estado': activo ? 'activo' : 'inactivo',
      });
      batch.set(
        _db.collection(transaccionesCollection).doc(),
        _datosTransaccion(
          accion: activo ? 'activar' : 'desactivar',
          modulo: 'estudiantes',
          descripcion: AppStrings.txEstudianteEstado(
            activo ? 'Activó' : 'Desactivó',
            nombre,
          ),
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
      final resena = await _db.collection(resenasCollection).doc(id).get();
      final datos = resena.data();
      await _db.collection(resenasCollection).doc(id).update({
        'visible': visible,
      });
      await registrarTransaccion(
        accion: visible ? 'mostrar' : 'ocultar',
        modulo: 'resenas',
        descripcion: AppStrings.txResenaVisibilidad(
          visible ? 'Mostró' : 'Ocultó',
          _textoODesconocido('${datos?['autorNombre'] ?? ''}'),
          _textoODesconocido('${datos?['disciplina'] ?? ''}'),
        ),
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
        final estudiante = await tx.get(
          _db.collection(usuariosCollection).doc('${datos['estudianteUid'] ?? ''}'),
        );
        final nombreEstudiante = _nombrePersona(estudiante.data());
        final deporteNombre = _textoODesconocido(
          '${datos['deporteNombre'] ?? deporte.data()?['nombre'] ?? ''}',
        );
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
        final estudianteUid = '${datos['estudianteUid'] ?? ''}';
        final tipoAviso = estado == 'confirmada'
            ? 'inscripcion_confirmada'
            : estado == 'cancelada'
            ? 'inscripcion_cancelada_admin'
            : 'inscripcion_pendiente_admin';
        final mensajeAviso = estado == 'confirmada'
            ? AppStrings.avisoInscripcionConfirmada(deporteNombre)
            : estado == 'cancelada'
            ? AppStrings.avisoInscripcionCanceladaAdmin(deporteNombre)
            : AppStrings.avisoInscripcionPendienteAdminEstudiante(deporteNombre);
        if (estudianteUid.isNotEmpty) {
          tx.set(
            _db.collection(notificacionesCollection).doc(),
            _aviso(
              destinatarioUid: estudianteUid,
              destinatarioRol: 'estudiante',
              tipo: tipoAviso,
              titulo: AppStrings.tituloAvisoInscripcion,
              mensaje: mensajeAviso,
              inscripcionId: id,
              deporteId: '${datos['deporteId'] ?? ''}',
            ),
          );
        }
        final entrenadorUid = '${deporte.data()?['entrenadorUid'] ?? ''}';
        if (estado == 'confirmada' && entrenadorUid.isNotEmpty) {
          tx.set(
            _db.collection(notificacionesCollection).doc(),
            _aviso(
              destinatarioUid: entrenadorUid,
              destinatarioRol: 'entrenador',
              tipo: 'alumno_confirmado',
              titulo: AppStrings.tituloAvisoInscripcion,
              mensaje: AppStrings.avisoAlumnoConfirmado(
                nombreEstudiante,
                deporteNombre,
              ),
              inscripcionId: id,
              deporteId: '${datos['deporteId'] ?? ''}',
            ),
          );
        }
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: estado,
            modulo: 'inscripciones',
            descripcion: AppStrings.txInscripcionEstado(
              _estadoInscripcionLegible(estado),
              nombreEstudiante,
              deporteNombre,
            ),
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

  static ResultadoChoqueEvento _exigirChoqueEvento(
    List<ReservaHorario> existentes,
    ReservaHorario nueva, {
    String? ignorarRefId,
    String? deporteId,
  }) {
    final resultado = evaluarChoqueEvento(
      nuevas: [nueva],
      existentes: existentes,
      ignorarRefId: ignorarRefId,
      deporteId: deporteId,
    );
    if (resultado.choque != null) {
      throw StateError(mensajeChoque(resultado.choque!));
    }
    return resultado;
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
    String? periodo,
  }) {
    return _ejecutarAdmin(() async {
      final pagoRef = _db.collection(pagosCollection).doc(pagoId);
      final configRef = _db.collection(configuracionCollection).doc('pagos');
      await _db.runTransaction((tx) async {
        final pago = await tx.get(pagoRef);
        if (!pago.exists) throw StateError('El pago no existe.');
        final datos = pago.data() ?? {};
        final uid = '${datos['estudianteUid'] ?? ''}'.trim();
        final monto = _numeroAdmin(datos['monto']);
        final config = await tx.get(configRef);
        final periodoConfig = '${config.data()?['periodo'] ?? ''}'.trim();
        final montoEsperado = _numeroAdmin(config.data()?['monto']);
        final periodoPago = (periodo ?? '${datos['periodo'] ?? ''}').trim();
        final estudiante = uid.isEmpty
            ? null
            : await tx.get(_db.collection(usuariosCollection).doc(uid));
        final nombreEstudiante = _nombrePersona(estudiante?.data());
        final concede = verificado &&
            AdminSolvencia.datosValidos(
              uidPago: uid,
              uid: uid,
              periodoPago: periodoPago.isEmpty ? null : periodoPago,
              periodo: periodoConfig,
              estado: 'realizado',
              verificado: true,
              fechaPago: fechaPago,
              monto: monto,
              montoEsperado: montoEsperado,
            );
        final cambios = <String, dynamic>{
          'paypalOrderId': paypalOrderId,
          'idTransaccion': paypalOrderId,
          'fechaPago': fechaPago,
          'verificado': verificado,
          'verificadoPor': verificadoPor,
          'verificadoEn': FieldValue.serverTimestamp(),
          'estado': verificado ? 'realizado' : 'pendiente',
        };
        if (periodoPago.isNotEmpty) cambios['periodo'] = periodoPago;
        tx.update(pagoRef, cambios);
        if (concede) {
          tx.update(_db.collection(usuariosCollection).doc(uid), {
            'solvente': true,
          });
        }
        if (verificado && uid.isNotEmpty) {
          tx.set(
            _db.collection(notificacionesCollection).doc(),
            _aviso(
              destinatarioUid: uid,
              destinatarioRol: 'estudiante',
              tipo: 'pago_verificado',
              titulo: AppStrings.tituloAvisoPago,
              mensaje: AppStrings.avisoPagoVerificado(periodoPago),
              pagoId: pagoId,
            ),
          );
        }
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: verificado ? 'verificar' : 'rechazar',
            modulo: 'pagos',
            descripcion: concede
                ? AppStrings.txPagoVerificado(
                    nombreEstudiante,
                    periodoPago,
                    '$monto',
                  )
                : AppStrings.txPagoSinSolvencia(nombreEstudiante, periodoPago),
          ),
        );
      });
    });
  }

  static Future<AuthResponse> aplicarCorteEstudiante({
    required String uid,
    required String periodo,
    required DateTime fechaCorte,
    required double monto,
  }) async {
    try {
      final userRef = _db.collection(usuariosCollection).doc(uid);
      final avisoRef = _db.collection(notificacionesCollection).doc(
        'pago-$periodo-$uid',
      );
      final conocidos = await _db
          .collection(pagosCollection)
          .where('estudianteUid', isEqualTo: uid)
          .get();
      var solvente = false;
      var avisoCreado = false;
      await _db.runTransaction((tx) async {
        solvente = false;
        avisoCreado = false;
        final usuario = await tx.get(userRef);
        if (!usuario.exists) throw StateError('El estudiante no existe.');
        final datosUsuario = usuario.data() ?? {};
        final activo = '${datosUsuario['estado'] ?? 'activo'}' != 'inactivo';
        if (!activo) return;
        final aviso = await tx.get(avisoRef);
        var valido = false;
        for (final doc in conocidos.docs) {
          final actual = await tx.get(doc.reference);
          if (!actual.exists) continue;
          final datos = actual.data() ?? {};
          if (AdminSolvencia.datosValidos(
            uidPago: '${datos['estudianteUid'] ?? ''}',
            uid: uid,
            periodoPago: _periodoAdmin(datos['periodo']),
            periodo: periodo,
            estado: '${datos['estado'] ?? ''}',
            verificado: datos['verificado'] == true,
            fechaPago: _fechaAdmin(datos['fechaPago']),
            monto: _numeroAdmin(datos['monto']),
            montoEsperado: monto,
          )) {
            valido = true;
            break;
          }
        }
        solvente = valido;
        tx.update(userRef, {'solvente': valido});
        if (!valido && !aviso.exists) {
          avisoCreado = true;
          tx.set(avisoRef, {
            'destinatarioUid': uid,
            'tipo': 'pago_pendiente',
            'titulo': 'Pago pendiente',
            'mensaje':
                'Tu pago del período $periodo está pendiente. Debes pagarlo para recuperar la solvencia.',
            'periodo': periodo,
            'leida': false,
            'fecha': FieldValue.serverTimestamp(),
          });
        }
        tx.set(
          _db.collection(transaccionesCollection).doc(),
          _datosTransaccion(
            accion: valido ? 'corte_solvente' : 'corte_insolvente',
            modulo: 'pagos',
            descripcion: valido
                ? AppStrings.txCorteSolvente(_nombrePersona(datosUsuario))
                : AppStrings.txCorteInsolvente(_nombrePersona(datosUsuario)),
          ),
        );
      });
      return AuthResponse(
        isSuccess: true,
        errorMessage: avisoCreado
            ? 'aviso_creado'
            : solvente
            ? 'solvente'
            : null,
      );
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

  static Future<AuthResponse> cambiarEstadoPago({
    required String pagoId,
    required String estado,
  }) {
    return _ejecutarAdmin(() async {
      const validos = ['pendiente', 'realizado', 'rechazado'];
      if (!validos.contains(estado)) {
        throw StateError('El estado del pago no es válido.');
      }
      final pago = await _db.collection(pagosCollection).doc(pagoId).get();
      final datosPago = pago.data();
      final estudianteUid = '${datosPago?['estudianteUid'] ?? ''}';
      final usuario = estudianteUid.isEmpty
          ? null
          : await _db.collection(usuariosCollection).doc(estudianteUid).get();
      final cambios = <String, dynamic>{
        'estado': estado,
        'verificado': estado == 'realizado',
      };
      if (estado != 'realizado') cambios['verificadoPor'] = '';
      final batch = _db.batch();
      batch.update(_db.collection(pagosCollection).doc(pagoId), cambios);
      if (estado == 'rechazado' && estudianteUid.isNotEmpty) {
        batch.set(
          _db.collection(notificacionesCollection).doc(),
          _aviso(
            destinatarioUid: estudianteUid,
            destinatarioRol: 'estudiante',
            tipo: 'pago_rechazado',
            titulo: AppStrings.tituloAvisoPago,
            mensaje: AppStrings.avisoPagoRechazado(
              '${datosPago?['periodo'] ?? ''}'.trim(),
            ),
            pagoId: pagoId,
          ),
        );
      }
      await batch.commit();
      await registrarTransaccion(
        accion: estado == 'rechazado' ? 'rechazar' : 'marcar_pendiente',
        modulo: 'pagos',
        descripcion: AppStrings.txPagoEstado(
          _estadoPagoLegible(estado),
          _nombrePersona(usuario?.data()),
          '${datosPago?['periodo'] ?? ''}'.trim(),
        ),
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
          descripcion: AppStrings.txFechaCorte(periodo.trim()),
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
      final usuario = await _db.collection(usuariosCollection).doc(uid).get();
      await _db.collection(usuariosCollection).doc(uid).update({
        'solvente': solvente,
      });
      await registrarTransaccion(
        accion: solvente ? 'marcar_solvente' : 'marcar_insolvente',
        modulo: 'estudiantes',
        descripcion: AppStrings.txSolvencia(
          solvente ? 'Marcó solvente' : 'Marcó insolvente',
          _nombrePersona(usuario.data()),
        ),
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
      final ticket = await _db.collection(ticketsCollection).doc(id).get();
      final datosTicket = ticket.data();
      final cambios = <String, dynamic>{'respuesta': texto};
      if (resolver) {
        cambios['estado'] = 'resuelto';
        cambios['resueltoEn'] = FieldValue.serverTimestamp();
      }
      final batch = _db.batch();
      batch.update(_db.collection(ticketsCollection).doc(id), cambios);
      final autorUid = '${datosTicket?['autorUid'] ?? ''}';
      if (autorUid.isNotEmpty) {
        batch.set(
          _db.collection(notificacionesCollection).doc(),
          _aviso(
            destinatarioUid: autorUid,
            destinatarioRol: '${datosTicket?['autorRol'] ?? 'estudiante'}',
            tipo: 'ticket_respondido',
            titulo: AppStrings.tituloAvisoTicket,
            mensaje: AppStrings.avisoTicketRespondido(
              '${datosTicket?['asunto'] ?? ''}',
            ),
            ticketId: id,
          ),
        );
      }
      await batch.commit();
      await registrarTransaccion(
        accion: resolver ? 'resolver' : 'responder',
        modulo: 'soporte',
        descripcion: AppStrings.txTicketRespondido(
          _textoODesconocido('${datosTicket?['asunto'] ?? ''}'),
          _textoODesconocido('${datosTicket?['autorNombre'] ?? ''}'),
        ),
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

  static Future<Map<String, dynamic>> resumenGraficosAdmin() async {
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month - 5, 1);
    final deportes = await _db.collection(deportesCollection).get();
    final populares = deportes.docs
        .map(
          (doc) => {
            'nombre': '${doc.data()['nombre'] ?? ''}',
            'inscritos': _enteroAdmin(doc.data()['inscritos']),
          },
        )
        .toList()
      ..sort(
        (a, b) => (b['inscritos'] as int).compareTo(a['inscritos'] as int),
      );
    final meses = <String, int>{};
    for (var i = 0; i < 6; i++) {
      final fecha = DateTime(inicio.year, inicio.month + i);
      final clave =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
      meses[clave] = 0;
    }
    final inscripciones = await _db.collection(inscripcionesCollection).get();
    for (final doc in inscripciones.docs) {
      final fecha = _fechaAdmin(doc.data()['fecha']);
      if (fecha == null || fecha.isBefore(inicio)) continue;
      final clave =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
      if (meses.containsKey(clave)) meses[clave] = meses[clave]! + 1;
    }
    final resenas = await _db.collection(resenasCollection).get();
    var suma = 0;
    var cantidad = 0;
    for (final doc in resenas.docs) {
      if (doc.data()['visible'] == false) continue;
      suma += _enteroAdmin(doc.data()['estrellas']);
      cantidad++;
    }
    return {
      'deportesPopulares': populares.take(5).toList(),
      'inscripcionesPorMes': [
        for (final entrada in meses.entries)
          {'mes': entrada.key, 'total': entrada.value},
      ],
      'resenasCantidad': cantidad,
      'resenasPromedio': cantidad == 0
          ? 0
          : (suma / cantidad * 10).round() / 10,
    };
  }

  static double _numeroAdmin(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse('$valor') ?? 0;
  }

  static String? _periodoAdmin(dynamic valor) {
    if (valor is! String) return null;
    final texto = valor.trim();
    return texto.isEmpty ? null : texto;
  }

  static DateTime? _fechaAdmin(dynamic valor) {
    if (valor is DateTime) return valor;
    if (valor is String) return DateTime.tryParse(valor);
    try {
      final convertida = (valor as dynamic).toDate();
      if (convertida is DateTime) return convertida;
    } catch (_) {}
    return null;
  }

  static Future<num> _contar(Query<Map<String, dynamic>> consulta) async {
    try {
      final snapshot = await consulta.count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Suma en Dart: sum('monto') con filtro exige un índice compuesto.
  static Future<num> _sumarIngresos() async {
    try {
      final snapshot = await _db
          .collection(pagosCollection)
          .where('estado', isEqualTo: 'realizado')
          .get();
      var total = 0.0;
      for (final doc in snapshot.docs) {
        total += _numeroAdmin(doc.data()['monto']);
      }
      return total;
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
