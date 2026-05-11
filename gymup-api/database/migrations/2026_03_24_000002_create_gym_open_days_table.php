<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabela de dias de funcionamento da academia.
 *
 * Regras:
 *   - Se a academia não tem nenhum registro → considerada aberta todos os dias.
 *   - Se tem registros, apenas os dias com is_open = true são considerados abertos.
 *   - O streak NÃO quebra em dias em que a academia está fechada.
 *   - Um plano pode ter treino num dia fechado, mas ele é ignorado para streak.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('gym_open_days', function (Blueprint $table) {
            $table->id();
            $table->foreignId('gym_id')->constrained()->cascadeOnDelete();
            $table->tinyInteger('day_of_week')->unsigned()
                ->comment('0=Domingo, 1=Segunda, ..., 6=Sábado');
            $table->boolean('is_open')->default(true);
            $table->timestamps();

            $table->unique(['gym_id', 'day_of_week']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('gym_open_days');
    }
};
