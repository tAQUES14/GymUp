import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymup/core/constants/firestore_collections.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ────────────────────────────
  // ALUNO
  // ────────────────────────────

  Stream<DocumentSnapshot> getAlunoStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection(FirestoreCollections.alunos)
        .doc(user.uid)
        .snapshots();
  }

  Future<DocumentSnapshot> getAluno() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');
    return _db.collection(FirestoreCollections.alunos).doc(user.uid).get();
  }

  Future<void> updateAluno(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');
    await _db
        .collection(FirestoreCollections.alunos)
        .doc(user.uid)
        .update(data);
  }

  // ────────────────────────────
  // RANKING
  // ────────────────────────────

  Stream<QuerySnapshot> getRankingStream() {
    return _db
        .collection(FirestoreCollections.alunos)
        .orderBy('pontos', descending: true)
        .limit(50)
        .snapshots();
  }

  // ────────────────────────────
  // QR VALIDATION
  // ────────────────────────────

  Future<void> validarPresencaHoje(String qrCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    final jaValidou = await verificarValidacaoHoje();
    if (jaValidou) {
      throw Exception('Você já validou o QR hoje.');
    }

    await _db.collection(FirestoreCollections.alunos).doc(user.uid).update({
      'dataValidacao': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> verificarValidacaoHoje() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db
        .collection(FirestoreCollections.alunos)
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return false;

    final dataValidacao = data['dataValidacao'] as Timestamp?;
    if (dataValidacao == null) return false;

    final validadoEm = dataValidacao.toDate().toLocal();
    final hoje = DateTime.now();

    return validadoEm.year == hoje.year &&
        validadoEm.month == hoje.month &&
        validadoEm.day == hoje.day;
  }

  bool qrValidadoHoje(Map<String, dynamic> data) {
    final timestamp = data['dataValidacao'];
    if (timestamp == null) return false;

    final validacao = (timestamp as Timestamp).toDate().toLocal();
    final now = DateTime.now();

    return validacao.year == now.year &&
        validacao.month == now.month &&
        validacao.day == now.day;
  }

  bool jaTreinouHoje(Map<String, dynamic> data) {
    final ultimoCheckin = data['ultimoCheckin'] as Timestamp?;
    if (ultimoCheckin == null) return false;

    final checkin = ultimoCheckin.toDate().toLocal();
    final now = DateTime.now();

    return checkin.year == now.year &&
        checkin.month == now.month &&
        checkin.day == now.day;
  }

  // ────────────────────────────
  // PRESENÇA
  // ────────────────────────────

  Future<void> registrarPresenca([String qrCode = '']) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final query = await _db
        .collection(FirestoreCollections.presencas)
        .where('alunoUid', isEqualTo: user.uid)
        .where('data', isEqualTo: todayStr)
        .get();

    if (query.docs.isNotEmpty) {
      throw Exception('Você já fez check-in hoje!');
    }

    final alunoDoc = await _db
        .collection(FirestoreCollections.alunos)
        .doc(user.uid)
        .get();

    final alunoData = alunoDoc.data() ?? {};
    final streakAtual = (alunoData['streak'] as num?)?.toInt() ?? 0;
    final ultimoCheckinTs = alunoData['ultimoCheckin'] as Timestamp?;

    final hoje = DateTime(now.year, now.month, now.day);
    int novaStreak;

    if (ultimoCheckinTs == null) {
      novaStreak = 1;
    } else {
      final ultimaData = ultimoCheckinTs.toDate();
      final diaUltimo = DateTime(
        ultimaData.year,
        ultimaData.month,
        ultimaData.day,
      );
      final diff = hoje.difference(diaUltimo).inDays;
      novaStreak = (diff == 1) ? streakAtual + 1 : 1;
    }

    final batch = _db.batch();

    final presencaRef = _db.collection(FirestoreCollections.presencas).doc();

    batch.set(presencaRef, {
      'id': presencaRef.id,
      'alunoUid': user.uid,
      'data': todayStr,
      'horario': FieldValue.serverTimestamp(),
      'pontosGanhos': 10,
      'qrCode': qrCode,
    });

    batch.update(_db.collection(FirestoreCollections.alunos).doc(user.uid), {
      'pontos': FieldValue.increment(10),
      'streak': novaStreak,
      'ultimoCheckin': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot> getPresencasStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection(FirestoreCollections.presencas)
        .where('alunoUid', isEqualTo: user.uid)
        .orderBy('horario', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getPresencasDesdeFuture(DateTime inicio) {
    return _db
        .collection(FirestoreCollections.presencas)
        .where('horario', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .get();
  }

  // ────────────────────────────
  // LOJA
  // ────────────────────────────

  Stream<QuerySnapshot> getRecompensasStream() {
    return _db.collection(FirestoreCollections.recompensas).snapshots();
  }

  Stream<QuerySnapshot> getResgatesStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection(FirestoreCollections.resgates)
        .where('alunoUid', isEqualTo: user.uid)
        .orderBy('data', descending: true)
        .snapshots();
  }

  Future<void> resgatarRecompensa(String recompensaId, int custo) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    final alunoDoc = await _db
        .collection(FirestoreCollections.alunos)
        .doc(user.uid)
        .get();

    final pontos = alunoDoc.data()?['pontos'] ?? 0;

    if (pontos < custo) {
      throw Exception('Pontos insuficientes');
    }

    final batch = _db.batch();

    final resgateRef = _db.collection(FirestoreCollections.resgates).doc();

    batch.set(resgateRef, {
      'id': resgateRef.id,
      'alunoUid': user.uid,
      'recompensaId': recompensaId,
      'status': 'pendente',
      'data': FieldValue.serverTimestamp(),
      'custo': custo,
    });

    batch.update(_db.collection(FirestoreCollections.alunos).doc(user.uid), {
      'pontos': FieldValue.increment(-custo),
    });

    await batch.commit();
  }

  /// Cria uma solicitação de resgate com status [PENDENTE].
  ///
  /// Os pontos NÃO são debitados aqui; o débito ocorre somente quando
  /// o admin confirmar o resgate no painel administrativo.
  ///
  /// Regra de negócio aplicada: 1 ponto = R$0,10 de desconto.
  /// O usuário precisa ter exatamente [custoPontos] pontos para resgatar.
  /// Validade da solicitação: 7 dias a partir da criação.
  Future<void> criarSolicitacaoResgate({
    required String recompensaId,
    required int custoPontos,
    required String titulo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não logado');

    final alunoDoc = await _db
        .collection(FirestoreCollections.alunos)
        .doc(user.uid)
        .get();

    final pontos = (alunoDoc.data()?['pontos'] as num?)?.toInt() ?? 0;

    if (pontos < custoPontos) {
      final faltam = custoPontos - pontos;
      throw Exception('Faltam $faltam pontos para resgatar esta recompensa.');
    }

    // Impede duplicata: verifica se já existe solicitação PENDENTE para este item
    final pendentes = await _db
        .collection(FirestoreCollections.resgates)
        .where('alunoUid', isEqualTo: user.uid)
        .where('recompensaId', isEqualTo: recompensaId)
        .where('status', isEqualTo: 'PENDENTE')
        .get();

    if (pendentes.docs.isNotEmpty) {
      throw Exception(
        'Você já possui uma solicitação pendente para esta recompensa.',
      );
    }

    final validade = DateTime.now().add(const Duration(days: 7));
    final resgateRef = _db.collection(FirestoreCollections.resgates).doc();

    await resgateRef.set({
      'id': resgateRef.id,
      'alunoUid': user.uid,
      'recompensaId': recompensaId,
      'titulo': titulo,
      'status': 'PENDENTE',
      'data': FieldValue.serverTimestamp(),
      // Validade: 7 dias. O admin deve confirmar antes deste prazo.
      'validade': Timestamp.fromDate(validade),
      'custo_pontos': custoPontos,
      // NOTA: pontos NÃO são debitados aqui.
      // O admin confirma → debita os pontos via painel admin.
    });
  }

  /// Retorna true se o aluno já registrou presença hoje,
  /// comparando [ultimoCheckin] com a data atual.
  /// Diferente de [qrValidadoHoje], este campo persiste após o treino.
  bool checkinHoje(Map<String, dynamic> data) {
    final ts = data['ultimoCheckin'] as Timestamp?;
    if (ts == null) return false;
    final now = DateTime.now();
    final check = ts.toDate();
    return check.year == now.year &&
        check.month == now.month &&
        check.day == now.day;
  }

  // ────────────────────────────
  // CHECKIN (async)
  // ────────────────────────────

  /// Versão async de [checkinHoje]: busca o documento e verifica
  /// se o aluno já registrou presença hoje (campo [ultimoCheckin]).
  Future<bool> verificarCheckinHoje() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _db
        .collection(FirestoreCollections.alunos)
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return false;
    return checkinHoje(data);
  }

  // ────────────────────────────
  // HISTÓRICO DE TREINOS
  // ────────────────────────────

  /// Salva um registro de treino concluído em
  /// `alunos/{uid}/historico_treinos/`.
  Future<void> saveHistoricoTreino({
    required String treinoId,
    required String treinoNome,
    required int duracaoMinutos,
    required int setsConcluidos,
    required int setsTotais,
    required int pontosGanhos,
    required bool comCheckin,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection(FirestoreCollections.alunos)
        .doc(user.uid)
        .collection('historico_treinos')
        .add({
      'treino_id': treinoId,
      'treino_nome': treinoNome,
      'data': FieldValue.serverTimestamp(),
      'duracao_minutos': duracaoMinutos,
      'sets_concluidos': setsConcluidos,
      'sets_totais': setsTotais,
      'pontos_ganhos': pontosGanhos,
      'com_checkin': comCheckin,
    });
  }
}
