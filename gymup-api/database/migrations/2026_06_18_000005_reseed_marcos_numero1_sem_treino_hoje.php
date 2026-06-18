<?php

use Database\Seeders\DemoWeekSeeder;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Re-seed com:
     * - Marcos sem sessão/checkin hoje (demo de QR code funciona)
     * - Marcos #1 no ranking geral (12 sessões históricas + conquistas)
     * - Conquistas coerentes com sessões e streak de cada aluno
     * - Rankings semanal / mensal / geral com valores distintos
     */
    public function up(): void
    {
        if (app()->environment('testing')) {
            return;
        }

        app(DemoWeekSeeder::class)->run();
    }

    public function down(): void {}
};
