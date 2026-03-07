<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('challenge_weekly_rankings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('challenge_id')->constrained('gym_challenges')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('week_start'); // Segunda-feira da semana

            // Quantidade de treinos válidos contabilizados (limitado ao max_weekly_workouts)
            $table->unsignedSmallInteger('workouts_count')->default(0);

            // Preenchido na finalização da semana
            $table->unsignedSmallInteger('position')->nullable();
            $table->integer('points_awarded')->default(0);
            $table->boolean('finalized')->default(false);

            $table->timestamps();

            $table->unique(['challenge_id', 'user_id', 'week_start']);
            $table->index(['challenge_id', 'week_start', 'finalized']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('challenge_weekly_rankings');
    }
};
