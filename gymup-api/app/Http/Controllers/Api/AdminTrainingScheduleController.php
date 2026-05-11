<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserTrainingSchedule;
use Illuminate\Http\Request;

/**
 * Endpoint legado de agenda manual do aluno.
 *
 * DEPRECATED: A agenda manual não influencia mais streak nem pontos.
 * O streak é calculado com base no plano de treino (WorkoutPlan).
 * Este controller é mantido apenas para leitura histórica e compatibilidade.
 */
class AdminTrainingScheduleController extends Controller
{
    /**
     * GET /api/admin/users/{id}/training-schedule
     *
     * Returns the student's current training days.
     * Response: { "training_days": [1, 2, 4, 5], "current_streak": 3, "best_streak": 7 }
     */
    public function show(Request $request, int $userId)
    {
        $admin = $request->user();

        $user = User::where('id', $userId)
            ->where('gym_id', $admin->activeGymId())
            ->firstOrFail();

        $days = UserTrainingSchedule::where('user_id', $user->id)
            ->orderBy('day_of_week')
            ->pluck('day_of_week');

        return response()->json([
            'training_days'  => $days,
            'current_streak' => (int) $user->current_streak,
            'best_streak'    => (int) $user->best_streak,
        ]);
    }

    /**
     * PUT /api/admin/users/{id}/training-schedule
     *
     * Mantido por compatibilidade. Salva os dias mas não afeta o streak.
     * O streak é calculado com base no plano de treino do aluno.
     */
    public function update(Request $request, int $userId)
    {
        $request->validate([
            'days'   => 'required|array',
            'days.*' => 'integer|between:0,6',
        ]);

        $admin = $request->user();

        $user = User::where('id', $userId)
            ->where('gym_id', $admin->activeGymId())
            ->firstOrFail();

        $days = array_values(array_unique($request->days));

        UserTrainingSchedule::where('user_id', $user->id)->delete();

        foreach ($days as $day) {
            UserTrainingSchedule::create([
                'user_id'     => $user->id,
                'gym_id'      => $user->gym_id,
                'day_of_week' => $day,
            ]);
        }

        return response()->json([
            'message'       => 'Agenda de treinos atualizada.',
            'training_days' => $days,
        ]);
    }
}
