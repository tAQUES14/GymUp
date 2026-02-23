import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gymup_button.dart';
import '../../../../core/widgets/gymup_card.dart';
import '../../../../core/widgets/gymup_text_field.dart';
import '../checkin/checkin_page.dart';
import 'models/workout_model.dart';
import 'services/weight_service.dart';
import 'widgets/workout_header.dart';
import 'widgets/workout_timer.dart';

class WorkoutStepPage extends StatefulWidget {
  const WorkoutStepPage({super.key});

  @override
  State<WorkoutStepPage> createState() => _WorkoutStepPageState();
}

class _WorkoutStepPageState extends State<WorkoutStepPage> {
  int _currentExerciseIndex = 0;
  bool _isResting = false;
  bool _canGoNext = false;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();

  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExerciseData();
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _obsController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _loadExerciseData() {
    final workout = ModalRoute.of(context)!.settings.arguments as WorkoutModel;
    if (_currentExerciseIndex >= workout.exercicios.length) return;

    final currentExercise = workout.exercicios[_currentExerciseIndex];

    // Load Video
    if (currentExercise.linkVideoYoutube.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(
        currentExercise.linkVideoYoutube,
      );
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        );
      }
    } else {
      _youtubeController = null;
    }

    // Load Weight
    _loadLastWeight(currentExercise);
  }

  Future<void> _loadLastWeight(ExerciseModel exercise) async {
    final exerciseId = exercise.nome.toLowerCase().replaceAll(' ', '_');
    final weightService = Provider.of<WeightService>(context, listen: false);
    final lastData = await weightService.getLastWeight(exerciseId);

    if (lastData != null && mounted) {
      // Show last weight as hint or initial value? Prompt says "Mostrar ao aluno: Última carga usada: XX kg"
      // And "Permitir inserir nova carga: Peso atual (kg): [input]"
      // So I will set the text to the last weight for convenience, or just show it.
      // I'll set it as text.
      setState(() {
        _weightController.text = lastData['peso'].toString();
      });
    } else {
      _weightController.clear();
    }
    _obsController.clear();
  }

  Future<void> _saveWeight() async {
    final workout = ModalRoute.of(context)!.settings.arguments as WorkoutModel;
    final currentExercise = workout.exercicios[_currentExerciseIndex];
    final exerciseId = currentExercise.nome.toLowerCase().replaceAll(' ', '_');

    final weight = double.tryParse(_weightController.text) ?? 0;
    final obs = _obsController.text;

    final weightService = Provider.of<WeightService>(context, listen: false);
    // Reps is 0 as per requirement "Nenhum dado de séries deve ser salvo" (but function signature might need it, passing 0)
    await weightService.saveWeight(exerciseId, weight, 0, obs);
  }

  void _finishExecution() {
    _saveWeight();
    setState(() {
      _isResting = true;
      _canGoNext = false; // Wait for rest
    });
  }

  void _finishRest() {
    setState(() {
      _canGoNext = true;
    });
  }

  void _nextExercise() {
    final workout = ModalRoute.of(context)!.settings.arguments as WorkoutModel;
    if (_currentExerciseIndex < workout.exercicios.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _isResting = false;
        _canGoNext = false;
        _youtubeController?.dispose();
        _youtubeController = null;
      });
      _loadExerciseData();
    } else {
      _finishWorkout();
    }
  }

  void _skipExercise() {
    _nextExercise();
  }

  Future<void> _finishWorkout() async {
    // Navigate to QR Check-in
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CheckinPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workout = ModalRoute.of(context)!.settings.arguments as WorkoutModel;
    final exercises = workout.exercicios;
    final currentExercise = exercises[_currentExerciseIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WorkoutHeader(title: _isResting ? 'Descanso' : 'Execução'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Exercise Info
                  Text(
                    currentExercise.nome,
                    style: AppTypography.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentExercise.descricao,
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Video Player
                  if (_youtubeController != null && !_isResting)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: AppColors.primary,
                        ),
                      ),
                    ),

                  // Load Input (Only during execution)
                  if (!_isResting) ...[
                    GymUpCard(
                      child: Column(
                        children: [
                          GymUpTextField(
                            label: 'Carga (kg)',
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            hintText: '0.0',
                          ),
                          const SizedBox(height: 12),
                          GymUpTextField(
                            label: 'Observação (opcional)',
                            controller: _obsController,
                            hintText: 'Ex: Fácil, difícil...',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Timer Area
                  GymUpCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          _isResting
                              ? 'Tempo de Descanso'
                              : 'Tempo de Execução',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 16),
                        WorkoutTimer(
                          key: ValueKey(
                            '${_currentExerciseIndex}_${_isResting ? "rest" : "exec"}',
                          ),
                          defaultTime: _isResting
                              ? (currentExercise.tempoDescanso > 0
                                    ? currentExercise.tempoDescanso
                                    : 20)
                              : (currentExercise.tempoExecucao > 0
                                    ? currentExercise.tempoExecucao
                                    : 45),
                          isRest: _isResting,
                          onTimerComplete: _isResting
                              ? _finishRest
                              : _finishExecution,
                          autoStart: _isResting, // Auto start only for rest
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  if (_isResting) ...[
                    if (!_canGoNext)
                      GymUpButton(
                        label: 'PULAR DESCANSO',
                        onPressed: _finishRest,
                        isSecondary: true,
                      ),
                    if (_canGoNext)
                      GymUpButton(
                        label: _currentExerciseIndex < exercises.length - 1
                            ? 'PRÓXIMO EXERCÍCIO'
                            : 'FINALIZAR TREINO',
                        onPressed: _nextExercise,
                      ),
                  ] else ...[
                    GymUpButton(
                      label: 'CONCLUIR SEM TIMER',
                      onPressed: _finishExecution,
                      isSecondary: true,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _skipExercise,
                      child: Text(
                        'Pular Exercício',
                        style: AppTypography.caption,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
