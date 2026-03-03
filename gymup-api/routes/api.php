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

/*
|--------------------------------------------------------------------------
| Rotas Públicas
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

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

    // 🔹 Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // 🔹 Pontos
    Route::get('/points/history', [PointController::class, 'history']);

    // 🔹 Ranking
    Route::get('/ranking', [RankingController::class, 'index']);

    // 🔹 Recompensas
    Route::get('/rewards', [RewardController::class, 'index']);
    Route::post('/redeem', [RedemptionController::class, 'store']);

    // 🔹 Check-in
    Route::post('/checkin', [CheckinController::class, 'store']);

    // 🔹 Workouts (sessão ativa)
    Route::prefix('workout')->group(function () {
        Route::post('/start', [WorkoutController::class, 'start']);
        Route::post('/progress', [WorkoutController::class, 'updateProgress']);
        Route::post('/finish', [WorkoutController::class, 'finish']);
        Route::get('/status', [WorkoutController::class, 'status']);
    });

    // 🔹 Histórico de Cargas (Weight)
    Route::prefix('exercises')->group(function () {
        Route::put('{exercise}/weight/set', [WeightController::class, 'saveSetWeight']);
        Route::get('{exercise}/weight/last', [WeightController::class, 'last']);
        Route::get('{exercise}/history', [WeightController::class, 'history']);
        Route::get('{exercise}/progress', [WeightController::class, 'progress']);
        Route::get('{exercise}/pr', [WeightController::class, 'pr']);
        Route::get('{exercise}/progress-score', [WeightController::class, 'progressScore']);
    });

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

    // 🔹 Resumo de Progresso (agregado)
    Route::get('/me/progress-summary', [ProgressSummaryController::class, 'index']);

    /*
    |--------------------------------------------------------------------------
    | Rotas Admin
    |--------------------------------------------------------------------------
    */

    Route::middleware('role:admin')->group(function () {
        Route::get('/admin/dashboard', [AdminDashboardController::class, 'index']);
        Route::get('/admin/redemptions', [RedemptionController::class, 'index']);
        Route::post('/redemptions/{id}/approve', [RedemptionController::class, 'approve']);
    });

});