<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('goal_type', 20);      // weight_loss | weight_gain | consistency
            $table->string('gender', 10);          // male | female
            $table->decimal('start_weight', 6, 2);
            $table->decimal('target_weight', 6, 2);
            $table->decimal('height', 6, 2);       // cm
            $table->unsignedSmallInteger('age');
            $table->string('activity_level', 20);  // sedentary | light | moderate | intense
            $table->unsignedSmallInteger('target_months');
            $table->integer('estimated_daily_calorie_deficit')->nullable();
            $table->unsignedSmallInteger('estimated_workouts_per_week');
            $table->timestamps();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_goals');
    }
};
