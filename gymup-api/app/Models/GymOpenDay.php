<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Dia de funcionamento de uma academia.
 *
 * Se não existir nenhum registro para uma academia,
 * o sistema assume que ela está aberta todos os dias.
 */
class GymOpenDay extends Model
{
    protected $fillable = ['gym_id', 'day_of_week', 'is_open'];

    protected $casts = [
        'is_open'     => 'boolean',
        'day_of_week' => 'integer',
    ];

    public function gym()
    {
        return $this->belongsTo(Gym::class);
    }
}
