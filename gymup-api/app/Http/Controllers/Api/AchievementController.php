<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Achievement;
use App\Models\WorkoutSession;
use Illuminate\Http\Request;

class AchievementController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $workoutsTotal = WorkoutSession::where('user_id', $user->id)
            ->where('points_granted', true)
            ->count();
        $streakDays    = (int) ($user->current_streak ?? $user->weekly_streak ?? 0);

        $achievements = Achievement::orderBy('metric')
            ->orderBy('target_value')
            ->get()
            ->map(function (Achievement $achievement) use ($workoutsTotal, $streakDays) {
                $progress = match ($achievement->metric) {
                    'workouts_total' => $workoutsTotal,
                    'streak_days'    => $streakDays,
                    default          => 0,
                };

                $progress = min($progress, $achievement->target_value);

                return [
                    'id'            => $achievement->id,
                    'code'          => $achievement->code,
                    'title'         => $achievement->title,
                    'description'   => $achievement->description,
                    'metric'        => $achievement->metric,
                    'icon'          => $achievement->icon,
                    'progress'      => $progress,
                    'target'        => $achievement->target_value,
                    'target_value'  => $achievement->target_value,
                    'pointsReward'  => $achievement->points_reward,
                    'points_reward' => $achievement->points_reward,
                    'unlocked'      => $progress >= $achievement->target_value,
                ];
            });

        return response()->json($achievements);
    }
}
