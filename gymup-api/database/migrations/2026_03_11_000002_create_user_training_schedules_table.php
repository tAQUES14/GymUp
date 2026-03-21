<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_training_schedules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('gym_id')->constrained()->cascadeOnDelete();
            // 0 = Sunday, 1 = Monday, ..., 6 = Saturday (Carbon convention)
            $table->tinyInteger('day_of_week');
            $table->timestamps();

            $table->unique(['user_id', 'day_of_week']);
            $table->index(['gym_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_training_schedules');
    }
};
