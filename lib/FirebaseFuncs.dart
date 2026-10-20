import 'package:firebase_auth/firebase_auth.dart';

class FirebaseFunctions {
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
}

class AuthResponse {
  final UserCredential? credential;
  final String? errorMessage;
  final bool isSuccess;

  AuthResponse({this.credential, this.errorMessage, required this.isSuccess});
}