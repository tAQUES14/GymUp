<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('custom_workouts', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained()
                ->onDelete('cascade');

            $table->string('name');
            $table->text('description')->nullable();
            $table->string('level')->nullable();
            $table->integer('duration')->nullable();
            $table->boolean('is_generated')->default(false);

            // Aqui salvamos todos os exercícios como JSON
            $table->json('exercises');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('custom_workouts');
    }
};