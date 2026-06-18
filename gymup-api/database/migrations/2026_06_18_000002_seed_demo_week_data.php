<?php

use Database\Seeders\DemoWeekSeeder;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    /**
     * Popula uma semana demonstrativa no primeiro deploy desta versao.
     * O seeder permanece disponivel para reaplicacao manual no Render.
     */
    public function up(): void
    {
        if (app()->environment('testing')) {
            return;
        }

        app(DemoWeekSeeder::class)->run();
    }

    /**
     * Os registros podem ser usados em gravacoes e nao devem ser removidos
     * automaticamente por um rollback de codigo.
     */
    public function down(): void
    {
        // Intencionalmente vazio.
    }
};
