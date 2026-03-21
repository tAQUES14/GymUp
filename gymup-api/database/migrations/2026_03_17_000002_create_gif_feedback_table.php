<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Lightweight feedback log: records which GIF an admin manually selected for
 * each exercise. No ML required — used later to weight fuzzy matching.
 */
return new class extends Migration {
    public function up(): void
    {
        Schema::create('gif_feedback', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('exercise_id');
            $table->string('exercise_name_normalized', 255);
            $table->string('selected_gif', 500);
            $table->timestamp('created_at')->useCurrent();

            $table->index('exercise_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gif_feedback');
    }
};
