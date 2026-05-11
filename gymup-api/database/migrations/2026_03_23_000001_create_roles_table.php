<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            // null = role global (super_admin, gym_admin padrão)
            // preenchido = role pertence a uma academia específica
            $table->foreignId('gym_id')->nullable()->constrained('gyms')->onDelete('cascade');
            $table->timestamps();

            $table->unique(['name', 'gym_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('roles');
    }
};
