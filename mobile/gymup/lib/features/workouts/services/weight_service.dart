import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeightService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveWeight(String exerciseId, double weight, int reps, String note) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    await _db
        .collection('alunos')
        .doc(user.uid)
        .collection('cargas')
        .doc(exerciseId)
        .collection('historico')
        .doc(timestamp)
        .set({
      'peso': weight,
      'reps': reps,
      'observacao': note,
      'data': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getLastWeight(String exerciseId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snapshot = await _db
        .collection('alunos')
        .doc(user.uid)
        .collection('cargas')
        .doc(exerciseId)
        .collection('historico')
        .orderBy('data', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }
}
