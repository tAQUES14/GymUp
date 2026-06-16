import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_share_card.dart';

const _kBlue = Color(0xFF2F6FED);
const _kBlueDark = Color(0xFF1F4FC4);
const _kGreen = Color(0xFF5BA300);
const _homeButtonSvg = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2.5 9.58317L10 2.9165L17.5 9.58317M4.16667 8.33317V16.6665H15.8333V8.33317" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';
const _shareButtonSvg = '''
<svg width="13" height="15" viewBox="0 0 13 15" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M10.3722 9.81903C10.0027 9.8189 9.63742 9.89578 9.30024 10.0446C8.96305 10.1935 8.66159 10.4109 8.41562 10.6827L5.03489 8.54015C5.18079 8.21268 5.25613 7.8589 5.25613 7.50123C5.25613 7.14355 5.18079 6.78977 5.03489 6.4623L8.41562 4.3197C8.85668 4.80481 9.46693 5.10824 10.1247 5.1695C10.7825 5.23076 11.4396 5.04536 11.965 4.65025C12.4904 4.25514 12.8454 3.67933 12.9595 3.03759C13.0735 2.39585 12.9381 1.7353 12.5803 1.18759C12.2225 0.639886 11.6685 0.245241 11.0287 0.0823131C10.389 -0.080615 9.71048 0.000138509 9.12842 0.308479C8.54637 0.61682 8.10351 1.1301 7.88812 1.74603C7.67273 2.36196 7.70062 3.0353 7.96624 3.63186L4.58551 5.77446C4.23083 5.38336 3.76408 5.10767 3.24701 4.98388C2.72994 4.86009 2.18694 4.89403 1.68987 5.08121C1.19279 5.2684 0.765077 5.6 0.463323 6.03213C0.161568 6.46426 0 6.97656 0 7.50123C0 8.02589 0.161568 8.53819 0.463323 8.97032C0.765077 9.40246 1.19279 9.73406 1.68987 9.92124C2.18694 10.1084 2.72994 10.1424 3.24701 10.0186C3.76408 9.89478 4.23083 9.61909 4.58551 9.22799L7.96624 11.3706C7.73929 11.8817 7.68579 12.4515 7.81369 12.995C7.9416 13.5386 8.24408 14.0269 8.67612 14.3873C9.10815 14.7476 9.64665 14.9608 10.2115 14.9951C10.7763 15.0294 11.3372 14.8829 11.8108 14.5775C12.2844 14.2721 12.6453 13.824 12.8399 13.3001C13.0344 12.7761 13.0522 12.2042 12.8905 11.6694C12.7288 11.1347 12.3964 10.6657 11.9426 10.3323C11.4889 9.99891 10.938 9.81888 10.3722 9.81903ZM10.3722 0.820502C10.7277 0.820502 11.0752 0.924454 11.3708 1.11921C11.6664 1.31397 11.8968 1.59079 12.0328 1.91466C12.1689 2.23853 12.2045 2.59491 12.1351 2.93872C12.0658 3.28254 11.8946 3.59836 11.6432 3.84624C11.3918 4.09412 11.0715 4.26293 10.7228 4.33132C10.3741 4.39971 10.0127 4.36461 9.68427 4.23046C9.35582 4.09631 9.07508 3.86913 8.87757 3.57765C8.68005 3.28618 8.57463 2.94349 8.57463 2.59294C8.57463 2.12286 8.76401 1.67203 9.10111 1.33964C9.43821 1.00724 9.89542 0.820502 10.3722 0.820502ZM2.62898 9.27366C2.27346 9.27366 1.92593 9.16971 1.63033 8.97495C1.33473 8.7802 1.10434 8.50338 0.968287 8.17951C0.832236 7.85564 0.79664 7.49926 0.865997 7.15544C0.935355 6.81162 1.10655 6.4958 1.35794 6.24792C1.60933 6.00004 1.92962 5.83124 2.2783 5.76285C2.62699 5.69446 2.98841 5.72956 3.31686 5.86371C3.64532 5.99786 3.92605 6.22504 4.12357 6.51651C4.32108 6.80799 4.4265 7.15067 4.4265 7.50123C4.4265 7.97131 4.23712 8.42213 3.90002 8.75453C3.56292 9.08692 3.10571 9.27366 2.62898 9.27366ZM10.3722 14.1819C10.0166 14.1819 9.6691 14.078 9.3735 13.8832C9.0779 13.6885 8.84751 13.4117 8.71146 13.0878C8.57541 12.7639 8.53981 12.4075 8.60917 12.0637C8.67853 11.7199 8.84972 11.4041 9.10111 11.1562C9.3525 10.9083 9.67279 10.7395 10.0215 10.6711C10.3702 10.6027 10.7316 10.6378 11.06 10.772C11.3885 10.9061 11.6692 11.1333 11.8667 11.4248C12.0643 11.7163 12.1697 12.059 12.1697 12.4095C12.1697 12.6423 12.1232 12.8728 12.0328 13.0878C11.9425 13.3028 11.8101 13.4982 11.6432 13.6628C11.4763 13.8274 11.2781 13.958 11.06 14.047C10.8419 14.1361 10.6082 14.1819 10.3722 14.1819Z" fill="#0E1116"/>
</svg>
''';

class WorkoutCompletePage extends StatefulWidget {
  final String workoutNome;
  final int duracaoMinutos;
  final int setsConcluidos;
  final int setsTotais;
  final int streak;
  final int pontosGerados;
  final int totalPontos;
  final String? noPointsReason;
  final String? progressMessage;
  final List<String> prMessages;
  final int workoutVolume;
  final List<String> exerciseNames;
  final int remainingWorkoutsThisWeek;
  final int weeklyGoal;

  const WorkoutCompletePage({
    super.key,
    required this.workoutNome,
    required this.duracaoMinutos,
    required this.setsConcluidos,
    required this.setsTotais,
    required this.streak,
    required this.pontosGerados,
    required this.totalPontos,
    this.noPointsReason,
    this.progressMessage,
    this.prMessages = const [],
    this.workoutVolume = 0,
    this.exerciseNames = const [],
    this.remainingWorkoutsThisWeek = -1,
    this.weeklyGoal = 4,
  });

  @override
  State<WorkoutCompletePage> createState() => _WorkoutCompletePageState();
}

class _WorkoutCompletePageState extends State<WorkoutCompletePage> {
  final GlobalKey _repaintKey = GlobalKey();
  String _userName = '';
  String _gymName = '';
  bool _shareLoading = false;

  bool get _hasPoints => widget.noPointsReason == null && widget.pontosGerados > 0;
  bool get _completedAnyExercise => widget.setsConcluidos > 0;
  bool get _wasAbandoned => !_completedAnyExercise;
  bool get _isInvalid => widget.noPointsReason != null;
  bool get _isCompletedWorkout => _hasPoints;

  @override
  void initState() {
    super.initState();
    _loadCachedUserData();
  }

  Future<void> _loadCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _gymName = prefs.getString('gym_name') ?? '';
    });
  }

  Future<void> _shareCard() async {
    setState(() => _shareLoading = true);
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !mounted) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null || !mounted) return;
      final Uint8List imageBytes = byteData.buffer.asUint8List();
      final file = await File('${Directory.systemTemp.path}/gymup_workout.png')
          .writeAsBytes(imageBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _isCompletedWorkout
            ? 'Treino concluido no GymUp!'
            : 'Treino registrado no GymUp.',
      );
    } finally {
      if (mounted) setState(() => _shareLoading = false);
    }
  }

  void _showShareBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShareBottomSheet(
        repaintKey: _repaintKey,
        shareCard: WorkoutShareCard(
          userName: _userName,
          gymName: _gymName,
          pontosGerados: widget.pontosGerados,
          streak: widget.streak,
          duracaoMinutos: widget.duracaoMinutos,
          setsConcluidos: widget.setsConcluidos,
          completed: _isCompletedWorkout,
        ),
        onShare: _shareCard,
        isLoading: _shareLoading,
      ),
    );
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 128 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 18),
                  _heroCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _pointsCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _streakCard()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _weeklyGoalCard(),
                  const SizedBox(height: 18),
                  _sectionTitle('Resumo do treino'),
                  const SizedBox(height: 12),
                  _summaryCard(),
                  const SizedBox(height: 18),
                  _sectionTitle('Exercicios realizados'),
                  const SizedBox(height: 12),
                  _exerciseListCard(),
                  if (widget.progressMessage != null ||
                      widget.prMessages.isNotEmpty ||
                      widget.noPointsReason != null) ...[
                    const SizedBox(height: 18),
                    _messagesCard(),
                  ],
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _bottomDock(bottomInset),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final title = _wasAbandoned
        ? 'Treino encerrado'
        : _hasPoints
            ? 'Treino concluído'
            : _isInvalid
                ? 'Treino sem validação'
                : 'Treino registrado';
    return Row(
      children: [
        _circleButton(
          icon: Icons.close_rounded,
          onTap: _goHome,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: _pjs(
                  size: 17,
                  weight: FontWeight.w700,
                  color: const Color(0xFF0E1116),
                  height: 1.05,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.workoutNome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _pjs(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: const Color(0xFF5B6472),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _circleButton(
          icon: Icons.share_rounded,
          onTap: _showShareBottomSheet,
        ),
      ],
    );
  }

  Widget _heroCard() {
    final heroIcon = _isCompletedWorkout
        ? Icons.check_rounded
        : _wasAbandoned
            ? Icons.close_rounded
            : Icons.info_outline_rounded;
    final iconBg = _isCompletedWorkout
        ? const Color(0xFFEDFBD3)
        : _wasAbandoned
            ? const Color(0xFFFFE3E3)
            : const Color(0xFFFFEDDC);
    final iconColor = _isCompletedWorkout
        ? _kGreen
        : _wasAbandoned
            ? const Color(0xFFE5484D)
            : const Color(0xFFFF7A1A);
    final title = _isCompletedWorkout
        ? 'Treino concluído!'
        : _wasAbandoned
            ? 'Treino não concluído'
            : 'Treino não validado';
    final subtitle = _isCompletedWorkout
        ? 'Você completou o treino de hoje com\nsucesso.'
        : _wasAbandoned
            ? 'Você saiu antes de concluir exercícios.\nNada foi contado para a meta.'
            : 'Seu treino foi salvo, mas não gerou\npontos nem meta semanal.';
    final badge = _isCompletedWorkout
        ? 'TREINO VÁLIDO'
        : _wasAbandoned
            ? 'NÃO CONTABILIZADO'
            : 'SEM PONTOS';
    return Container(
      width: double.infinity,
      height: 238,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.08, -0.12),
          end: Alignment(0.92, 1.12),
          colors: [Color(0xFF1F4FC4), Color(0xFF2F6FED), Color(0xFF4A8CFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.28),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      heroIcon,
                      color: iconColor,
                      size: 27,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _pjs(
                    size: 22,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.05,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _pjs(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                _darkBadge(badge, icon: heroIcon, iconColor: iconColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointsCard() {
    return _metricBigCard(
      label: 'PONTOS GANHOS',
      icon: Icons.workspace_premium_rounded,
      iconBg: const Color(0xFFEDFBD3),
      valuePrefix: widget.pontosGerados > 0 ? '+' : '',
      value: '${widget.pontosGerados}',
      suffix: 'pts',
      footer: widget.totalPontos > 0 ? 'Saldo: ${widget.totalPontos} pts' : null,
      accent: _kGreen,
    );
  }

  Widget _streakCard() {
    return _metricBigCard(
      label: 'STREAK',
      icon: Icons.local_fire_department_rounded,
      iconBg: Colors.white,
      value: '${widget.streak}',
      suffix: 'dias',
      footer: widget.streak > 0 ? 'Sequencia mantida' : 'Comece sua sequencia',
      accent: const Color(0xFFB85A00),
      warm: true,
    );
  }

  Widget _metricBigCard({
    required String label,
    required IconData icon,
    required Color iconBg,
    String valuePrefix = '',
    required String value,
    required String suffix,
    required String? footer,
    required Color accent,
    bool warm = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warm ? null : Colors.white,
        gradient: warm
            ? const LinearGradient(
                begin: Alignment(0.30, -0.13),
                end: Alignment(0.70, 1.13),
                colors: [Color(0xFFFFF4E5), Color(0xFFFFEDDC)],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: warm ? Border.all(color: const Color(0x2DFF7A1A)) : null,
        boxShadow: _softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: _pjs(
                  size: 10.5,
                  weight: FontWeight.w800,
                  color: warm ? accent : const Color(0xFF5B6472),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (valuePrefix.isNotEmpty)
                Text(
                  valuePrefix,
                  style: _sg(
                    size: 13,
                    weight: FontWeight.w700,
                    color: accent,
                    letterSpacing: -0.2,
                  ),
                ),
              Text(
                value,
                style: _sg(
                  size: 42,
                  weight: FontWeight.w700,
                  color: const Color(0xFF0E1116),
                  height: 0.95,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                suffix,
                style: _sg(
                  size: 13,
                  weight: FontWeight.w700,
                  color: warm ? accent : const Color(0xFF5B6472),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 4),
            Text(
              footer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pjs(
                size: 11.5,
                weight: FontWeight.w600,
                color: warm ? const Color(0xFF7A4500) : const Color(0xFF5B6472),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weeklyGoalCard() {
    final total = widget.weeklyGoal <= 0 ? 4 : widget.weeklyGoal;
    final hasServerWeeklyData = widget.remainingWorkoutsThisWeek >= 0;
    final remaining = hasServerWeeklyData
        ? widget.remainingWorkoutsThisWeek.clamp(0, total)
        : (_completedAnyExercise ? (total - 1).clamp(0, total) : total);
    final done = (total - remaining).clamp(0, total);
    final progress = total == 0 ? 0.0 : done / total;
    final remainingLabel = remaining == 1 ? '1 treino' : '$remaining treinos';
    final statusText = !_isCompletedWorkout
        ? 'Esse treino não alterou sua meta. Você segue com $done de $total treinos válidos na semana.'
        : remaining == 0
            ? 'Meta da semana completa. Boa!'
            : 'Falta $remainingLabel para completar sua meta da semana.';
    final progressColor = _isCompletedWorkout ? _kGreen : const Color(0xFF9AA3B0);
    final progressBg =
        _isCompletedWorkout ? const Color(0xFFEDFBD3) : const Color(0xFFEFF3F8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _whiteDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 185),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'META SEMANAL',
                      style: _pjs(
                        size: 10.5,
                        weight: FontWeight.w800,
                        color: const Color(0xFF9AA3B0),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$done',
                            style: _sg(
                              size: 16,
                              weight: FontWeight.w700,
                              color: const Color(0xFF0E1116),
                              letterSpacing: -0.3,
                            ),
                          ),
                          TextSpan(
                            text: ' de $total treinos concluídos',
                            style: _pjs(
                              size: 16,
                              weight: FontWeight.w700,
                              color: const Color(0xFF0E1116),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: progressBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: _sg(
                    size: 12,
                    weight: FontWeight.w700,
                    color: progressColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 10,
            padding: const EdgeInsets.only(top: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0x110E1116),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: _isCompletedWorkout
                              ? const [Color(0xFF5BA300), Color(0xFFA6E000)]
                              : const [Color(0xFF9AA3B0), Color(0xFFCBD3DD)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: _isCompletedWorkout
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFA6E000).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            statusText,
            style: _pjs(
              size: 12,
              weight: !_isCompletedWorkout ? FontWeight.w700 : FontWeight.w600,
              color: const Color(0xFF5B6472),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final totalExercises = widget.exerciseNames.isNotEmpty
        ? widget.exerciseNames.length
        : widget.setsTotais;
    final exercisesDone = widget.setsConcluidos.clamp(0, totalExercises);
    final totalSets = widget.exerciseNames.isNotEmpty
        ? widget.setsConcluidos * 3
        : widget.setsConcluidos * 3;
    return Container(
      width: double.infinity,
      height: 182,
      padding: const EdgeInsets.all(4),
      decoration: _whiteDecoration(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _summaryTile(
                    icon: Icons.timer_outlined,
                    iconBg: const Color(0xFFE7EEFE),
                    iconColor: _kBlue,
                    label: 'DURA\u00C7\u00C3O',
                    value: '${widget.duracaoMinutos}',
                    suffix: 'min',
                    border: const Border(
                      right: BorderSide(color: Color(0x0F0E1116)),
                      bottom: BorderSide(color: Color(0x0F0E1116)),
                    ),
                  ),
                ),
                Expanded(
                  child: _summaryTile(
                    icon: Icons.format_list_bulleted_rounded,
                    iconBg: const Color(0xFFEDFBD3),
                    iconColor: _kGreen,
                    label: 'EXERC\u00CDCIOS',
                    value: '$exercisesDone/$totalExercises',
                    border: const Border(
                      bottom: BorderSide(color: Color(0x0F0E1116)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _summaryTile(
                    icon: Icons.bar_chart_rounded,
                    iconBg: const Color(0xFFFFEDDC),
                    iconColor: const Color(0xFFFF7A1A),
                    label: 'S\u00C9RIES',
                    value: '$totalSets',
                    border: const Border(
                      right: BorderSide(color: Color(0x0F0E1116)),
                    ),
                  ),
                ),
                Expanded(
                  child: _summaryTile(
                    icon: Icons.show_chart_rounded,
                    iconBg: const Color(0xFFECECFA),
                    iconColor: const Color(0xFF4A5FEA),
                    label: 'VOLUME TOTAL',
                    value: '${widget.workoutVolume}',
                    suffix: 'kg',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    String? suffix,
    Border? border,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(border: border),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow(label),
                const SizedBox(height: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: _sg(
                        size: 18,
                        weight: FontWeight.w700,
                        color: const Color(0xFF0E1116),
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 3),
                      Text(
                        suffix,
                        style: _sg(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF9AA3B0),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _exerciseListCard() {
    final names = widget.exerciseNames.isNotEmpty
        ? widget.exerciseNames
        : List<String>.generate(
            widget.setsTotais,
            (i) => i == 0 ? widget.workoutNome : 'Exercicio ${i + 1}',
          );
    if (_wasAbandoned) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _whiteDecoration(radius: 20),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE3E3),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFE5484D),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nenhum exercício foi concluído neste treino.',
                style: _pjs(
                  size: 13,
                  weight: FontWeight.w700,
                  color: const Color(0xFF5B6472),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final visibleNames = names.take(widget.setsConcluidos.clamp(0, names.length)).toList();
    return Container(
      width: double.infinity,
      decoration: _whiteDecoration(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < visibleNames.length; i++)
            _exerciseRow(
              visibleNames[i],
              seriesLabel: '3 series',
              isLast: i == visibleNames.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _exerciseRow(String name, {required String seriesLabel, required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0x0C0E1116))),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEDFBD3),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.check_rounded, color: _kGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _pjs(
                size: 14,
                weight: FontWeight.w700,
                color: const Color(0xFF0E1116),
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            seriesLabel,
            style: _sg(
              size: 11.5,
              weight: FontWeight.w700,
              color: const Color(0xFF5B6472),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messagesCard() {
    final messages = <String>[
      ...widget.prMessages,
      if (widget.progressMessage != null) widget.progressMessage!,
      if (widget.noPointsReason != null) widget.noPointsReason!,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _whiteDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final msg in messages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: _kBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg,
                      style: _pjs(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: const Color(0xFF5B6472),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomDock(double bottomInset) {
    return _bottomDockClean(bottomInset);
  }

  Widget _bottomDockClean(double bottomInset) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 21, 20, 26 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F5F9),
        border: Border(top: BorderSide(color: Color(0x0F0E1116))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _goHome,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(0.18, -0.69),
                    end: Alignment(0.82, 1.69),
                    colors: [_kBlueDark, _kBlue, Color(0xFF4A8CFF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.36),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.string(
                      _homeButtonSvg,
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Voltar para o início',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(
                          size: 13.6,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showShareBottomSheet,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x190E1116)),
                boxShadow: _softShadow(),
              ),
              child: Center(
                child: SvgPicture.string(
                  _shareButtonSvg,
                  width: 17,
                  height: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomDockLegacy(double bottomInset) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 21, 20, 26 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F5F9),
        border: Border(top: BorderSide(color: Color(0x0F0E1116))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _goHome,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(0.18, -0.69),
                    end: Alignment(0.82, 1.69),
                    colors: [_kBlueDark, _kBlue, Color(0xFF4A8CFF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.36),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.string(
                      _homeButtonSvg,
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Voltar para o início',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(
                          size: 14,
                          weight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _showShareBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x190E1116)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.string(
                      _shareButtonSvg,
                      width: 16,
                      height: 18,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Compartilhar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _pjs(
                          size: 14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF0E1116),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: _softShadow(),
        ),
        child: Icon(icon, color: const Color(0xFF0E1116), size: 19),
      ),
    );
  }

  Widget _darkBadge(
    String label, {
    IconData icon = Icons.check_rounded,
    Color iconColor = _kGreen,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 11),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: _pjs(
              size: 11,
              weight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: _pjs(
        size: 16,
        weight: FontWeight.w700,
        color: const Color(0xFF0E1116),
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _eyebrow(String text) {
    return Text(
      text,
      style: _pjs(
        size: 9.5,
        weight: FontWeight.w800,
        color: const Color(0xFF9AA3B0),
        letterSpacing: 0.4,
      ),
    );
  }

  BoxDecoration _whiteDecoration({required double radius}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: _softShadow(),
    );
  }

  List<BoxShadow> _softShadow() {
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }

  TextStyle _pjs({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  TextStyle _sg({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Space Grotesk',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

class _ShareBottomSheet extends StatefulWidget {
  final GlobalKey repaintKey;
  final WorkoutShareCard shareCard;
  final VoidCallback onShare;
  final bool isLoading;

  const _ShareBottomSheet({
    required this.repaintKey,
    required this.shareCard,
    required this.onShare,
    required this.isLoading,
  });

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  bool _sharing = false;

  Future<void> _handleShare() async {
    setState(() => _sharing = true);
    widget.onShare();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF3F5F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x1F0E1116),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EEFE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.ios_share_rounded,
                    color: _kBlue,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compartilhar treino',
                        style: TextStyle(
                          color: Color(0xFF0E1116),
                          fontSize: 17,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gere uma imagem pronta para postar.',
                        style: TextStyle(
                          color: Color(0xFF5B6472),
                          fontSize: 12,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F0F172A),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF5B6472),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: RepaintBoundary(
                key: widget.repaintKey,
                child: widget.shareCard,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _sharing || widget.isLoading ? null : _handleShare,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_kBlueDark, _kBlue, Color(0xFF4A8CFF)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_sharing || widget.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _sharing || widget.isLoading ? 'Gerando imagem...' : 'Compartilhar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A imagem usa os dados deste treino.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF5B6472).withValues(alpha: 0.85),
                fontSize: 11.5,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
