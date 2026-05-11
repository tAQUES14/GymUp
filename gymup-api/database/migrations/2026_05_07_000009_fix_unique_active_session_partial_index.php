<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * SQLite rebuilds the workout_sessions table when migrations use ->after() to
 * reorder columns (e.g. is_valid in 2026_03_18, checkin_gym_id in 2026_05_07_000005).
 * During rebuild, SQLite regenerates indexes from the schema definition, stripping
 * the WHERE clause from the raw-SQL partial index created in 2026_02_27.
 * This migration drops and recreates the index with the correct partial predicate.
 */
return new class extends Migration
{
    public function up(): void
    {
        $driver = Schema::getConnection()->getDriverName();

        if (in_array($driver, ['pgsql', 'sqlite'])) {
            DB::statement('DROP INDEX IF EXISTS unique_active_session');
            DB::statement('
                CREATE UNIQUE INDEX unique_active_session
                ON workout_sessions(user_id)
                WHERE finished_at IS NULL
            ');
        }
    }

    public function down(): void
    {
        // Nothing to do — the index already existed before this migration ran.
    }
};
