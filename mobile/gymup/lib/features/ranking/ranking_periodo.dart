/// Enum que define os períodos disponíveis para o ranking.
enum RankingPeriodo { all, semanal, mensal, trimestral, progress }

/// Enum que define o escopo de alunos listados no ranking.
enum RankingEscopo { gym, chain }

/// Extensão com helpers de label e parâmetro de API do escopo.
extension RankingEscopoExtension on RankingEscopo {
  String get label {
    switch (this) {
      case RankingEscopo.gym:
        return 'Minha academia';
      case RankingEscopo.chain:
        return 'Minha rede';
    }
  }

  String get param {
    switch (this) {
      case RankingEscopo.gym:
        return 'gym';
      case RankingEscopo.chain:
        return 'chain';
    }
  }
}

/// Extensão com helpers de label e parâmetro de API do período.
extension RankingPeriodoExtension on RankingPeriodo {
  /// Rótulo exibido nos chips de filtro.
  String get label {
    switch (this) {
      case RankingPeriodo.all:
        return 'Geral';
      case RankingPeriodo.semanal:
        return 'Semana';
      case RankingPeriodo.mensal:
        return 'Mês';
      case RankingPeriodo.trimestral:
        return '3 Meses';
      case RankingPeriodo.progress:
        return 'Progresso';
    }
  }

  /// Parâmetro enviado à API para filtrar o período.
  String get param {
    switch (this) {
      case RankingPeriodo.all:
        return 'all';
      case RankingPeriodo.semanal:
        return 'weekly';
      case RankingPeriodo.mensal:
        return 'monthly';
      case RankingPeriodo.trimestral:
        return 'quarterly';
      case RankingPeriodo.progress:
        return 'progress';
    }
  }
}
