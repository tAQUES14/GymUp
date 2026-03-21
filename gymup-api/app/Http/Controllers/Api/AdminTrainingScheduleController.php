<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\UserTrainingSchedule;
use Illuminate\Http\Request;

/**
 * Trainer/gym_admin endpoint to manage a student's weekly training schedule.
 *
 * Day convention (matches Carbon::dayOfWeek):
 *   0 = Sunday, 1 = Monday, 2 = Tuesday, 3 = Wednesday,
 *   4 = Thursday, 5 = Friday, 6 = Saturday
 *
 * Setting last_schedule_change prevents StreakService from reinterpreting
 * days before the change when checking for missed training days.
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
            ->where('gym_id', $admin->gym_id)
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
     * Replaces the student's entire training schedule.
     * Body: { "days": [1, 2, 4, 5] }
     *
     * Records last_schedule_change so the streak system only checks
     * for missed training days from this date forward.
     */
    public function update(Request $request, int $userId)
    {
        $request->validate([
            'days'   => 'required|array',
            'days.*' => 'integer|between:0,6',
        ]);

        $admin = $request->user();

        $user = User::where('id', $userId)
            ->where('gym_id', $admin->gym_id)
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

        // Record the date of this change so StreakService does not
        // retroactively check days before the schedule was updated.
        $user->last_schedule_change = now()->toDateString();
        $user->save();

        return response()->json([
            'message'       => 'Agenda de treinos atualizada.',
            'training_days' => $days,
        ]);
    }
}
