<?php

namespace App\Services;

use App\Models\Achievement;
use App\Models\User;
use App\Models\UserAchievement;
use App\Models\WorkoutSession;
use Illuminate\Support\Facades\DB;

class AchievementService
{
    public function __construct(private readonly PointService $points) {}

    public function allFor(User $user): array
    {
        $stats = $this->statsFor($user);
        $unlocked = UserAchievement::where('user_id', $user->id)
            ->get()
            ->keyBy('achievement_id');

        return Achievement::orderBy('metric')
            ->orderBy('target_value')
            ->get()
            ->map(function (Achievement $achievement) use ($stats, $unlocked) {
                $progress = $this->progressFor($achievement, $stats);
                $record = $unlocked->get($achievement->id);

                return $this->serialize($achievement, $progress, (bool) $record, $record?->unlocked_at?->toIso8601String());
            })
            ->all();
    }

    public function grantNewlyUnlocked(User $user): array
    {
        $stats = $this->statsFor($user);
        $unlocked = [];

        Achievement::orderBy('metric')
            ->orderBy('target_value')
            ->get()
            ->each(function (Achievement $achievement) use ($user, $stats, &$unlocked) {
                $progress = $this->progressFor($achievement, $stats);
                if ($progress < (int) $achievement->target_value) {
                    return;
                }

                DB::transaction(function () use ($user, $achievement, $progress, &$unlocked) {
                    $record = UserAchievement::firstOrCreate(
                        [
                            'user_id' => $user->id,
                            'achievement_id' => $achievement->id,
                        ],
                        [
                            'points_awarded' => (int) $achievement->points_reward,
                            'unlocked_at' => now(),
                        ]
                    );

                    if (! $record->wasRecentlyCreated) {
                        return;
                    }

                    $points = (int) $achievement->points_reward;
                    if ($points > 0) {
                        $this->points->earnPoints(
                            $user,
                            $points,
                            "Conquista desbloqueada: {$achievement->title}",
                            'achievement',
                            $achievement->id
                        );
                    }

                    $unlocked[] = $this->serialize(
                        $achievement,
                        $progress,
                        true,
                        $record->unlocked_at?->toIso8601String(),
                    );
                });
            });

        return $unlocked;
    }

    private function statsFor(User $user): array
    {
        return [
            'workouts_total' => WorkoutSession::where('user_id', $user->id)
                ->where('points_granted', true)
                ->count(),
            'streak_days' => (int) ($user->current_streak ?? $user->weekly_streak ?? 0),
        ];
    }

    private function progressFor(Achievement $achievement, array $stats): int
    {
        return min(
            (int) ($stats[$achievement->metric] ?? 0),
            (int) $achievement->target_value,
        );
    }

    private function serialize(Achievement $achievement, int $progress, bool $unlocked, ?string $unlockedAt): array
    {
        return [
            'id'            => $achievement->id,
            'code'          => $achievement->code,
            'title'         => $achievement->title,
            'description'   => $achievement->description,
            'metric'        => $achievement->metric,
            'icon'          => $achievement->icon,
            'progress'      => $progress,
            'target'        => (int) $achievement->target_value,
            'target_value'  => (int) $achievement->target_value,
            'pointsReward'  => (int) $achievement->points_reward,
            'points_reward' => (int) $achievement->points_reward,
            'unlocked'      => $unlocked,
            'unlocked_at'   => $unlockedAt,
        ];
    }
}
