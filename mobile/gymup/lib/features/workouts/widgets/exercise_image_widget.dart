import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/workout_model.dart';
import '../../../core/api/api_service.dart';
import 'gif_web_stub.dart'
    if (dart.library.html) 'gif_web_impl.dart';

/// Exibe a imagem do exercício (rede) com fallback colorido por grupo muscular.
/// Tamanho padrão: 64px × 64px, borderRadius 12px.
///
/// [showGif]: quando true, tenta carregar o GIF da URL da rede. Use apenas em
/// thumbnails pequenos — para exibição full-width use [ExerciseGifPanel].
class ExerciseImageWidget extends StatelessWidget {
  final ExerciseModel exercise;
  final double size;
  final bool showGif;

  const ExerciseImageWidget({
    super.key,
    required this.exercise,
    this.size = 64,
    this.showGif = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showGif && exercise.gifUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          exercise.gifUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Shimmer.fromColors(
              baseColor: const Color(0xFFE2E8F0),
              highlightColor: const Color(0xFFF8FAFC),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _MuscleGroupFallback(exercise.muscleGroup, size),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _MuscleGroupFallback(exercise.muscleGroup, size),
    );
  }
}

// ─── Full-width GIF panel for exercise execution ──────────────────────────────

/// Painel full-width com o GIF animado do exercício.
/// Usado na tela de execução — mostra o movimento claramente.
/// [height]: altura do painel (padrão 200px).
class ExerciseGifPanel extends StatelessWidget {
  final ExerciseModel exercise;
  final double height;
  final BorderRadius? borderRadius;
  /// Quando true, exibe somente o 1° frame (sem animação).
  /// Use na tela de execução do treino; false na tela de detalhe.
  final bool paused;

  const ExerciseGifPanel({
    super.key,
    required this.exercise,
    this.height = 200,
    this.borderRadius,
    this.paused = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ??
        const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        );

    final gifUri = exercise.gifUrl != null ? _safeUri(exercise.gifUrl!) : null;

    if (gifUri == null) {
      return ClipRRect(
        borderRadius: radius,
        child: _GifFallbackWide(exercise.muscleGroup, height),
      );
    }

    // No Flutter Web, usa HtmlElementView para evitar bloqueio CORS.
    // paused=true → canvas (1° frame estático); false → <img> animado.
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: radius,
        child: paused
            ? buildGifHtmlViewPaused(gifUri, height)
            : buildGifHtmlView(gifUri, height),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.network(
          gifUri,
          width: double.infinity,
          height: height,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Shimmer.fromColors(
              baseColor: const Color(0xFFE8EDF2),
              highlightColor: const Color(0xFFF8FAFC),
              child: Container(
                width: double.infinity,
                height: height,
                color: Colors.white,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('[GIF] ERROR loading $gifUri: $error');
            return _GifFallbackWide(exercise.muscleGroup, height);
          },
        ),
      ),
    );
  }
}

// ─── Fallback colorido por grupo muscular (quadrado) ─────────────────────────

class _MuscleGroupFallback extends StatelessWidget {
  final String muscleGroup;
  final double size;

  const _MuscleGroupFallback(this.muscleGroup, this.size);

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(muscleGroup);
    return Container(
      width: size,
      height: size,
      color: style.bg,
      child: Icon(style.icon, color: style.fg, size: size * 0.44),
    );
  }
}

// ─── Fallback wide (full-width) ───────────────────────────────────────────────

class _GifFallbackWide extends StatelessWidget {
  final String muscleGroup;
  final double height;

  const _GifFallbackWide(this.muscleGroup, this.height);

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(muscleGroup);
    return Container(
      width: double.infinity,
      height: height,
      color: style.bg,
      child: Icon(style.icon, color: style.fg.withValues(alpha: 0.5), size: 72),
    );
  }
}

// ─── URI safety helper ────────────────────────────────────────────────────────

/// Returns a valid URI string, or null when the input is empty/unparseable.
///
/// Rewrites the origin (scheme+host+port) to match [ApiService.baseUrl] so
/// that GIF loading uses the same host as API calls.  This is critical on
/// Android where `localhost` refers to the device itself — the backend stores
/// `APP_URL=http://localhost:8000` but the device needs `10.0.2.2` (emulator)
/// or the LAN IP.  Changing [ApiService.baseUrl] is the single place to update.
String? _safeUri(String raw) {
  if (raw.isEmpty) return null;
  try {
    final gifUri = Uri.parse(raw);
    final apiUri = Uri.parse(ApiService.baseUrl);
    // Replace origin with the API origin; keep path/query/fragment unchanged.
    final fixed = gifUri.replace(
      scheme: apiUri.scheme,
      host:   apiUri.host,
      port:   apiUri.port,
    );
    return fixed.toString();
  } catch (_) {
    return null;
  }
}

// ─── Shared style lookup ──────────────────────────────────────────────────────

_Style _styleFor(String muscle) {
  final m = muscle.toLowerCase();
  if (m.contains('peito') || m.contains('chest')) {
    return const _Style(Color(0xFFEFF6FF), Color(0xFF3B82F6), Icons.fitness_center_rounded);
  }
  if (m.contains('costa') || m.contains('back') || m.contains('dorsal')) {
    return const _Style(Color(0xFFF0FDF4), Color(0xFF16A34A), Icons.accessibility_new_rounded);
  }
  if (m.contains('perna') || m.contains('quadr') || m.contains('glút') ||
      m.contains('glut') || m.contains('isquio') || m.contains('panturr')) {
    return const _Style(Color(0xFFFFF7ED), Color(0xFFEA580C), Icons.directions_run_rounded);
  }
  if (m.contains('ombro') || m.contains('deltoid') || m.contains('trapézio') || m.contains('trapezio')) {
    return const _Style(Color(0xFFFAF5FF), Color(0xFF9333EA), Icons.sports_handball_rounded);
  }
  if (m.contains('bícep') || m.contains('bicep') || m.contains('trícep') ||
      m.contains('tricep') || m.contains('braço') || m.contains('antebraço')) {
    return const _Style(Color(0xFFFFF1F2), Color(0xFFE11D48), Icons.sports_gymnastics_rounded);
  }
  if (m.contains('core') || m.contains('abdôm') || m.contains('abdom') || m.contains('lombar')) {
    return const _Style(Color(0xFFFEFCE8), Color(0xFFCA8A04), Icons.self_improvement_rounded);
  }
  return const _Style(Color(0xFFF1F5F9), Color(0xFF2563EB), Icons.fitness_center_rounded);
}

class _Style {
  final Color bg;
  final Color fg;
  final IconData icon;
  const _Style(this.bg, this.fg, this.icon);
}
