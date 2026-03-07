<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('challenge_participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('challenge_id')->constrained('gym_challenges')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('gym_id')->constrained()->cascadeOnDelete();

            // Competitivo: pontos acumulados ao longo das semanas
            $table->integer('total_challenge_points')->default(0);

            // Simples: progresso individual
            $table->unsignedSmallInteger('workouts_this_challenge')->default(0);
            $table->boolean('goal_completed')->default(false);
            $table->timestamp('goal_completed_at')->nullable();
            $table->boolean('reward_granted')->default(false);

            $table->timestamps();

            $table->unique(['challenge_id', 'user_id']);
            $table->index(['challenge_id', 'total_challenge_points']);
            $table->index(['challenge_id', 'goal_completed']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('challenge_participants');
    }
};
