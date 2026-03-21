<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Feedback log: one row per admin manual GIF selection.
 * Used to accumulate ground-truth data for future match weight improvements.
 */
class GifFeedback extends Model
{
    // No updated_at column — append-only log table
    const UPDATED_AT = null;

    protected $table = 'gif_feedback';

    protected $fillable = [
        'exercise_id',
        'exercise_name_normalized',
        'selected_gif',
    ];
}
