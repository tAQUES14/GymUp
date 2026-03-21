<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CheckinController;
use App\Http\Controllers\Api\RedemptionController;
use App\Http\Controllers\Api\RankingController;
use App\Http\Controllers\Api\PointController;
use App\Http\Controllers\Api\AdminDashboardController;
use App\Http\Controllers\Api\RewardController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\WorkoutController;
use App\Http\Controllers\Api\WeightController;
use App\Http\Controllers\Api\CustomWorkoutController;
use App\Http\Controllers\Api\WorkoutHistoryController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ProgressSummaryController;
use App\Http\Controllers\Api\GoalController;
use App\Http\Controllers\Api\BodyWeightController;
use App\Http\Controllers\Api\ChallengeController;
use App\Http\Controllers\Api\AdminChallengeController;
use App\Http\Controllers\Api\AchievementController;
use App\Http\Controllers\Api\Auth\PasswordResetController;
use App\Http\Controllers\Api\AdminUserController;
use App\Http\Controllers\Api\AdminWorkoutController;
use App\Http\Controllers\Api\AdminExerciseController;
use App\Http\Controllers\Api\AdminRankingController;
use App\Http\Controllers\Api\AdminAchievementController;
use App\Http\Controllers\Api\AdminRewardController;
use App\Http\Controllers\Api\AdminReportsController;
use App\Http\Controllers\Api\AdminSettingsController;
use App\Http\Controllers\Api\TrainingScheduleController;
use App\Http\Controllers\Api\AdminTrainingScheduleController;
use App\Http\Controllers\Api\WorkoutPlanController;
use App\Http\Controllers\Api\AdminWorkoutPlanController;
use App\Http\Controllers\Api\WorkoutSetController;
use App\Http\Controllers\Api\AdminExerciseOverrideController;
use App\Http\Controllers\Api\ExerciseController;
use App\Http\Controllers\Api\NotificationController;

/*
|--------------------------------------------------------------------------
| Rotas Públicas
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// 🔹 Catálogo de exercícios (público — usado pelo app antes do login)
// /library must be declared before /{id} so it is not captured by the wildcard
Route::get('/exercises/library', [ExerciseController::class, 'index']);
Route::get('/exercises/{id}',    [ExerciseController::class, 'show']);
Route::get('/exercises',         [ExerciseController::class, 'index']); // backward-compat

// Recuperação de senha (sem autenticação)
Route::prefix('auth')->group(function () {
    Route::post('/forgot-password', [PasswordResetController::class, 'forgotPassword']);
    Route::post('/reset-password',  [PasswordResetController::class, 'resetPassword']);
});

/*
|--------------------------------------------------------------------------
| Rotas Protegidas (AUTH SANCTUM)
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {

    // 🔹 Usuário
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // 🔹 Perfil
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);

    // 🔹 Resumo de Progresso
    Route::get('/me/progress-summary', [ProgressSummaryController::class, 'index']);

    // 🔹 Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // 🔹 Pontos
    Route::get('/points/history', [PointController::class, 'history']);

    // 🔹 Ranking
    Route::get('/ranking', [RankingController::class, 'index']);

    // 🔹 Recompensas
    Route::get('/rewards', [RewardController::class, 'index']);
    Route::post('/redeem', [RedemptionController::class, 'store']);

    // 🔹 Histórico de resgates do aluno
    Route::get('/user/redemptions', [RedemptionController::class, 'userIndex']);

    // 🔹 Notificações do usuário
    Route::prefix('user/notifications')->group(function () {
        Route::get('/',             [NotificationController::class, 'index']);
        Route::post('/read-all',    [NotificationController::class, 'markAllRead']);
        Route::post('/{id}/read',   [NotificationController::class, 'markRead']);
    });

    // 🔹 Check-in
    Route::post('/checkin', [CheckinController::class, 'store']);

    // 🔹 Workouts (sessão ativa)
    Route::prefix('workout')->group(function () {
        Route::post('/start', [WorkoutController::class, 'start']);
        Route::post('/progress', [WorkoutController::class, 'updateProgress']);
        Route::post('/finish', [WorkoutController::class, 'finish']);
        Route::get('/status', [WorkoutController::class, 'status']);
    });

    // 🔹 Endpoint alternativo: POST /workout-sessions/{id}/finish
    Route::post('/workout-sessions/{id}/finish', [WorkoutController::class, 'finish']);

    // 🔹 Histórico de Cargas (Weight) + Substituições + Últimas séries
    Route::prefix('exercises')->group(function () {
        Route::get('prs', [WorkoutSetController::class, 'allPRs']);
        Route::put('{exercise}/weight/set', [WeightController::class, 'saveSetWeight']);
        Route::get('{exercise}/weight/last', [WeightController::class, 'last']);
        Route::get('{exercise}/history', [WeightController::class, 'history']);
        Route::get('{exercise}/progress', [WeightController::class, 'progress']);
        Route::get('{exercise}/pr', [WeightController::class, 'pr']);
        Route::get('{exercise}/progress-score', [WeightController::class, 'progressScore']);
        Route::get('{exercise}/substitutions', [AdminExerciseController::class, 'substitutions']);
        Route::get('{exercise}/last-sets', [WorkoutSetController::class, 'lastSets']);
        Route::get('{exercise}/workout-history', [WorkoutSetController::class, 'workoutHistory']);
    });

    // 🔹 Registro de séries por exercício
    Route::post('/workout-sets', [WorkoutSetController::class, 'store']);

    // 🔹 Treinos Personalizados (IA)
    Route::prefix('custom-workouts')->group(function () {
        Route::get('/', [CustomWorkoutController::class, 'index']);
        Route::post('/', [CustomWorkoutController::class, 'store']);
        Route::get('{id}', [CustomWorkoutController::class, 'show']);
        Route::delete('{id}', [CustomWorkoutController::class, 'destroy']);
    });

    Route::prefix('workout-history')->group(function () {
        Route::post('/', [WorkoutHistoryController::class, 'store']);
        Route::get('/', [WorkoutHistoryController::class, 'index']);
    });

    Route::get('/checkin/status', [CheckinController::class, 'status']);

    // 🔹 Metas pessoais
    Route::post('/goals/preview', [GoalController::class, 'preview']);
    Route::post('/goals', [GoalController::class, 'store']);
    Route::get('/goals/current', [GoalController::class, 'current']);

    // 🔹 Histórico de peso corporal
    Route::post('/body-weight', [BodyWeightController::class, 'store']);
    Route::get('/body-weight', [BodyWeightController::class, 'index']);

    // 🔹 Agenda de treinos — leitura pelo próprio usuário (escrita é exclusiva do admin)
    Route::get('/training-schedule', [TrainingScheduleController::class, 'show']);

    // 🔹 Conquistas
    Route::get('/achievements', [AchievementController::class, 'index']);

    // 🔹 Desafios (aluno)
    Route::get('/challenges/active', [ChallengeController::class, 'active']);
    Route::get('/challenges/{id}/ranking', [ChallengeController::class, 'ranking']);

    // 🔹 Plano de treino sequencial
    Route::get('/workout-plan/today', [WorkoutPlanController::class, 'today']);
    Route::get('/workout-plan/current', [WorkoutPlanController::class, 'current']);

    /*
    |--------------------------------------------------------------------------
    | Rotas Admin — acessíveis a super_admin e trainer
    |--------------------------------------------------------------------------
    */

    Route::middleware('role:super_admin,gym_admin,trainer')->prefix('admin')->group(function () {
        // 🔹 Dashboard
        Route::get('/dashboard', [AdminDashboardController::class, 'index']);

        // 🔹 Relatórios
        Route::get('/reports', [AdminReportsController::class, 'index']);

        // 🔹 Configurações
        Route::get('/settings',           [AdminSettingsController::class, 'index']);
        Route::put('/settings/gym',       [AdminSettingsController::class, 'updateGym']);
        Route::put('/settings/account',   [AdminSettingsController::class, 'updateAccount']);
        Route::put('/settings/password',  [AdminSettingsController::class, 'updatePassword']);

        // 🔹 Alunos
        Route::get('/users',                                              [AdminUserController::class, 'index']);
        Route::get('/users/{id}',                                         [AdminUserController::class, 'show']);
        Route::put('/users/{id}',                                         [AdminUserController::class, 'update']);
        Route::delete('/users/{id}',                                      [AdminUserController::class, 'destroy']);
        Route::post('/users/{id}/adjust-points',                          [AdminUserController::class, 'adjustPoints']);
        Route::get('/users/{id}/training-schedule',  [AdminTrainingScheduleController::class, 'show']);
        Route::put('/users/{id}/training-schedule',  [AdminTrainingScheduleController::class, 'update']);

        // 🔹 Treinos
        Route::get('/workouts',                                           [AdminWorkoutController::class, 'index']);
        Route::post('/workouts',                                          [AdminWorkoutController::class, 'store']);
        Route::get('/workouts/{id}',                                      [AdminWorkoutController::class, 'show']);
        Route::put('/workouts/{id}',                                      [AdminWorkoutController::class, 'update']);
        Route::delete('/workouts/{id}',                                   [AdminWorkoutController::class, 'destroy']);
        Route::post('/workouts/{id}/assign',                              [AdminWorkoutController::class, 'assign']);
        Route::delete('/workouts/{id}/assignments/{assignmentId}',        [AdminWorkoutController::class, 'removeAssignment']);

        // 🔹 Planos de treino sequenciais
        Route::get('/workout-plans', [AdminWorkoutPlanController::class, 'index']);
        Route::post('/workout-plans', [AdminWorkoutPlanController::class, 'store']);
        Route::get('/workout-plans/{id}', [AdminWorkoutPlanController::class, 'show']);
        Route::put('/workout-plans/{id}', [AdminWorkoutPlanController::class, 'update']);
        Route::delete('/workout-plans/{id}', [AdminWorkoutPlanController::class, 'destroy']);
        Route::post('/workout-plans/{id}/days', [AdminWorkoutPlanController::class, 'addDay']);
        Route::post('/workout-plans/{planId}/days/from-template', [AdminWorkoutPlanController::class, 'addDayFromTemplate']);
        Route::patch('/workout-plans/{planId}/days/reorder', [AdminWorkoutPlanController::class, 'reorderDays']);
        Route::put('/workout-plans/{planId}/days/{dayId}', [AdminWorkoutPlanController::class, 'updateDay']);
        Route::delete('/workout-plans/{planId}/days/{dayId}', [AdminWorkoutPlanController::class, 'destroyDay']);
        Route::post('/users/{userId}/assign-plan', [AdminWorkoutPlanController::class, 'assignPlan']);

        // 🔹 Exercícios (catálogo — para seleção no modal)
        Route::get('/exercises', [AdminExerciseController::class, 'index']);
        Route::post('/exercises', [AdminExerciseController::class, 'store']);
        // GIF management — must be declared before /{id} routes
        Route::get('/exercises/gif-mapping', [AdminExerciseController::class, 'gifMapping']);
        Route::get('/exercises/available-gifs', [AdminExerciseController::class, 'availableGifs']);
        Route::put('/exercises/{id}', [AdminExerciseController::class, 'update']);
        Route::delete('/exercises/{id}', [AdminExerciseController::class, 'destroy']);
        Route::post('/exercises/{id}/duplicate', [AdminExerciseController::class, 'duplicate']);
        Route::post('/exercises/{id}/link-gif', [AdminExerciseController::class, 'linkGif']);
        Route::get('/exercises/{id}/suggest-gifs', [AdminExerciseController::class, 'suggestGifs']);
        Route::get('/exercises/{id}/substitutions', [AdminExerciseController::class, 'substitutions']);
        Route::post('/exercises/{id}/substitutions', [AdminExerciseController::class, 'addSubstitution']);
        Route::delete('/exercises/{id}/substitutions/{substituteId}', [AdminExerciseController::class, 'removeSubstitution']);

        // 🔹 Personalizações de exercício por aluno
        Route::get('/users/{userId}/exercise-overrides',                   [AdminExerciseOverrideController::class, 'index']);
        Route::get('/users/{userId}/exercises/{exerciseId}/override',      [AdminExerciseOverrideController::class, 'show']);
        Route::put('/users/{userId}/exercises/{exerciseId}/override',      [AdminExerciseOverrideController::class, 'upsert']);
        Route::delete('/users/{userId}/exercises/{exerciseId}/override',   [AdminExerciseOverrideController::class, 'destroy']);

        // 🔹 Recompensas (admin)
        Route::get('/rewards',                      [AdminRewardController::class, 'index']);
        Route::post('/rewards',                     [AdminRewardController::class, 'store']);
        Route::put('/rewards/{id}',                 [AdminRewardController::class, 'update']);
        Route::post('/rewards/{id}',                [AdminRewardController::class, 'update']); // multipart/FormData
        Route::delete('/rewards/{id}',              [AdminRewardController::class, 'destroy']);
        Route::patch('/rewards/{id}/toggle',        [AdminRewardController::class, 'toggle']);

        // 🔹 Resgates (admin — gym_admin e super_admin)
        Route::get('/redemptions',                       [RedemptionController::class, 'index']);
        Route::post('/redemptions/{id}/approve',         [RedemptionController::class, 'approve']);
        Route::post('/redemptions/{id}/reject',          [RedemptionController::class, 'reject']);

        // 🔹 Ranking (admin)
        Route::get('/ranking', [AdminRankingController::class, 'index']);

        // 🔹 Conquistas (admin — catálogo global)
        Route::get('/achievements',          [AdminAchievementController::class, 'index']);
        Route::post('/achievements',         [AdminAchievementController::class, 'store']);
        Route::put('/achievements/{id}',     [AdminAchievementController::class, 'update']);
        Route::delete('/achievements/{id}',  [AdminAchievementController::class, 'destroy']);

        // 🔹 Desafios (admin)
        Route::get('/challenges', [AdminChallengeController::class, 'index']);
        Route::post('/challenges', [AdminChallengeController::class, 'store']);
        Route::get('/challenges/{id}', [AdminChallengeController::class, 'show']);
        Route::put('/challenges/{id}', [AdminChallengeController::class, 'update']);
        Route::delete('/challenges/{id}', [AdminChallengeController::class, 'destroy']);
        Route::post('/challenges/{id}/finish', [AdminChallengeController::class, 'finish']);

        /*
        |----------------------------------------------------------------------
        | Rotas exclusivas para super_admin
        |----------------------------------------------------------------------
        */
        Route::middleware('role:super_admin')->group(function () {
            // (nenhuma rota exclusiva no momento)
        });
    });

});