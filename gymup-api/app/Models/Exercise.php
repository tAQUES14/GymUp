<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Exercise extends Model
{
    private const FALLBACK_PUBLIC_GIF_BASE_URL = 'https://s3.us-west-004.backblazeb2.com/gymup-storage';

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
        return self::gifPathToUrl($this->gif_file);
    }

    /**
     * Convert a relative gif_file path (e.g. "BÍCEPS e ANTEBRAÇO/Rosca direta.gif")
     * to a fully-qualified, RFC-3986-safe URL.
     *
     * Percent-encodes every path segment so accented folder/file names and spaces
     * produce a valid URI. Dart's Uri.parse() (used by Image.network) throws a
     * FormatException on bare spaces / non-ASCII chars, silently showing the fallback
     * icon.  rawurlencode encodes spaces as %20 (RFC 3986-safe).
     *
     * Used by getGifUrlAttribute(), AdminExerciseController::availableGifs(), and
     * GifSuggestionService so all three always produce identical URLs.
     */
    public static function gifPathToUrl(?string $relative): ?string
    {
        if (!$relative) {
            return null;
        }

        $encoded = implode('/', array_map('rawurlencode', explode('/', $relative)));
        $publicDisk = config('filesystems.disks.public', []);
        $publicUrl = env('PUBLIC_DISK_URL');

        if (!$publicUrl && ($publicDisk['driver'] ?? null) === 's3') {
            $endpoint = $publicDisk['endpoint'] ?? null;
            $bucket = $publicDisk['bucket'] ?? null;

            if ($endpoint && $bucket) {
                $publicUrl = rtrim($endpoint, '/') . '/' . $bucket;
            }
        }

        $publicUrl ??= $publicDisk['url'] ?? null;

        if (!$publicUrl || str_contains($publicUrl, 'gymup-api.onrender.com/storage')) {
            $publicUrl = self::FALLBACK_PUBLIC_GIF_BASE_URL;
        }

        if ($publicUrl) {
            return rtrim($publicUrl, '/') . '/exercises/' . $encoded;
        }

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
