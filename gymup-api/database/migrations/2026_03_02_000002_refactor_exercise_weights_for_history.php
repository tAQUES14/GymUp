<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('exercise_weights', function (Blueprint $table) {
            // Remove UNIQUE constraint
            $table->dropUnique('ew_unique_user_workout_exercise_set');

            // Remove workout_id column
            $table->dropColumn('workout_id');

            // Remove note column (not part of new schema)
            $table->dropColumn('note');

            // Add indexes for query performance
            $table->index('user_id', 'ew_idx_user_id');
            $table->index('exercise_id', 'ew_idx_exercise_id');
            $table->index('set_number', 'ew_idx_set_number');
            $table->index('created_at', 'ew_idx_created_at');
        });
    }

    public function down(): void
    {
        Schema::table('exercise_weights', function (Blueprint $table) {
            $table->dropIndex('ew_idx_user_id');
            $table->dropIndex('ew_idx_exercise_id');
            $table->dropIndex('ew_idx_set_number');
            $table->dropIndex('ew_idx_created_at');

            $table->string('note')->nullable();
            $table->unsignedBigInteger('workout_id')->nullable()->after('exercise_id');

            $table->unique(
                ['user_id', 'workout_id', 'exercise_id', 'set_number'],
                'ew_unique_user_workout_exercise_set'
            );
        });
    }
};
