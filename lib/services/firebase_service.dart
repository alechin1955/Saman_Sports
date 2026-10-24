import 'package:cloud_firestore/cloud_firestore.dart';

// Patrón Singleton: Única instancia de conexión a la BD
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();
}