<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('gym_challenges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('gym_id')->constrained()->cascadeOnDelete();
            $table->string('type', 20);       // competitive | simple
            $table->string('name');
            $table->text('description')->nullable();
            $table->date('starts_at');
            $table->date('ends_at');
            $table->string('status', 20)->default('active'); // active | finished

            // Competitivo
            $table->unsignedTinyInteger('min_weekly_workouts')->nullable();
            $table->unsignedTinyInteger('max_weekly_workouts')->nullable();
            $table->json('weekly_points_config')->nullable(); // {"1": 100, "2": 80, ...}

            // Simples
            $table->unsignedSmallInteger('goal_workouts')->nullable();
            $table->integer('reward_points')->nullable();

            $table->timestamps();

            $table->index(['gym_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gym_challenges');
    }
};
