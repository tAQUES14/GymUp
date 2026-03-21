<?php

namespace App\Services;

use App\Models\CustomWorkout;
use App\Models\User;
use App\Models\UserWorkoutPlan;
use App\Models\WorkoutExercise;
use App\Models\WorkoutPlan;
use App\Models\WorkoutPlanDay;
use Illuminate\Support\Facades\DB;

class WorkoutPlanService
{
    public function __construct(private ExerciseOverrideService $overrideService)
    {
    }

    /**
     * Get the current plan state for a user.
     * Returns null if no plan is assigned.
     */
    public function getCurrentPlanForUser(User $user): ?array
    {
        $userPlan = UserWorkoutPlan::where('user_id', $user->id)->first();

        if (!$userPlan) {
            return null;
        }

        $plan = WorkoutPlan::with(['days' => function ($q) {
            $q->orderBy('day_order');
        }])->find($userPlan->plan_id);

        if (!$plan) {
            return null;
        }

        $totalDays = $plan->days->count();

        if ($totalDays === 0) {
            return null;
        }

        // Clamp current_day_index to valid range
        $dayIndex = max(1, min($userPlan->current_day_index, $totalDays));

        // days are ordered by day_order; use collection index (1-based)
        $currentDay = $plan->days->values()->get($dayIndex - 1);

        if (!$currentDay) {
            return null;
        }

        // Eager load exercises with their exercise model
        $currentDay->load(['exercises.exercise']);

        // Batch-load overrides for all exercises in this day (one query)
        $exerciseIds = $currentDay->exercises
            ->pluck('exercise_id')
            ->filter()
            ->values()
            ->all();

        $overrides = $this->overrideService->loadOverridesForUser($user->id, $exerciseIds);

        // Compact summary of every day — used by Flutter to render the
        // day-sequence strip without a second request.
        $allDays = $plan->days->values()->map(fn ($d, $i) => [
            'day_order' => $d->day_order,
            'name'      => $d->name,
            'rest_day'  => $d->rest_day,
        ])->values()->all();

        return [
            'plan_id'                        => $plan->id,
            'plan_name'                      => $plan->name,
            'current_day_index'              => $dayIndex,
            'total_days'                     => $totalDays,
            'between_exercise_rest_seconds'  => $plan->between_exercise_rest_seconds ?? 180,
            'current_day'                    => $this->formatDayForResponse($currentDay, $overrides),
            'all_days'                       => $allDays,
        ];
    }

    /**
     * Advance the user's plan to the next day after a valid workout is completed.
     * Wraps around to day 1 when end of plan is reached.
     */
    public function advancePlanAfterWorkout(User $user): void
    {
        $userPlan = UserWorkoutPlan::where('user_id', $user->id)->first();

        if (!$userPlan) {
            return;
        }

        $totalDays = WorkoutPlanDay::where('plan_id', $userPlan->plan_id)->count();

        if ($totalDays === 0) {
            return;
        }

        $nextIndex = $userPlan->current_day_index + 1;

        if ($nextIndex > $totalDays) {
            $nextIndex = 1;
        }

        $userPlan->current_day_index = $nextIndex;
        $userPlan->save();
    }

    /**
     * Format a WorkoutPlanDay with its exercises for the API response.
     * Accepts a pre-loaded overrides collection to avoid N+1.
     */
    public function formatDayForResponse(WorkoutPlanDay $day, $overrides = null): array
    {
        // Ensure exercises and their exercise relation are loaded
        if (!$day->relationLoaded('exercises')) {
            $day->load(['exercises.exercise']);
        }

        $overrides = $overrides ?? collect();

        $exercises = $day->exercises->map(function ($we) use ($overrides) {
            $ex       = $we->exercise;
            $override = $ex ? $overrides->get($ex->id) : null;

            if (!$ex) {
                return [
                    'id'               => $we->id,
                    'exercise_id'      => $we->exercise_id,
                    'name'             => '',
                    'muscle_group'     => '',
                    'image_url'        => null,
                    'video_url'        => null,
                    'description'      => null,
                    'execution_steps'  => [],
                    'common_mistakes'  => [],
                    'tips'             => [],
                    'primary_muscle'   => null,
                    'secondary_muscles'=> [],
                    'type'             => 'strength',
                    'sets'             => $we->sets,
                    'reps'             => $we->reps,
                    'rest_seconds'     => $we->rest_seconds,
                    'duration_minutes' => $we->duration_minutes,
                    'distance_km'      => $we->distance_km,
                    'technique'        => $we->technique ?? 'normal',
                    'group_id'         => $we->group_id,
                    'rounds'           => $we->rounds,
                    'drops'            => $we->drops,
                    'exercise_order'   => $we->exercise_order,
                    'default_rest'     => 60,
                    'has_override'     => false,
                ];
            }

            return array_merge(
                $this->overrideService->resolveForApi($ex, $override),
                [
                    'id'               => $we->id,
                    'exercise_id'      => $ex->id,   // required by WorkoutPlanExerciseModel
                    'sets'             => $we->sets,
                    'reps'             => $we->reps,
                    'rest_seconds'     => $we->rest_seconds,
                    'duration_minutes' => $we->duration_minutes,
                    'distance_km'      => $we->distance_km,
                    'technique'        => $we->technique ?? 'normal',
                    'group_id'         => $we->group_id,
                    'rounds'           => $we->rounds,
                    'drops'            => $we->drops,
                    'exercise_order'   => $we->exercise_order,
                ]
            );
        })->values()->all();

        return [
            'id'        => $day->id,
            'plan_id'   => $day->plan_id,
            'day_order' => $day->day_order,
            'name'      => $day->name,
            'rest_day'  => $day->rest_day,
            'exercises' => $exercises,
        ];
    }

    /**
     * Create a WorkoutPlanDay by copying exercises from a CustomWorkout template.
     * The resulting day is fully independent — future changes to the template have no effect.
     */
    public function addDayFromTemplate(WorkoutPlan $plan, int $workoutId): WorkoutPlanDay
    {
        $workout = CustomWorkout::with('exercises')
            ->where('is_template', true)
            ->findOrFail($workoutId);

        $maxOrder = WorkoutPlanDay::where('plan_id', $plan->id)->max('day_order') ?? 0;

        return DB::transaction(function () use ($plan, $workout, $maxOrder) {
            $day = WorkoutPlanDay::create([
                'plan_id'   => $plan->id,
                'day_order' => $maxOrder + 1,
                'name'      => $workout->name,
                'rest_day'  => false,
            ]);

            foreach ($workout->exercises as $index => $exercise) {
                WorkoutExercise::create([
                    'plan_day_id'    => $day->id,
                    'exercise_id'    => $exercise->id,
                    'sets'           => $exercise->pivot->sets,
                    'reps'           => (string) $exercise->pivot->reps,
                    'rest_seconds'   => $exercise->pivot->rest,
                    'exercise_order' => $index + 1,
                    'technique'      => 'normal',
                ]);
            }

            return $day;
        });
    }

    /**
     * Assign or reassign a plan to a user.
     * Resets to day 1.
     */
    public function assignPlanToUser(int $userId, int $planId, int $gymId): UserWorkoutPlan
    {
        $userPlan = UserWorkoutPlan::updateOrCreate(
            ['user_id' => $userId],
            [
                'plan_id'           => $planId,
                'gym_id'            => $gymId,
                'current_day_index' => 1,
                'started_at'        => now(),
            ]
        );

        return $userPlan;
    }
}
