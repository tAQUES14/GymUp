import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gymup_button.dart';

class RestTimerSheet extends StatefulWidget {
  final int initialDuration;
  final VoidCallback onTimerComplete;

  const RestTimerSheet({
    super.key,
    required this.initialDuration,
    required this.onTimerComplete,
  });

  @override
  State<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<RestTimerSheet> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialDuration;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _finish();
      }
    });
  }

  void _finish() {
    // Feedback sonoro/vibração pode ser adicionado aqui
    widget.onTimerComplete();
    Navigator.pop(context); // Close the sheet
  }

  void _addTime() {
    setState(() {
      _remainingSeconds += 15;
    });
  }

  void _skip() {
    _timer?.cancel();
    _finish();
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Descanso', style: AppTypography.h3),
          const SizedBox(height: 24),
          Text(
            _formattedTime,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontFamily: 'Inter', // Assuming Inter is available, else default
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GymUpButton(
                  label: '+15s',
                  onPressed: _addTime,
                  isSecondary: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GymUpButton(label: 'Pular', onPressed: _skip),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar', style: AppTypography.caption),
          ),
        ],
      ),
    );
  }
}
