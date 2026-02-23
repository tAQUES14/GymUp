/// Configurações globais da aplicação.
/// Mudar [kDevMode] para false antes de publicar em produção.
const bool kDevMode = true;

/// Tempo mínimo de treino (em minutos) para pontuar presença.
/// Em dev: 1 min. Em produção: 15 min.
const int kMinTrainingMinutes = kDevMode ? 1 : 15;
