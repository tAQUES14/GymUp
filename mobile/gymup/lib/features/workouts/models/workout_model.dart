class WorkoutSet {
  final int number;
  double weight;
  int reps;
  bool isCompleted;

  WorkoutSet({
    required this.number,
    required this.weight,
    required this.reps,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'weight': weight,
      'reps': reps,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      number: map['number'] ?? 1,
      weight: (map['weight'] ?? 0).toDouble(),
      reps: map['reps'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

class ExerciseModel {
  final String nome;
  final String descricao;
  final String? icone;
  final String linkVideoYoutube;
  final int tempoExecucao;
  final int tempoDescanso;
  double carga; // Editável pelo usuário
  List<WorkoutSet> sets; // Lista de séries

  ExerciseModel({
    required this.nome,
    required this.descricao,
    this.icone,
    this.linkVideoYoutube = '',
    this.tempoExecucao = 45,
    this.tempoDescanso = 20,
    this.carga = 0.0,
    List<WorkoutSet>? sets,
  }) : sets = sets ?? [];

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'icone': icone,
      'linkVideoYoutube': linkVideoYoutube,
      'tempoExecucao': tempoExecucao,
      'tempoDescanso': tempoDescanso,
      'carga': carga,
      'sets': sets.map((x) => x.toMap()).toList(),
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    var setsList = <WorkoutSet>[];
    if (map['sets'] != null) {
      setsList = List<WorkoutSet>.from(
        (map['sets'] as List<dynamic>).map<WorkoutSet>(
          (x) => WorkoutSet.fromMap(x as Map<String, dynamic>),
        ),
      );
    } else {
      // Default sets for prototype if none exist
      setsList = List.generate(
        3,
        (index) => WorkoutSet(
          number: index + 1,
          weight: (map['carga'] ?? 0).toDouble(),
          reps: 12, // Default reps
        ),
      );
    }

    return ExerciseModel(
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      icone: map['icone'],
      linkVideoYoutube: map['linkVideoYoutube'] ?? '',
      tempoExecucao: map['tempoExecucao'] ?? 45,
      tempoDescanso: map['tempoDescanso'] ?? 20,
      carga: (map['carga'] ?? 0).toDouble(),
      sets: setsList,
    );
  }
}

class WorkoutModel {
  final String id;
  final String nome;
  final String descricao;
  final String duracao;
  final String nivel;
  final List<ExerciseModel> exercicios;
  final bool isGenerated;

  WorkoutModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.duracao,
    required this.nivel,
    required this.exercicios,
    this.isGenerated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'duracao': duracao,
      'nivel': nivel,
      'exercicios': exercicios.map((x) => x.toMap()).toList(),
      'isGenerated': isGenerated,
    };
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      duracao: map['duracao']?.toString() ?? '',
      nivel: map['nivel'] ?? '',
      exercicios: List<ExerciseModel>.from(
        (map['exercicios'] as List<dynamic>? ?? []).map<ExerciseModel>(
          (x) => ExerciseModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      isGenerated: map['isGenerated'] ?? false,
    );
  }
}
