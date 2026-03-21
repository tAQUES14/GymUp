<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Achievement;
use App\Models\User;
use App\Models\WorkoutHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AdminAchievementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $achievements = Achievement::orderBy('metric')->orderBy('target_value')->get();

        // Pre-compute unlocked counts per metric to avoid N+1
        $workoutCountsByUser = WorkoutHistory::selectRaw('user_id, COUNT(*) as total')
            ->groupBy('user_id')
            ->pluck('total', 'user_id');

        $streakByUser = User::where('role', 'user')
            ->pluck('weekly_streak', 'id');

        $mapped = $achievements->map(function (Achievement $a) use ($workoutCountsByUser, $streakByUser) {
            $unlockedCount = match ($a->metric) {
                'workouts_total' => $workoutCountsByUser->filter(fn ($v) => $v >= $a->target_value)->count(),
                'streak_days'    => $streakByUser->filter(fn ($v) => $v >= $a->target_value)->count(),
                default          => 0,
            };

            return [
                'id'             => $a->id,
                'code'           => $a->code,
                'title'          => $a->title,
                'description'    => $a->description,
                'metric'         => $a->metric,
                'target_value'   => $a->target_value,
                'points_reward'  => $a->points_reward,
                'icon'           => $a->icon,
                'unlocked_count' => $unlockedCount,
            ];
        });

        return response()->json(['achievements' => $mapped]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title'         => 'required|string|max:100',
            'description'   => 'required|string|max:255',
            'metric'        => 'required|in:workouts_total,streak_days',
            'target_value'  => 'required|integer|min:1',
            'points_reward' => 'required|integer|min:0',
        ]);

        $data['code'] = Str::slug($data['title']) . '_' . $data['target_value'];
        $data['icon'] = $data['metric'] === 'streak_days' ? 'streak' : 'fitness';

        $achievement = Achievement::create($data);

        return response()->json(['achievement' => $achievement], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $achievement = Achievement::findOrFail($id);

        $data = $request->validate([
            'title'         => 'required|string|max:100',
            'description'   => 'required|string|max:255',
            'metric'        => 'required|in:workouts_total,streak_days',
            'target_value'  => 'required|integer|min:1',
            'points_reward' => 'required|integer|min:0',
        ]);

        $data['icon'] = $data['metric'] === 'streak_days' ? 'streak' : 'fitness';

        $achievement->update($data);

        return response()->json(['achievement' => $achievement]);
    }

    public function destroy(int $id): JsonResponse
    {
        Achievement::findOrFail($id)->delete();

        return response()->json(['message' => 'Conquista removida.']);
    }
}
