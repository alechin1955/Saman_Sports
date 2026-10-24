// Patrón Repositorio: Centraliza las operaciones CRUD
import '../models/sport_model.dart';
import '../services/firebase_service.dart';

class SportRepository {
  final _collection = FirebaseService().db.collection('disciplines');

  Stream<List<SportModel>> getSportsStream() {
    return _collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => SportModel.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<void> addSport(SportModel sport) => _collection.add(sport.toMap());

  Future<void> updateSport(String id, Map<String, dynamic> data) =>
      _collection.doc(id).update(data);

  Future<void> deleteSport(String id) => _collection.doc(id).delete();
}