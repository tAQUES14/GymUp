<?php

namespace Database\Seeders;

use App\Models\Achievement;
use App\Models\ChallengeParticipant;
use App\Models\ChallengeWeeklyRanking;
use App\Models\Checkin;
use App\Models\GymChallenge;
use App\Models\PointTransaction;
use App\Models\User;
use App\Models\WorkoutSession;
use App\Services\AchievementService;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DemoWeekSeeder extends Seeder
{
    private const CHALLENGE_NAME = 'Desafio Semana em Movimento';
    private const POINTS_DESCRIPTION = 'Carga demo: semana de treinos';

    public function run(): void
    {
        $this->call(AchievementSeeder::class);

        $studentsByGym = User::query()
            ->where('role', 'user')
            ->orderBy('gym_id')
            ->orderBy('name')
            ->get()
            ->groupBy('gym_id');

        foreach ($studentsByGym as $gymId => $students) {
            DB::transaction(function () use ($gymId, $students) {
                $challenge = $this->upsertChallenge((int) $gymId);

                foreach ($students->values() as $index => $student) {
                    $profile = $this->profileFor($student, $index);

                    $this->seedStudentWeek($student, $profile);
                    $this->seedChallengeProgress($challenge, $student, $profile, $index + 1);
                }
            });
        }

        $achievements = app(AchievementService::class);
        User::where('role', 'user')->get()->each(
            fn (User $student) => $achievements->grantNewlyUnlocked($student)
        );

        $this->command?->info('Semana demo populada para todos os alunos atuais.');
    }

    private function profileFor(User $student, int $index): array
    {
        if (str_contains(mb_strtolower($student->name), 'marcos taques')) {
            return ['workouts' => 2, 'points' => 150, 'streak' => 2, 'goal' => 3, 'challenge_points' => 75];
        }

        $profiles = [
            ['workouts' => 7, 'points' => 210, 'streak' => 7, 'goal' => 7, 'challenge_points' => 120],
            ['workouts' => 6, 'points' => 180, 'streak' => 4, 'goal' => 5, 'challenge_points' => 100],
            ['workouts' => 5, 'points' => 135, 'streak' => 3, 'goal' => 4, 'challenge_points' => 90],
            ['workouts' => 4, 'points' => 110, 'streak' => 2, 'goal' => 4, 'challenge_points' => 65],
            ['workouts' => 3, 'points' => 85,  'streak' => 2, 'goal' => 3, 'challenge_points' => 50],
            ['workouts' => 1, 'points' => 45,  'streak' => 1, 'goal' => 3, 'challenge_points' => 25],
        ];

        return $profiles[$index % count($profiles)];
    }

    private function seedStudentWeek(User $student, array $profile): void
    {
        $today = Carbon::today();
        $weekStart = $today->copy()->startOfWeek(Carbon::MONDAY);

        for ($offset = $profile['workouts'] - 1; $offset >= 0; $offset--) {
            $day = $today->copy()->subDays($offset);
            $startedAt = $day->copy()->setTime(18, 10);
            $finishedAt = $day->copy()->setTime(19, 5);

            Checkin::updateOrCreate(
                ['user_id' => $student->id, 'checkin_date' => $day->toDateString()],
                ['gym_id' => $student->gym_id, 'checked_in_at' => $startedAt]
            );

            WorkoutSession::updateOrCreate(
                ['user_id' => $student->id, 'started_at' => $startedAt],
                [
                    'gym_id' => $student->gym_id,
                    'checkin_gym_id' => $student->gym_id,
                    'finished_at' => $finishedAt,
                    'progress' => 100,
                    'is_valid' => true,
                    'counts_for_points' => true,
                    'counts_for_streak' => true,
                    'points_granted' => true,
                    'points_granted_at' => $finishedAt,
                ]
            );
        }

        $student->update([
            'weekly_streak' => $profile['streak'],
            'current_streak' => $profile['streak'],
            'best_streak' => max((int) $student->best_streak, $profile['streak']),
            'current_week_start' => $weekStart,
            'current_week_goal' => $profile['goal'],
            'week_goal_completed' => $profile['streak'] >= $profile['goal'],
            'last_workout_date' => $today,
        ]);

        $transaction = PointTransaction::where('user_id', $student->id)
            ->where('category', 'demo')
            ->where('description', self::POINTS_DESCRIPTION)
            ->first();
        $previousPoints = (int) ($transaction?->points ?? 0);

        if ($transaction) {
            $transaction->update(['points' => $profile['points'], 'type' => 'earn', 'gym_id' => $student->gym_id]);
        } else {
            PointTransaction::create([
                'user_id' => $student->id,
                'gym_id' => $student->gym_id,
                'type' => 'earn',
                'category' => 'demo',
                'points' => $profile['points'],
                'description' => self::POINTS_DESCRIPTION,
            ]);
        }

        $student->increment('points_balance', $profile['points'] - $previousPoints);
    }

    private function upsertChallenge(int $gymId): GymChallenge
    {
        return GymChallenge::updateOrCreate(
            ['gym_id' => $gymId, 'name' => self::CHALLENGE_NAME],
            [
                'type' => 'competitive',
                'scope' => 'community',
                'description' => 'Ranking demo de consistencia: quem treinar mais vezes na semana sobe no podio.',
                'starts_at' => Carbon::today()->subDays(6),
                'ends_at' => Carbon::today()->addDays(7),
                'status' => 'active',
                'reward_type' => 'points',
                'reward_description' => 'Bonus de 120 pontos para o primeiro lugar',
                'min_weekly_workouts' => 1,
                'max_weekly_workouts' => 7,
                'weekly_points_config' => ['1' => 120, '2' => 100, '3' => 90, '4' => 65, '5' => 50, '6' => 25],
            ]
        );
    }

    private function seedChallengeProgress(GymChallenge $challenge, User $student, array $profile, int $position): void
    {
        ChallengeParticipant::updateOrCreate(
            ['challenge_id' => $challenge->id, 'user_id' => $student->id],
            [
                'gym_id' => $student->gym_id,
                'total_challenge_points' => $profile['challenge_points'],
                'workouts_this_challenge' => $profile['workouts'],
                'goal_completed' => false,
                'reward_granted' => false,
            ]
        );

        ChallengeWeeklyRanking::updateOrCreate(
            [
                'challenge_id' => $challenge->id,
                'user_id' => $student->id,
                'week_start' => Carbon::today()->startOfWeek(Carbon::MONDAY)->toDateString(),
            ],
            [
                'workouts_count' => $profile['workouts'],
                'position' => $position,
                'points_awarded' => 0,
                'finalized' => false,
            ]
        );
    }
}
