import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_service.dart';
import '../../core/widgets/gymup_loading.dart';

const _kBg = Color(0xFFEDF0F6);
const _kInk = Color(0xFF17233F);
const _kMuted = Color(0xFF5C6678);
const _kSoft = Color(0xFF97A1B4);
const _kBlue = Color(0xFF2E63F2);
const _kBlueDark = Color(0xFF2450D6);
const _kBlue2 = Color(0xFF41B6C9);
const _kBlueSoft = Color(0xFFEAF1FF);
const _kLime = Color(0xFFC6EE54);
const _kLimeInk = Color(0xFF3E5A07);
const _kGreen = Color(0xFF0E9F6E);
const _kRed = Color(0xFFD14343);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _api = ApiService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _avatarUploading = false;
  String? _email;
  String? _gymName;
  String? _error;
  String _avatarUrl = '';

  bool _notifications = true;
  bool _workoutReminder = true;
  bool _rankingVisible = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await Future.wait<http.Response>([
        _api.get('/profile'),
        _api.get('/body-weight?limit=1').catchError((_) => http.Response('[]', 200)),
        _api.get('/goals/current').catchError((_) => http.Response('{}', 404)),
      ]);
      final response = results[0];
      final weightResponse = results[1];
      final goalResponse = results[2];
      if (response.statusCode == 401 && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final gym = data['gym'] as Map<String, dynamic>?;
      final avatarUrl = data['avatar_url'] as String? ?? '';
      final latestWeight = _latestBodyWeight(weightResponse);
      final goalData = _goalFallback(goalResponse);
      final profileWeight = _toDouble(data['weight']);
      final profileHeight = _toDouble(data['height']);
      _nameCtrl.text = data['name'] as String? ?? '';
      _phoneCtrl.text = data['phone'] as String? ?? '';
      _weightCtrl.text = _formatNumber(profileWeight ?? latestWeight ?? goalData.weight, decimals: 1);
      _heightCtrl.text = _formatNumber(profileHeight ?? goalData.height, decimals: 0);
      if (avatarUrl.isNotEmpty) {
        await prefs.setString('user_avatar_url', avatarUrl);
      } else {
        await prefs.remove('user_avatar_url');
      }

      if (!mounted) return;
      setState(() {
        _email = data['email'] as String?;
        _gymName = gym?['name'] as String?;
        _avatarUrl = avatarUrl;
        _notifications = prefs.getBool('settings_notifications') ?? true;
        _workoutReminder = prefs.getBool('settings_workout_reminder') ?? true;
        _rankingVisible = prefs.getBool('settings_ranking_visible') ?? true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final weight = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
      final height = double.tryParse(_heightCtrl.text.trim().replaceAll(',', '.'));
      final response = await _api.put('/profile', {
        'name': _nameCtrl.text.trim(),
        'phone': _emptyToNull(_phoneCtrl),
        'weight': weight,
        'height': height,
      });

      if (response.statusCode != 200) {
        throw Exception(_parseApiError(response.body, response.statusCode));
      }

      if (weight != null) {
        await _api.post('/body-weight', {'weight': weight}).catchError((_) => http.Response('{}', 500));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('settings_notifications', _notifications);
      await prefs.setBool('settings_workout_reminder', _workoutReminder);
      await prefs.setBool('settings_ranking_visible', _rankingVisible);
      await prefs.setString('user_name', _nameCtrl.text.trim());

      if (!mounted) return;
      _snack('Configurações salvas.', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    if (_avatarUploading) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
    } on MissingPluginException {
      _snack(
        kIsWeb
            ? 'Seletor de fotos atualizado. Pare o servidor Flutter e rode novamente para registrar o plugin.'
            : 'Seletor de fotos atualizado. Recompile o app para registrar o plugin.',
      );
      return;
    }
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      final croppedBytes = await _showAvatarCropModal(bytes);
      if (croppedBytes == null) return;

      setState(() => _avatarUploading = true);

      final streamed = await _api.multipartPost(
        '/profile/avatar',
        files: [
          http.MultipartFile.fromBytes(
            'avatar',
            croppedBytes,
            filename: 'avatar.png',
          ),
        ],
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw Exception(_parseApiError(response.body, response.statusCode));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final avatarUrl = data['avatar_url'] as String? ?? _avatarUrl;
      if (avatarUrl.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar_url', avatarUrl);
      }
      if (!mounted) return;
      setState(() => _avatarUrl = avatarUrl);
      _snack('Foto atualizada.', success: true);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _avatarUploading = false);
    }
  }

  Future<Uint8List?> _showAvatarCropModal(Uint8List bytes) async {
    final cropKey = GlobalKey();
    final result = await showGeneralDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Recortar foto',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, _, _) {
        var saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> capture() async {
              if (saving) return;
              setSheetState(() => saving = true);
              await Future<void>.delayed(const Duration(milliseconds: 60));
              try {
                final boundary =
                    cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                final image = await boundary?.toImage(pixelRatio: 1.25);
                final data = await image?.toByteData(format: ui.ImageByteFormat.png);
                if (ctx.mounted) {
                  Navigator.pop(ctx, data?.buffer.asUint8List());
                }
              } catch (_) {
                if (ctx.mounted) Navigator.pop(ctx);
              }
            }

            final width = MediaQuery.sizeOf(ctx).width;
            final cropSize = (width - 48).clamp(280.0, 360.0);

            return Material(
              color: const Color(0xFF0E1116),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CircleButton(
                          icon: Icons.close_rounded,
                          onTap: saving ? () {} : () => Navigator.pop(ctx),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Recortar foto',
                            textAlign: TextAlign.center,
                            style: _pjs(
                              size: 18,
                              weight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 56),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Arraste e aproxime a imagem para enquadrar seu avatar.',
                      textAlign: TextAlign.center,
                      style: _pjs(
                        size: 13,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.45,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: RepaintBoundary(
                              key: cropKey,
                              child: ColoredBox(
                                color: Colors.black,
                                child: SizedBox(
                                  width: cropSize,
                                  height: cropSize,
                                  child: InteractiveViewer(
                                    minScale: 1,
                                    maxScale: 6,
                                    boundaryMargin: const EdgeInsets.all(220),
                                    child: Image.memory(
                                      bytes,
                                      width: cropSize,
                                      height: cropSize,
                                      fit: BoxFit.contain,
                                      cacheWidth: 1200,
                                      cacheHeight: 1200,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: Container(
                              width: cropSize,
                              height: cropSize,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saving ? null : capture,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            child: Text(saving ? 'Salvando...' : 'Cortar e salvar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }

  String? _emptyToNull(TextEditingController ctrl) {
    final text = ctrl.text.trim();
    return text.isEmpty ? null : text;
  }

  double? _latestBodyWeight(http.Response response) {
    if (response.statusCode != 200) return null;
    try {
      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;
      final first = list.first as Map<String, dynamic>;
      return _toDouble(first['weight']);
    } catch (_) {
      return null;
    }
  }

  ({double? weight, double? height}) _goalFallback(http.Response response) {
    if (response.statusCode != 200) return (weight: null, height: null);
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        weight: _toDouble(data['start_weight']),
        height: _toDouble(data['height']),
      );
    } catch (_) {
      return (weight: null, height: null);
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _formatNumber(double? value, {required int decimals}) {
    if (value == null) return '';
    return value.toStringAsFixed(decimals);
  }

  String _parseApiError(String body, int statusCode) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final errors = json['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      return json['message'] as String? ?? 'Erro ao salvar configuracoes.';
    } catch (_) {
      return 'Erro ao salvar configuracoes. HTTP $statusCode';
    }
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _kGreen : _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const GymUpLoading()
            : Stack(
                children: [
                  RefreshIndicator(
                    color: _kBlue,
                    onRefresh: _load,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16, 18, 16, 124 + bottomInset),
                        children: [
                          _Header(onBack: () => Navigator.pop(context)),
                          const SizedBox(height: 14),
                          if (_error != null)
                            _StateCard(error: _error!, onRetry: _load)
                          else ...[
                            _AvatarHero(
                              name: _nameCtrl.text,
                              email: _email ?? '',
                              gymName: _gymName ?? '',
                              avatarUrl: _avatarUrl.trim(),
                              uploading: _avatarUploading,
                              onPickAvatar: _pickAvatar,
                            ),
                            const SizedBox(height: 26),
                            const _SectionTitle(title: 'Dados pessoais'),
                            const SizedBox(height: 10),
                            _SettingsCard(
                              children: [
                                _SettingsField(
                                  controller: _nameCtrl,
                                  label: 'Nome',
                                  icon: Icons.person_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => setState(() {}),
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) return 'Informe seu nome.';
                                    return null;
                                  },
                                ),
                                const _CardDivider(),
                                _SettingsField(
                                  controller: _phoneCtrl,
                                  label: 'Telefone',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9()+\-\s]')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            const _SectionTitle(title: 'Dados corporais'),
                            const SizedBox(height: 10),
                            _SettingsCard(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _MetricField(
                                        controller: _weightCtrl,
                                        label: 'Peso',
                                        suffix: 'kg',
                                        icon: Icons.monitor_weight_outlined,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([,.]\d{0,1})?')),
                                        ],
                                      ),
                                    ),
                                    const _VerticalDivider(),
                                    Expanded(
                                      child: _MetricField(
                                        controller: _heightCtrl,
                                        label: 'Altura',
                                        suffix: 'cm',
                                        icon: Icons.height_rounded,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            const _SectionTitle(title: 'Preferências'),
                            const SizedBox(height: 10),
                            _SettingsCard(
                              children: [
                                _SwitchRow(
                                  title: 'Notificações',
                                  subtitle: 'Avisos de desafios, recompensas e novidades.',
                                  icon: Icons.notifications_none_rounded,
                                  value: _notifications,
                                  onChanged: (value) => setState(() => _notifications = value),
                                ),
                                _SwitchRow(
                                  title: 'Lembrete de treino',
                                  subtitle: 'Ajuda a manter sua consistência semanal.',
                                  icon: Icons.alarm_rounded,
                                  value: _workoutReminder,
                                  onChanged: (value) => setState(() => _workoutReminder = value),
                                ),
                                _SwitchRow(
                                  title: 'Aparecer no ranking',
                                  subtitle: 'Controle local para sua preferência de privacidade.',
                                  icon: Icons.emoji_events_outlined,
                                  value: _rankingVisible,
                                  onChanged: (value) => setState(() => _rankingVisible = value),
                                  showDivider: false,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BottomBar(
                      bottomInset: bottomInset,
                      loading: _saving,
                      onSave: _save,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        Expanded(
          child: Text(
            'Configurações',
            textAlign: TextAlign.center,
            style: _pjs(size: 18, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.3),
          ),
        ),
        const SizedBox(width: 42),
      ],
    );
  }
}

class _AvatarHero extends StatelessWidget {
  final String name;
  final String email;
  final String gymName;
  final String avatarUrl;
  final bool uploading;
  final VoidCallback onPickAvatar;

  const _AvatarHero({
    required this.name,
    required this.email,
    required this.gymName,
    required this.avatarUrl,
    required this.uploading,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final hasAvatar = avatarUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlueDark, _kBlue, _kBlue2],
          begin: Alignment(-0.9, -1),
          end: Alignment(1.1, 1.2),
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: uploading ? null : onPickAvatar,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: hasAvatar ? Colors.transparent : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasAvatar
                              ? Image.network(
                                  avatarUrl,
                                  key: ValueKey(avatarUrl),
                                  fit: BoxFit.cover,
                                  cacheWidth: 180,
                                  cacheHeight: 180,
                                  filterQuality: FilterQuality.medium,
                                  errorBuilder: (_, _, _) => _Initials(initials: initials, color: _kBlue),
                                )
                              : _Initials(initials: initials, color: _kBlue),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _kLime,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.95), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: uploading
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: _kLimeInk),
                                  )
                                : const Icon(Icons.photo_camera_outlined, size: 13, color: _kLimeInk),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.trim().isEmpty ? 'Seu perfil' : name.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _pjs(size: 21, weight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -0.4),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _pjs(size: 13.5, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.82)),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (gymName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.fromLTRB(10, 7, 13, 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.fitness_center_rounded, size: 15, color: Colors.white),
                                    const SizedBox(width: 7),
                                    Text(
                                      gymName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _pjs(size: 13, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.1),
                                    ),
                                  ],
                                ),
                              ),
                            GestureDetector(
                              onTap: uploading ? null : onPickAvatar,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      uploading ? Icons.hourglass_top_rounded : Icons.image_outlined,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      uploading ? 'Enviando foto' : 'Alterar foto',
                                      style: _pjs(size: 13, weight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  final Color color;

  const _Initials({required this.initials, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: _pjs(size: 24, weight: FontWeight.w800, color: color, letterSpacing: -0.4),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: _whiteDecoration(22),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: _kInk.withValues(alpha: 0.06)),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 86,
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: _kInk.withValues(alpha: 0.06),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const _SettingsField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SmallIconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: _pjs(size: 11.5, weight: FontWeight.w700, color: _kSoft, letterSpacing: 0.5),
                ),
                const SizedBox(height: 3),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  inputFormatters: inputFormatters,
                  onChanged: onChanged,
                  validator: validator,
                  style: _pjs(size: 16.5, weight: FontWeight.w600, color: _kInk, letterSpacing: -0.1),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  const _MetricField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallIconBox(icon: icon),
              const SizedBox(width: 9),
              Text(
                label.toUpperCase(),
                style: _pjs(size: 11.5, weight: FontWeight.w700, color: _kSoft, letterSpacing: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  inputFormatters: inputFormatters,
                  style: _pjs(size: 27, weight: FontWeight.w700, color: _kInk, letterSpacing: -0.6),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(suffix, style: _pjs(size: 14, weight: FontWeight.w600, color: _kSoft)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallIconBox extends StatelessWidget {
  final IconData icon;

  const _SmallIconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: _kBlueSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: _kBlue, size: 16),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: value ? _kBlueSoft : _kInk.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: value ? _kBlue : _kMuted, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _pjs(size: 14.5, weight: FontWeight.w800, color: _kInk, letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kSoft, height: 1.35)),
                  ],
                ),
              ),
              Switch(
                value: value,
                activeThumbColor: Colors.white,
                activeTrackColor: _kBlue,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE2E6EE),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(height: 1, color: _kInk.withValues(alpha: 0.06)),
          ),
        ],
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final double bottomInset;
  final bool loading;
  final VoidCallback onSave;

  const _BottomBar({
    required this.bottomInset,
    required this.loading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 30 + bottomInset),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _kBg.withValues(alpha: 0),
            _kBg.withValues(alpha: 0.92),
            _kBg,
          ],
          stops: const [0, 0.28, 0.60],
        ),
      ),
      child: GestureDetector(
        onTap: loading ? null : onSave,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: loading ? 0.72 : 1,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kBlueDark, _kBlue, _kBlue2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.34),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : Text(
                      'Salvar configurações',
                      style: _pjs(size: 16.5, weight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 1),
      child: Text(
        title.toUpperCase(),
        style: _pjs(size: 13, weight: FontWeight.w700, color: const Color(0xFF6B7588), letterSpacing: 0.8),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _StateCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _whiteDecoration(22),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: _kRed.withValues(alpha: 0.10), shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, color: _kRed, size: 28),
          ),
          const SizedBox(height: 14),
          Text('Erro ao carregar', style: _pjs(size: 17, weight: FontWeight.w800, color: _kInk)),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: _pjs(size: 12.5, weight: FontWeight.w500, color: _kMuted, height: 1.4)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(14)),
              child: Text('Tentar novamente', style: _pjs(size: 13, weight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kInk.withValues(alpha: 0.05)),
          boxShadow: _shadow(tight: true),
        ),
        child: Icon(icon, color: _kInk, size: 20),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
}

BoxDecoration _whiteDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _kInk.withValues(alpha: 0.04)),
    boxShadow: _shadow(),
  );
}

List<BoxShadow> _shadow({bool tight = false}) {
  return [
    BoxShadow(
      color: const Color(0xFF172850).withValues(alpha: tight ? 0.07 : 0.06),
      blurRadius: tight ? 12 : 24,
      offset: Offset(0, tight ? 4 : 8),
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
