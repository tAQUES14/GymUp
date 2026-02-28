<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Índice composto para a subquery do ranking por período:
        // WHERE user_id = ? AND type = 'earn' AND created_at >= ?
        // Ordem das colunas: user_id (equality) → type (equality) → created_at (range)
        Schema::table('point_transactions', function (Blueprint $table) {
            $table->index(
                ['user_id', 'type', 'created_at'],
                'pt_ranking_period_idx'
            );
        });

        // Índice composto para o filtro de usuários no ranking:
        // WHERE gym_id = ? AND role = 'student'
        Schema::table('users', function (Blueprint $table) {
            $table->index(['gym_id', 'role'], 'users_gym_role_idx');
        });
    }

    public function down(): void
    {
        Schema::table('point_transactions', function (Blueprint $table) {
            $table->dropIndex('pt_ranking_period_idx');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex('users_gym_role_idx');
        });
    }
};
