<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('exercise_weights', function (Blueprint $table) {
            // workout_id refers to custom_workouts.id (stored as unsignedBigInteger,
            // nullable for weights saved outside a specific workout context)
            $table->unsignedBigInteger('workout_id')->nullable()->after('exercise_id');

            // set_number: 1-based index of the set within the exercise
            $table->unsignedSmallInteger('set_number')->default(1)->after('workout_id');

            // Unique constraint: one weight record per user/workout/exercise/set
            // Allows upsert (updateOrCreate) without creating duplicates
            $table->unique(
                ['user_id', 'workout_id', 'exercise_id', 'set_number'],
                'ew_unique_user_workout_exercise_set'
            );
        });
    }

    public function down(): void
    {
        Schema::table('exercise_weights', function (Blueprint $table) {
            $table->dropUnique('ew_unique_user_workout_exercise_set');
            $table->dropColumn(['workout_id', 'set_number']);
        });
    }
};
