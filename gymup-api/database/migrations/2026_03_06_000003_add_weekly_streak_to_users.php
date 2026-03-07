<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Semanas consecutivas em que o usuário atingiu a meta semanal
            $table->unsignedInteger('weekly_streak')->default(0)->after('points_balance');

            // Flag: a meta semanal já foi atingida na semana corrente?
            $table->boolean('week_goal_completed')->default(false)->after('weekly_streak');

            // Segunda-feira da semana que está sendo rastreada
            $table->date('current_week_start')->nullable()->after('week_goal_completed');

            // Snapshot da meta semanal no início da semana (protege contra
            // recálculo retroativo quando o usuário muda a meta)
            $table->unsignedSmallInteger('current_week_goal')->nullable()->after('current_week_start');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'weekly_streak',
                'week_goal_completed',
                'current_week_start',
                'current_week_goal',
            ]);
        });
    }
};
