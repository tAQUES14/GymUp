import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class WorkoutConceptPage extends StatefulWidget {
  const WorkoutConceptPage({super.key});

  @override
  State<WorkoutConceptPage> createState() => _WorkoutConceptPageState();
}

class _WorkoutConceptPageState extends State<WorkoutConceptPage> {
  // Theme Colors
  static const Color primaryBlue = Color(0xFF007AFF); // Vibrant Blue
  static const Color backgroundGrey = Color(0xFFF5F7FA); // Off-white/Grey

  // State
  Timer? _timer;
  int _secondsElapsed = 580; // Start at 00:09:40 as requested example
  bool _isRunning = false;

  // Exercises Data
  final List<Map<String, dynamic>> _exercises = [
    {
      'title': 'Voador / Peck Deck',
      'subtitle': 'Peito',
      'imagePath':
          'c:/Users/taque/.gemini/antigravity/brain/0dd1ea11-9159-41e9-9c71-b829eb2c023d/peck_deck_icon_1768529487477.png',
      'sets': '4',
      'reps': '12',
      'load': '-',
      'rest': '60s',
      'isDone': false,
    },
    {
      'title': 'Supino Reto com Barra',
      'subtitle': 'Ombro, Peito',
      'imagePath':
          'c:/Users/taque/.gemini/antigravity/brain/0dd1ea11-9159-41e9-9c71-b829eb2c023d/bench_press_icon_1768529501754.png',
      'sets': '4',
      'reps': '12',
      'load': '-',
      'rest': '60s',
      'isDone': false,
    },
    {
      'title': 'Supino Inclinado com Halteres',
      'subtitle': 'Braço, Ombro, Peito',
      'imagePath':
          'c:/Users/taque/.gemini/antigravity/brain/0dd1ea11-9159-41e9-9c71-b829eb2c023d/incline_bench_press_icon_1768529515136.png',
      'sets': '4',
      'reps': '12',
      'load': '-',
      'rest': '60s',
      'isDone': false,
    },
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _isRunning = false;
      } else {
        _isRunning = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _secondsElapsed++;
          });
        });
      }
    });
  }

  String get _formattedTime {
    final duration = Duration(seconds: _secondsElapsed);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = twoDigits(duration.inHours);
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              _buildHeader(),

              // List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(
                    top: 20,
                    left: 16,
                    right: 16,
                    bottom: 120,
                  ),
                  itemCount: _exercises.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return _buildExerciseCard(
                      exercise: exercise,
                      onToggle: (val) {
                        setState(() {
                          exercise['isDone'] = val;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCurvedBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: primaryBlue,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back Button Left
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Title Center
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Treino A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedTime,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16, // Slightly larger for readability
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),

          // Menu Button Right
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.list, color: Colors.white, size: 28),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard({
    required Map<String, dynamic> exercise,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Radius ~16px
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Upper Part
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(exercise['imagePath'])),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise['subtitle'],
                      style: const TextStyle(
                        color: Color(0xFF9094A6), // Gray
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Toggle
              Switch(
                value: exercise['isDone'],
                onChanged: onToggle,
                activeTrackColor: primaryBlue.withValues(alpha: 0.3),
                trackColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? primaryBlue.withValues(alpha: 0.3)
                      : const Color(0xFFE0E0E0),
                ),
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? primaryBlue
                      : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid 2x2
          Row(
            children: [
              _buildInfoBlock('Séries', exercise['sets']),
              const SizedBox(width: 10),
              _buildInfoBlock('Repetições', exercise['reps']),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildInfoBlock('Carga/Velocidade', exercise['load']),
              const SizedBox(width: 10),
              _buildInfoBlock('Descanso', exercise['rest']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // Light Grey
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280), // Darker grey for text
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2937), // Dark text
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurvedBottomBar() {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Curve
          CustomPaint(
            size: const Size(double.infinity, 90),
            painter: BottomCurvePainter(
              Colors.white,
            ), // Bar itself is white or coloured?
            // "Navegação inferior... Barra inferior com..."
            // Usually bottom bars are white with shadow in light mode apps, or colored.
            // But the prompt says "Header com fundo azul" and "Botão principal... azul vibrante".
            // It doesn't explicitly say the BAR background color.
            // "Barra inferior com..."
            // Previous design used colored bar.
            // Standard clean UI typically uses white bar with shadow. Let's stick to White bar for "Clean" look,
            // and the button is the pop of color.
            // Wait, "Navegação fixa, sempre visível."
            // If I look at the previous image provided by user, the bar was blue?
            // No, the prompt says "Fundo claro".
            // Let's make the bar White to contrast with the Blue button, fitting "Modern, clean".
          ),

          // Buttons Row (Left & Right)
          Positioned(
            bottom: 20,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.list,
                    color: Color(0xFF9CA3AF),
                    size: 30,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow_outlined,
                    color: const Color(0xFF9CA3AF),
                    size: 30,
                  ),
                  onPressed: _toggleTimer, // Optional: pause/play timer
                ),
              ],
            ),
          ),

          // Center Floating Button
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: _toggleTimer,
              child: Container(
                width: 70,
                height: 70, // "Grande, circular"
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF007AFF),
                      Color(0xFF00C6FF),
                    ], // Vibrant Blue Gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isRunning
                        ? Icons.pause
                        : Icons
                              .emoji_events, // Trophy or Play/Pause? Prompt says "troféu ou play"
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 75,
            child: Text(
              _isRunning ? 'Pausar' : 'Iniciar',
              style: const TextStyle(
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomCurvePainter extends CustomPainter {
  final Color color;
  BottomCurvePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        convertRadiusToSigma(8),
      ); // Apply blur for shadow effect

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Start slightly down to allow for the curve nicely?
    // Actually standard bottom bar.
    path.moveTo(0, 20);

    // Left flat
    path.lineTo(w * 0.35, 20);

    // Center dip/curve for button
    // "Organic rise" - since button is floating above, maybe the bar dips OR the button sits on top.
    // Prompt: "Botão pensado para iniciar o treino... destacado".
    // Usually "Organic rise" means the bar curves UP to meet the button or DOWN to cradle it.
    // If button is floating, let's make a subtle cradle (dip) or just flat if "Clean".
    // The previous prompt said "rises".
    // Let's do a gentle curve DOWN to cradle the button (Concave) is standard for "FAB in notch"
    // OR Curve UP (Convex) effectively integrating it.
    // Given "Floating", I'll make a Convex curve (Rise) to hold the button?
    // Actually, "Rise in the center" usually means Convex.

    // Let's stick to a clean Arc compatible with the button.
    path.cubicTo(
      w * 0.42,
      20,
      w * 0.42,
      0, // Control 1
      w * 0.5,
      0, // Peak
    );
    path.cubicTo(
      w * 0.58,
      0,
      w * 0.58,
      20, // Control 2
      w * 0.65,
      20,
    );

    path.lineTo(w, 20);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // Draw shadow first
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
            .withValues(alpha: 0.1) // Shadow color
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          convertRadiusToSigma(8),
        ), // Blur for shadow
    );
    // Then draw the actual path
    canvas.drawPath(
      path,
      paint..maskFilter = null,
    ); // Remove maskFilter for the main path
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  // Helper function to convert radius to sigma for MaskFilter
  static double convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }
}
