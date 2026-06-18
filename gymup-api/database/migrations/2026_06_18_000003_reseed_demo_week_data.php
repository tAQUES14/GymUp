<?php

use Database\Seeders\DemoWeekSeeder;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Re-popula os dados demo com perfis corrigidos:
     * - Limpa dados antigos antes de seedar (sessoes, checkins, pontos)
     * - Máximo 4 treinos na semana atual (Dom–Qua disponíveis)
     * - Semana anterior para usuários com mais checkins/streak
     * - Barras da semana no app não mostram dias futuros como treinados
     */
    public function up(): void
    {
        if (app()->environment('testing')) {
            return;
        }

        app(DemoWeekSeeder::class)->run();
    }

    public function down(): void
    {
        // Intencionalmente vazio.
    }
};
