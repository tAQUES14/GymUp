<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserGoal;

class GoalService
{
    private const ACTIVITY_MULTIPLIERS = [
        'sedentary' => 1.2,
        'light'     => 1.375,
        'moderate'  => 1.55,
        'intense'   => 1.725,
    ];

    private const WORKOUTS_PER_WEEK = [
        'sedentary' => 2,
        'light'     => 3,
        'moderate'  => 4,
        'intense'   => 5,
    ];

    private const KCAL_PER_KG = 7700;

    /**
     * Calculate estimates without persisting — used for the preview endpoint.
     *
     * @return array  Same shape as formatGoal(), but without created_at / id.
     */
    public function previewGoal(array $data): array
    {
        $deficit = null;
        if ($data['goal_type'] !== 'consistency') {
            $deficit = $this->calculateDailyDeficit(
                (float) $data['start_weight'],
                (float) $data['target_weight'],
                (int)   $data['target_months']
            );
        }

        return [
            'goal_type'                       => $data['goal_type'],
            'gender'                          => $data['gender'],
            'start_weight'                    => (float) $data['start_weight'],
            'target_weight'                   => (float) $data['target_weight'],
            'height'                          => (float) $data['height'],
            'age'                             => (int) $data['age'],
            'activity_level'                  => $data['activity_level'],
            'target_months'                   => (int) $data['target_months'],
            'estimated_daily_calorie_deficit' => $deficit,
            'estimated_workouts_per_week'     => self::WORKOUTS_PER_WEEK[$data['activity_level']],
            'created_at'                      => now()->toIso8601String(),
        ];
    }

    /**
     * Create (or replace) the user's active goal.
     * Rule: each user can have only ONE active goal at a time.
     */
    public function createGoal(User $user, array $data): UserGoal
    {
        // Enforce single active goal: delete previous before creating new one.
        UserGoal::where('user_id', $user->id)->delete();

        $deficit = null;
        if ($data['goal_type'] !== 'consistency') {
            $deficit = $this->calculateDailyDeficit(
                (float) $data['start_weight'],
                (float) $data['target_weight'],
                (int)   $data['target_months']
            );
        }

        return UserGoal::create([
            'user_id'                         => $user->id,
            'goal_type'                       => $data['goal_type'],
            'gender'                          => $data['gender'],
            'start_weight'                    => $data['start_weight'],
            'target_weight'                   => $data['target_weight'],
            'height'                          => $data['height'],
            'age'                             => $data['age'],
            'activity_level'                  => $data['activity_level'],
            'target_months'                   => $data['target_months'],
            'estimated_daily_calorie_deficit' => $deficit,
            'estimated_workouts_per_week'     => self::WORKOUTS_PER_WEEK[$data['activity_level']],
        ]);
    }

    /**
     * Mifflin-St Jeor BMR formula.
     *
     * Male:   BMR = (10 × weight) + (6.25 × height) − (5 × age) + 5
     * Female: BMR = (10 × weight) + (6.25 × height) − (5 × age) − 161
     *
     * @param  float  $weight  kg
     * @param  float  $height  cm
     * @param  int    $age     years
     * @param  string $gender  male|female
     */
    public function calculateBMR(float $weight, float $height, int $age, string $gender): float
    {
        $base = (10 * $weight) + (6.25 * $height) - (5 * $age);

        return $gender === 'male' ? $base + 5 : $base - 161;
    }

    /**
     * Total Daily Energy Expenditure = BMR × activity multiplier.
     *
     * @param  string $activityLevel  sedentary|light|moderate|intense
     */
    public function calculateTDEE(float $bmr, string $activityLevel): float
    {
        return $bmr * self::ACTIVITY_MULTIPLIERS[$activityLevel];
    }

    /**
     * Estimated daily calorie deficit/surplus needed to hit the target weight.
     *
     * Formula: |Δweight| × 7700 kcal/kg / total_days
     * Used for both weight_loss (deficit) and weight_gain (surplus).
     *
     * @param  float $startWeight   kg
     * @param  float $targetWeight  kg
     * @param  int   $targetMonths
     * @return int   kcal/day (always positive)
     */
    public function calculateDailyDeficit(float $startWeight, float $targetWeight, int $targetMonths): int
    {
        $weightDelta = abs($startWeight - $targetWeight);
        $totalDays   = $targetMonths * 30;

        if ($totalDays === 0) {
            return 0;
        }

        return (int) round(($weightDelta * self::KCAL_PER_KG) / $totalDays);
    }
}
