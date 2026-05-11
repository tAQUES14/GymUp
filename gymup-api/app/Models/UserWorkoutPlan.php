<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class UserWorkoutPlan extends Model
{
    protected $fillable = ['user_id', 'plan_id', 'gym_id', 'started_at', 'effective_from'];

    protected $casts = [
        'started_at'     => 'datetime',
        'effective_from' => 'date',
    ];

    /**
     * Scope que retorna apenas planos que já entraram em vigor.
     * effective_from NULL = ativo imediatamente (compatibilidade com registros antigos).
     */
    public function scopeActive(Builder $query): Builder
    {
        return $query->where(function (Builder $q) {
            $q->whereNull('effective_from')
              ->orWhereDate('effective_from', '<=', now()->toDateString());
        });
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function plan()
    {
        return $this->belongsTo(WorkoutPlan::class, 'plan_id');
    }
}
