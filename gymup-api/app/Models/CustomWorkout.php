<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomWorkout extends Model
{
    protected $fillable = [
        'user_id',
        'name',
        'description',
        'level',
        'duration',
        'is_generated',
        'is_template',
        'template_id',
    ];

    protected $casts = [
        'is_generated' => 'boolean',
        'is_template'  => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function exercises()
    {
        return $this->belongsToMany(Exercise::class)
            ->withPivot(['sets', 'reps', 'rest'])
            ->withTimestamps();
    }

    /** Cópias atribuídas a alunos (is_template = false, template_id = this->id) */
    public function copies()
    {
        return $this->hasMany(CustomWorkout::class, 'template_id');
    }
}