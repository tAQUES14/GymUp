<?php

use Database\Seeders\DemoWeekSeeder;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Re-seed com dados de ranking consistentes:
     * - 1 PointTransaction por sessão com created_at = data da sessão
     * - Ranking semanal / mensal / geral passam a mostrar valores distintos
     * - Check-ins totais proporcionais aos pontos (30 pts/sessão)
     * - Marcos Taques: 5 check-ins · 150 pts · 2/3 esta semana
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
