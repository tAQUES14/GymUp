<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $driver = Schema::getConnection()->getDriverName();

        // Partial unique indexes: only PostgreSQL and SQLite (3.8+) support WHERE clauses.
        // MySQL does not support partial indexes — skip on MySQL.
        if ($driver === 'pgsql') {
            DB::statement('
                CREATE UNIQUE INDEX unique_active_session
                ON workout_sessions(user_id)
                WHERE finished_at IS NULL
            ');
        } elseif ($driver === 'sqlite') {
            DB::statement('
                CREATE UNIQUE INDEX unique_active_session
                ON workout_sessions(user_id)
                WHERE finished_at IS NULL
            ');
        }
    }

    public function down(): void
    {
        $driver = Schema::getConnection()->getDriverName();

        if (in_array($driver, ['pgsql', 'sqlite'])) {
            DB::statement('DROP INDEX IF EXISTS unique_active_session');
        }
    }
};
