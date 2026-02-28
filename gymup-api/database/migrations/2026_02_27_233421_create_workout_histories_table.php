<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_histories', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained()
                ->onDelete('cascade');

            $table->string('workout_id');
            $table->string('workout_name');

            $table->integer('duration_minutes');
            $table->integer('sets_completed');
            $table->integer('sets_total');

            $table->integer('points_earned')->default(0);
            $table->boolean('had_checkin')->default(false);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_histories');
    }
};