<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Adiciona effective_from a user_workout_plans.
 *
 * Permite que a troca de plano seja agendada para a próxima semana
 * sem alterar o histórico do usuário.
 *
 * Regras de negócio:
 *   - Usuário sem plano ativo → effective_from = hoje (começa imediatamente)
 *   - Usuário que troca de plano → effective_from = próxima segunda-feira
 *   - Plan só é "ativo" quando effective_from <= CURDATE()
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_workout_plans', function (Blueprint $table) {
            $table->date('effective_from')->nullable()->after('started_at');
        });

        // Dados existentes: marcar como já ativos (started_at ou hoje)
        DB::statement("
            UPDATE user_workout_plans
            SET effective_from = COALESCE(DATE(started_at), CURRENT_DATE)
            WHERE effective_from IS NULL
        ");
    }

    public function down(): void
    {
        Schema::table('user_workout_plans', function (Blueprint $table) {
            $table->dropColumn('effective_from');
        });
    }
};
