<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Exercise extends Model
{
    protected $fillable = [
        'name',
        'type',
        'muscle_group',
        'image_url',
        'gif_file',
        'gif_confidence',
        'gif_is_auto',
        'default_rest',
        'gym_id',
        'created_by',
        'description',
        'primary_muscle',
        'secondary_muscles',
        'execution_steps',
        'common_mistakes',
        'tips',
    ];

    protected $appends = ['gif_url'];

    // video_url and image_url kept in DB for backward-compat but never exposed in API responses
    // gif_file is hidden — clients use gif_url instead; gif_confidence and gif_is_auto are exposed
    protected $hidden = ['video_url', 'image_url', 'gif_file'];

    protected $casts = [
        'secondary_muscles' => 'array',
        'execution_steps'   => 'array',
        'common_mistakes'   => 'array',
        'tips'              => 'array',
    ];

    public function getGifUrlAttribute(): ?string
    {
        if (!$this->gif_file) {
            return null;
        }

        // Percent-encode every path segment so accented folder/file names and
        // spaces produce a valid URI. Dart's Uri.parse() (used by Image.network)
        // throws FormatException on bare spaces / non-ASCII, silently showing the
        // fallback icon.  rawurlencode encodes spaces as %20 (RFC 3986-safe).
        $encoded = implode('/', array_map('rawurlencode', explode('/', $this->gif_file)));

        return url('storage/exercises/' . $encoded);
    }

    public function workouts()
    {
        return $this->belongsToMany(CustomWorkout::class)
            ->withPivot(['sets', 'reps', 'rest'])
            ->withTimestamps();
    }

    public function substitutions(): HasMany
    {
        return $this->hasMany(ExerciseSubstitution::class, 'exercise_id')->orderBy('priority');
    }

    public function userOverrides(): HasMany
    {
        return $this->hasMany(UserExerciseOverride::class);
    }
}