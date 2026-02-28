<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
   public function up()
{
    Schema::create('custom_workout_exercise', function (Blueprint $table) {
        $table->id();
        $table->foreignId('custom_workout_id')->constrained()->cascadeOnDelete();
        $table->foreignId('exercise_id')->constrained()->cascadeOnDelete();
        $table->integer('sets')->default(4);
        $table->integer('reps')->default(12);
        $table->integer('rest')->default(60);
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('custom_workout_exercise');
    }
};
