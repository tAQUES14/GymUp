<?php

namespace App\Services;

class WorkoutValidationService
{
    public const STATUS_VALID           = 'VALID';
    public const STATUS_PARTIAL_CONFIRM = 'PARTIAL_CONFIRM';
    public const STATUS_INVALID         = 'INVALID';

    public function minProgressValid(): int
    {
        return (int) config('workout.min_progress_valid', 75);
    }

    public function minProgressPartial(): int
    {
        return (int) config('workout.min_progress_partial', 70);
    }

    public function minMinutes(): int
    {
        return (int) config('workout.min_minutes', 10);
    }

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
