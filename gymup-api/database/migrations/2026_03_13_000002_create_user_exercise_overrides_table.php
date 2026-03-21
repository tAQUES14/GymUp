<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_exercise_overrides', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('exercise_id');
            $table->unsignedBigInteger('user_id');
            $table->string('custom_video_url')->nullable();
            $table->text('custom_description')->nullable();
            $table->json('custom_execution_steps')->nullable();
            $table->json('custom_tips')->nullable();
            $table->timestamps();

            $table->foreign('exercise_id')->references('id')->on('exercises')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->unique(['exercise_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_exercise_overrides');
    }
};
