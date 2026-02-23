/// Enum que define os períodos disponíveis para o ranking.
enum RankingPeriodo { semanal, mensal, trimestral }

/// Extensão com helpers de label e cálculo de data de início do período.
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

  /// Retorna o DateTime de início do período atual.
  DateTime get inicio {
    final now = DateTime.now();
    switch (this) {
      // Segunda-feira da semana atual (weekday 1 = segunda)
      case RankingPeriodo.semanal:
        final diasDesdeSegunda = now.weekday - 1; // Monday = 1
        return DateTime(now.year, now.month, now.day - diasDesdeSegunda);

      // Primeiro dia do mês atual
      case RankingPeriodo.mensal:
        return DateTime(now.year, now.month, 1);

      // 90 dias atrás
      case RankingPeriodo.trimestral:
        return now.subtract(const Duration(days: 90));
    }
  }
}
