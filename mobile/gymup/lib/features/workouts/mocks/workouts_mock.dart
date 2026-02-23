import '../models/workout_model.dart';

class WorkoutsMock {
  static final List<WorkoutModel> standardWorkouts = [
    WorkoutModel(
      id: 'treino_a',
      nome: 'Treino A – Peito e Tríceps',
      descricao: 'Foco em empurrar e força superior.',
      duracao: '45 min',
      nivel: 'Intermediário',
      exercicios: [
        ExerciseModel(
          nome: 'Supino Reto',
          descricao: 'Deite-se no banco e empurre a barra para cima.',
          tempoExecucao: 45,
          tempoDescanso: 60,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
        ),
        ExerciseModel(
          nome: 'Supino Inclinado com Halteres',
          descricao: 'Banco inclinado a 30-45 graus.',
          tempoExecucao: 45,
          tempoDescanso: 60,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=07D2xdNcUo8',
        ),
        ExerciseModel(
          nome: 'Tríceps Pulley',
          descricao: 'Use a corda ou barra reta.',
          tempoExecucao: 45,
          tempoDescanso: 45,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=6kALZikXxLc',
        ),
      ],
    ),
    WorkoutModel(
      id: 'treino_b',
      nome: 'Treino B – Costas e Bíceps',
      descricao: 'Foco em puxar e largura das costas.',
      duracao: '50 min',
      nivel: 'Intermediário',
      exercicios: [
        ExerciseModel(
          nome: 'Puxada Alta',
          descricao: 'Puxe a barra até a altura do peito.',
          tempoExecucao: 45,
          tempoDescanso: 60,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=CAwf7n6Luuc',
        ),
        ExerciseModel(
          nome: 'Remada Curvada',
          descricao: 'Mantenha a coluna reta.',
          tempoExecucao: 45,
          tempoDescanso: 60,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=G8l_8chR5BE',
        ),
        ExerciseModel(
          nome: 'Rosca Direta',
          descricao: 'Use barra W ou reta.',
          tempoExecucao: 45,
          tempoDescanso: 45,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=i1YgFZB6alI',
        ),
      ],
    ),
    WorkoutModel(
      id: 'treino_c',
      nome: 'Treino C – Pernas',
      descricao: 'Treino completo de membros inferiores.',
      duracao: '60 min',
      nivel: 'Avançado',
      exercicios: [
        ExerciseModel(
          nome: 'Agachamento Livre',
          descricao: 'Desça até quebrar a paralela.',
          tempoExecucao: 60,
          tempoDescanso: 90,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=U3HlEF_E9fo',
        ),
        ExerciseModel(
          nome: 'Leg Press 45',
          descricao: 'Não trave os joelhos na subida.',
          tempoExecucao: 60,
          tempoDescanso: 60,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=yZ961lZplQI',
        ),
        ExerciseModel(
          nome: 'Cadeira Extensora',
          descricao: 'Segure 1s no topo.',
          tempoExecucao: 45,
          tempoDescanso: 45,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=YyvSfVjQeL0',
        ),
      ],
    ),
    WorkoutModel(
      id: 'full_body',
      nome: 'Full Body – Iniciante',
      descricao: 'Treino para o corpo todo, ideal para começar.',
      duracao: '40 min',
      nivel: 'Iniciante',
      exercicios: [
        ExerciseModel(
          nome: 'Agachamento (Peso do corpo)',
          descricao: 'Use uma cadeira como referência se precisar.',
          tempoExecucao: 45,
          tempoDescanso: 45,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=U3HlEF_E9fo',
        ),
        ExerciseModel(
          nome: 'Flexão de Braços',
          descricao: 'Apoie os joelhos se for difícil.',
          tempoExecucao: 45,
          tempoDescanso: 45,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=IODxDxX7oi4',
        ),
        ExerciseModel(
          nome: 'Prancha Abdominal',
          descricao: 'Mantenha o corpo alinhado.',
          tempoExecucao: 30,
          tempoDescanso: 30,
          linkVideoYoutube: 'https://www.youtube.com/watch?v=pSHjTRCQxIw',
        ),
      ],
    ),
  ];
}
