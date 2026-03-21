<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_exercises', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('plan_day_id');
            $table->unsignedBigInteger('exercise_id');
            $table->unsignedInteger('sets');
            $table->string('reps'); // can be "10-12", "30s", etc.
            $table->unsignedInteger('rest_seconds')->default(60);
            $table->unsignedInteger('exercise_order')->default(1);
            $table->timestamps();

            $table->foreign('plan_day_id')->references('id')->on('workout_plan_days')->onDelete('cascade');
            $table->foreign('exercise_id')->references('id')->on('exercises')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_exercises');
    }
};
