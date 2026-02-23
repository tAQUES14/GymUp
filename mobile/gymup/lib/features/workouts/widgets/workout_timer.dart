import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/gymup_button.dart';

class WorkoutTimer extends StatefulWidget {
  final int defaultTime;
  final VoidCallback? onTimerComplete;
  final bool isRest;
  final bool autoStart;

  const WorkoutTimer({
    super.key,
    this.defaultTime = 60,
    this.onTimerComplete,
    this.isRest = false,
    this.autoStart = false,
  });

  @override
  State<WorkoutTimer> createState() => _WorkoutTimerState();
}

class _WorkoutTimerState extends State<WorkoutTimer> {
  late int _remainingTime;
  Timer? _timer;
  bool _isRunning = false;
  int _initialTime = 60;

  @override
  void initState() {
    super.initState();
    _initialTime = widget.defaultTime;
    _remainingTime = _initialTime;
    
    if (widget.autoStart) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _pauseTimer();
        HapticFeedback.vibrate();
        if (widget.onTimerComplete != null) {
          widget.onTimerComplete!();
        }
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingTime = _initialTime;
    });
  }

  void _addTime(int seconds) {
    setState(() {
      int newTime = _remainingTime + seconds;
      if (newTime < 5) newTime = 5; // Minimum limit 5s
      
      _remainingTime = newTime;
      // Adjust initial time to keep progress bar meaningful if extending
      if (seconds > 0) {
         _initialTime += seconds;
      } else {
         if (_initialTime > _remainingTime) {
            _initialTime += seconds; 
         }
         if (_initialTime < 5) _initialTime = 5;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _initialTime > 0 ? _remainingTime / _initialTime : 0.0;
    final color = widget.isRest ? Colors.blue : AppColors.primary;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 12,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _remainingTime < 10 ? AppColors.error : color,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_remainingTime}s',
                  style: AppTypography.h1.copyWith(fontSize: 48, color: color),
                ),
                Text(
                  _isRunning ? (widget.isRest ? 'DESCANSANDO' : 'EXECUTANDO') : 'PAUSADO',
                  style: AppTypography.caption.copyWith(
                    color: _isRunning ? color : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _addTime(-10),
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.grey,
              iconSize: 32,
            ),
            const SizedBox(width: 16),
            if (_isRunning)
              GymUpButton(
                label: 'PAUSAR',
                onPressed: _pauseTimer,
                width: 120,
                color: Colors.orange,
              )
            else
              GymUpButton(
                label: _remainingTime == _initialTime ? 'INICIAR' : 'CONTINUAR',
                onPressed: _startTimer,
                width: 120,
                color: color,
              ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => _addTime(10),
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.grey,
              iconSize: 32,
            ),
          ],
        ),
        if (!_isRunning && _remainingTime != _initialTime)
          TextButton(
            onPressed: _resetTimer,
            child: Text(
              'Resetar Timer',
              style: AppTypography.button.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
