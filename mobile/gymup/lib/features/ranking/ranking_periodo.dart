/// Enum que define os períodos disponíveis para o ranking.
enum RankingPeriodo { semanal, mensal, trimestral }

/// Extensão com helpers de label e parâmetro de API do período.
extension RankingPeriodoExtension on RankingPeriodo {
  /// Rótulo exibido nos chips de filtro.
  String get label {
    switch (this) {
      case RankingPeriodo.semanal:
        return 'Semana';
      case RankingPeriodo.mensal:
        return 'Mês';
      case RankingPeriodo.trimestral:
        return '3 Meses';
    }
  }

  /// Parâmetro enviado à API para filtrar o período.
  String get param {
    switch (this) {
      case RankingPeriodo.semanal:
        return 'weekly';
      case RankingPeriodo.mensal:
        return 'monthly';
      case RankingPeriodo.trimestral:
        return 'quarterly';
    }
  }
}
