<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_sets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('workout_session_id')->constrained('workout_sessions')->cascadeOnDelete();
            $table->foreignId('exercise_id')->constrained('exercises')->cascadeOnDelete();
            $table->unsignedSmallInteger('set_number');
            $table->decimal('weight', 6, 2)->default(0);
            $table->unsignedSmallInteger('reps')->default(0);
            $table->timestamp('created_at')->useCurrent();

            $table->index(['workout_session_id', 'exercise_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_sets');
    }
};
