import 'package:firebase_auth/firebase_auth.dart';

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
}

class AuthResponse {
  final UserCredential? credential;
  final String? errorMessage;
  final bool isSuccess;

  AuthResponse({this.credential, this.errorMessage, required this.isSuccess});
}