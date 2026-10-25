import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseServices {
  static Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
  static Future<Map<String, dynamic>?> getUserData({required String uid}) async {
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

  static Stream<List<Map<String, dynamic>>> streamDeportes() {
    return _streamConsulta(
      _db.collection(deportesCollection).where('activo', isEqualTo: true).orderBy('nombre'),
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
    return consulta.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
          .toList();
    }).transform(
      StreamTransformer<List<Map<String, dynamic>>, List<Map<String, dynamic>>>.fromHandlers(
        handleError: (error, stack, sink) => sink.add(const []),
      ),
    );
  }

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
}


class AuthResponse {
  final UserCredential? credential;
  final String? errorMessage;
  final bool isSuccess;

  AuthResponse({this.credential, this.errorMessage, required this.isSuccess});
}