<?php

namespace App\Services;

class WorkoutValidationService
{
    public const STATUS_VALID           = 'VALID';
    public const STATUS_PARTIAL_CONFIRM = 'PARTIAL_CONFIRM';
    public const STATUS_INVALID         = 'INVALID';

    /**
     * Minimum progress for a fully valid workout (75%).
     */
    public function minProgressValid(): int
    {
        return (int) config('workout.min_progress_valid', 75);
    }

    /**
     * Minimum progress to qualify for partial confirmation (70%).
     */
    public function minProgressPartial(): int
    {
        return (int) config('workout.min_progress_partial', 70);
    }

    /**
     * Minimum duration in minutes (10 min prod, 1 min test).
     */
    public function minMinutes(): int
    {
        return (int) config('workout.min_minutes', 10);
    }

    /**
     * Determines workout validation status.
     *
     * @param  int   $completionPercent  0-100
     * @param  int   $durationSeconds    Duration in seconds
     * @param  bool  $hasCheckinToday    Whether user checked in today
     * @param  bool  $confirmPartial     Whether user confirmed partial workout
     * @return array{status: string, message: string, points_multiplier: float}
     */
    public function validate(
        int  $completionPercent,
        int  $durationSeconds,
        bool $hasCheckinToday,
        bool $confirmPartial = false
    ): array {
        $durationMinutes = $durationSeconds / 60;

        // Duration below minimum → always invalid
        if ($durationMinutes < $this->minMinutes()) {
            return [
                'status'            => self::STATUS_INVALID,
                'message'           => 'Treino não validado. Você não atingiu o tempo mínimo de ' . $this->minMinutes() . ' minutos. Seus pontos não foram validados.',
                'points_multiplier' => 0,
            ];
        }

        // No check-in today → always invalid
        if (!$hasCheckinToday) {
            return [
                'status'            => self::STATUS_INVALID,
                'message'           => 'Você realizou o treino, mas não fez check-in hoje. Seus pontos não foram validados.',
                'points_multiplier' => 0,
            ];
        }

        // Completion below 70% → invalid
        if ($completionPercent < $this->minProgressPartial()) {
            return [
                'status'            => self::STATUS_INVALID,
                'message'           => 'Treino não validado. Complete pelo menos 70% e o tempo mínimo para validar.',
                'points_multiplier' => 0,
            ];
        }

        // Completion >= 75% → fully valid
        if ($completionPercent >= $this->minProgressValid()) {
            return [
                'status'            => self::STATUS_VALID,
                'message'           => 'Treino validado com sucesso!',
                'points_multiplier' => 1.0,
            ];
        }

        // Completion 70-74% → partial, needs confirmation
        if (!$confirmPartial) {
            return [
                'status'            => self::STATUS_PARTIAL_CONFIRM,
                'message'           => "Você completou {$completionPercent}% do treino. Deseja finalizar mesmo assim?",
                'points_multiplier' => 0,
            ];
        }

        // Confirmed partial → proportional points
        $multiplier = $completionPercent / 100;

        return [
            'status'            => self::STATUS_VALID,
            'message'           => "Treino parcial validado com {$completionPercent}% de conclusão.",
            'points_multiplier' => $multiplier,
        ];
    }
}
