import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart';

class WorkoutAiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simulates AI generation for now
  Future<WorkoutModel> gerarTreinoIA({
    required String objetivo,
    required String nivel,
    required int tempo,
    required List<String> equipamentos,
    double? pesoAtual,
    double? pesoPretendido,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // Mock response based on input (simple logic for demo)
    final isHipertrofia = objetivo.toLowerCase().contains('hipertrofia');

    final exercicios = <ExerciseModel>[];

    if (isHipertrofia) {
      exercicios.add(
        ExerciseModel(
          nome: 'Supino Reto',
          descricao:
              'Foco na contração do peitoral. Mantenha os cotovelos levemente fechados.',
          linkVideoYoutube: 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
          tempoExecucao: 45,
          tempoDescanso: 60,
          carga: 0,
          sets: [
            WorkoutSet(number: 1, weight: 20, reps: 12),
            WorkoutSet(number: 2, weight: 20, reps: 12),
            WorkoutSet(number: 3, weight: 20, reps: 12),
          ],
        ),
      );
      exercicios.add(
        ExerciseModel(
          nome: 'Agachamento Livre',
          descricao: 'Mantenha a postura correta e desça até 90 graus.',
          linkVideoYoutube: 'https://www.youtube.com/watch?v=U3HlEF_E9fo',
          tempoExecucao: 60,
          tempoDescanso: 90,
          carga: 0,
          sets: [
            WorkoutSet(number: 1, weight: 40, reps: 10),
            WorkoutSet(number: 2, weight: 40, reps: 10),
            WorkoutSet(number: 3, weight: 40, reps: 10),
          ],
        ),
      );
    } else {
      // Emagrecimento / Condicionamento
      exercicios.add(
        ExerciseModel(
          nome: 'Polichinelos',
          descricao: 'Aqueça bem o corpo. Mantenha o ritmo constante.',
          linkVideoYoutube: 'https://www.youtube.com/watch?v=c4DAnQ6DtF8',
          tempoExecucao: 60,
          tempoDescanso: 30,
          carga: 0,
          sets: [
            WorkoutSet(number: 1, weight: 0, reps: 50),
            WorkoutSet(number: 2, weight: 0, reps: 50),
            WorkoutSet(number: 3, weight: 0, reps: 50),
          ],
        ),
      );
      exercicios.add(
        ExerciseModel(
          nome: 'Burpees',
          descricao: 'Explosão na subida. Cuidado com a lombar.',
          linkVideoYoutube: 'https://www.youtube.com/watch?v=TU8QYXL8gEQ',
          tempoExecucao: 45,
          tempoDescanso: 45,
          carga: 0,
          sets: [
            WorkoutSet(number: 1, weight: 0, reps: 15),
            WorkoutSet(number: 2, weight: 0, reps: 15),
            WorkoutSet(number: 3, weight: 0, reps: 15),
          ],
        ),
      );
    }

    // Add common exercises
    exercicios.add(
      ExerciseModel(
        nome: 'Prancha Abdominal',
        descricao: 'Fortalecimento do core. Mantenha o corpo alinhado.',
        linkVideoYoutube: 'https://www.youtube.com/watch?v=pSHjTRCQxIw',
        tempoExecucao: 60,
        tempoDescanso: 30,
        carga: 0,
        sets: [
          WorkoutSet(
            number: 1,
            weight: 0,
            reps: 60,
          ), // seconds usually, but using reps field for simplicity or 1 rep
          WorkoutSet(number: 2, weight: 0, reps: 60),
          WorkoutSet(number: 3, weight: 0, reps: 60),
        ],
      ),
    );

    return WorkoutModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: 'Treino Personalizado IA',
      descricao:
          'Objetivo: $objetivo | Nível: $nivel | Peso: ${pesoAtual ?? "N/A"}kg -> ${pesoPretendido ?? "N/A"}kg',
      duracao: '$tempo',
      nivel: nivel,
      exercicios: exercicios,
      isGenerated: true,
    );
  }

  Future<void> saveWorkout(WorkoutModel workout) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    await _db
        .collection('alunos')
        .doc(user.uid)
        .collection('treinosPersonalizados')
        .doc(workout.id)
        .set(workout.toMap());
  }

  Stream<List<WorkoutModel>> getCustomWorkouts() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('alunos')
        .doc(user.uid)
        .collection('treinosPersonalizados')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return WorkoutModel.fromMap(doc.data());
          }).toList();
        });
  }

  Future<void> deleteExercise(String workoutId, ExerciseModel exercise) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db
        .collection('alunos')
        .doc(user.uid)
        .collection('treinosPersonalizados')
        .doc(workoutId);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final workoutData = snapshot.data()!;
    final workout = WorkoutModel.fromMap(workoutData);

    // Remove the exercise
    final updatedExercises = workout.exercicios
        .where((e) => e.nome != exercise.nome)
        .toList();

    // Update Firestore
    await docRef.update({
      'exercicios': updatedExercises.map((e) => e.toMap()).toList(),
    });
  }
}
