<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_workout_plans', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('plan_id');
            $table->unsignedBigInteger('gym_id');
            $table->unsignedInteger('current_day_index')->default(1);
            $table->timestamp('started_at')->nullable();
            $table->timestamps();

            $table->unique('user_id'); // one active plan per user

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('plan_id')->references('id')->on('workout_plans')->onDelete('cascade');
            $table->foreign('gym_id')->references('id')->on('gyms')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_workout_plans');
    }
};
