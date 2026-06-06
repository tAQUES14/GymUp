<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('custom_workouts', function (Blueprint $table) {
            $table->foreignId('gym_id')
                ->nullable()
                ->after('user_id')
                ->constrained()
                ->nullOnDelete();
        });

        // Backfill from the owning user's gym_id
        DB::statement('
            UPDATE custom_workouts
            SET gym_id = (
                SELECT gym_id FROM users WHERE id = custom_workouts.user_id
            )
        ');
    }

    public function down(): void
    {
        Schema::table('custom_workouts', function (Blueprint $table) {
            $table->dropForeign(['gym_id']);
            $table->dropColumn('gym_id');
        });
    }
};
