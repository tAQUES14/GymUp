<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserTrainingSchedule;
use Illuminate\Http\Request;

class TrainingScheduleController extends Controller
{
    /**
     * GET /api/training-schedule
     *
     * Returns the authenticated user's weekly training days.
     * day_of_week: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
     */
    public function show(Request $request)
    {
        $days = UserTrainingSchedule::where('user_id', $request->user()->id)
            ->orderBy('day_of_week')
            ->pluck('day_of_week');

        return response()->json(['training_days' => $days]);
    }

    /**
     * PUT /api/training-schedule
     *
     * Replaces the user's entire training schedule.
     * Body: { "days": [1, 2, 4, 5] }  // 0=Sun ... 6=Sat
     * Sending an empty array clears the schedule.
     */
    public function update(Request $request)
    {
        $request->validate([
            'days'   => 'required|array',
            'days.*' => 'integer|between:0,6',
        ]);

        $user = $request->user();
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
