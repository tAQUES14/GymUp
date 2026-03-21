<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Adds three semantic flags to workout_sessions:
 *
 *  is_valid          — whether the workout met the criteria (time + progress + check-in)
 *  counts_for_points — whether this session was the qualifying workout that earned points today
 *  counts_for_streak — whether this session was the qualifying workout that incremented the streak
 *
 * Before this migration, the only signal was points_granted, which conflated
 * "workout was valid" with "this specific session earned points". Now the model
 * can express "valid but not the first of the day" explicitly.
 *
 * Backfill: existing sessions that already have points_granted = true are
 * assumed to have been the qualifying session for that day.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('workout_sessions', function (Blueprint $table) {
            $table->boolean('is_valid')->default(false)->after('finished_at');
            $table->boolean('counts_for_points')->default(false)->after('is_valid');
            $table->boolean('counts_for_streak')->default(false)->after('counts_for_points');
        });

        // Backfill historical sessions: sessions that granted points were valid
        // and counted for both points and streak.
        DB::statement(
            'UPDATE workout_sessions
             SET    is_valid = true, counts_for_points = true, counts_for_streak = true
             WHERE  points_granted = true'
        );
    }

    public function down(): void
    {
        Schema::table('workout_sessions', function (Blueprint $table) {
            $table->dropColumn(['is_valid', 'counts_for_points', 'counts_for_streak']);
        });
    }
};
