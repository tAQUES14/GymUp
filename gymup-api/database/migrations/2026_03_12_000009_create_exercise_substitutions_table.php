<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('exercise_substitutions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('exercise_id')->constrained('exercises')->cascadeOnDelete();
            $table->foreignId('substitute_exercise_id')->constrained('exercises')->cascadeOnDelete();
            $table->unsignedSmallInteger('priority')->default(0);
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['exercise_id', 'substitute_exercise_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('exercise_substitutions');
    }
};
