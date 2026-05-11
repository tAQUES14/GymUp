<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adiciona consistency_bonus_days à tabela users.
 *
 * Este campo rastreia quantos dias consecutivos o usuário seguiu o plano
 * de treino (on_plan). É usado para calcular o multiplicador de bônus:
 *   0–2  dias →  0%
 *   3–6  dias →  5%
 *   7–13 dias →  8%
 *   14–29 dias → 12%
 *   30–39 dias → 18%
 *   40+  dias  → 20%
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedInteger('consistency_bonus_days')
                ->default(0)
                ->after('best_streak');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('consistency_bonus_days');
        });
    }
};
