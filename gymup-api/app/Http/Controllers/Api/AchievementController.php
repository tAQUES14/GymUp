<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Achievement;
use App\Models\WorkoutHistory;
use Illuminate\Http\Request;

class AchievementController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $workoutsTotal = WorkoutHistory::where('user_id', $user->id)->count();
        $streakDays    = (int) ($user->weekly_streak ?? 0);

        $achievements = Achievement::all()->map(function (Achievement $achievement) use ($workoutsTotal, $streakDays) {
            $progress = match ($achievement->metric) {
                'workouts_total' => $workoutsTotal,
                'streak_days'    => $streakDays,
                default          => 0,
            };

            $progress = min($progress, $achievement->target_value);

            return [
                'title'        => $achievement->title,
                'description'  => $achievement->description,
                'progress'     => $progress,
                'target'       => $achievement->target_value,
                'pointsReward' => $achievement->points_reward,
                'unlocked'     => $progress >= $achievement->target_value,
            ];
        });

        return response()->json($achievements);
    }
}
