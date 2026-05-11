<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trainer_gyms', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('trainer_id');
            $table->unsignedBigInteger('gym_id');
            $table->boolean('is_primary')->default(false);
            $table->timestamp('created_at')->nullable();

            $table->unique(['trainer_id', 'gym_id']);

            $table->foreign('trainer_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('gym_id')->references('id')->on('gyms')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trainer_gyms');
    }
};
