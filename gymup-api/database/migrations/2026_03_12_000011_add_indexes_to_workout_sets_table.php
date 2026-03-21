<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('workout_sets', function (Blueprint $table) {
            // Speeds up getLastSets / history lookups by exercise
            $table->index('exercise_id');
            // Speeds up time-range queries on workout history
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::table('workout_sets', function (Blueprint $table) {
            $table->dropIndex(['exercise_id']);
            $table->dropIndex(['created_at']);
        });
    }
};
