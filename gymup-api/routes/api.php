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




Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::get('/rewards', [RewardController::class, 'index']);
    Route::post('/checkin', [CheckinController::class, 'store']);
    Route::post('/redeem', [RedemptionController::class, 'store']);
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/redemptions/{id}/approve',[RedemptionController::class, 'approve'])->middleware('role:admin');
    Route::get('/admin/redemptions', [RedemptionController::class, 'index'])->middleware('role:admin');
    Route::get('/ranking', [RankingController::class, 'index']);
    Route::get('/points/history', [PointController::class, 'history']);
    Route::get('/admin/dashboard', [AdminDashboardController::class, 'index'])
        ->middleware('role:admin');

    Route::prefix('workout')->group(function () {
        Route::post('/start',    [WorkoutController::class, 'start']);
        Route::post('/progress', [WorkoutController::class, 'updateProgress']);
        Route::post('/finish',   [WorkoutController::class, 'finish']);
        Route::get('/status',    [WorkoutController::class, 'status']);
    });
});