<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Migra workout_plan_days de lógica sequencial para calendário.
 *
 * Antes: day_order (1, 2, 3...) — posição na sequência
 * Depois: day_of_week (0=Dom, 1=Seg, ..., 6=Sáb) — dia real da semana
 *
 * Migração de dados existentes: day_order → (day_order - 1) % 7.
 * Isso é uma aproximação razoável; o admin deverá revisar e corrigir
 * os planos existentes via painel.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('workout_plan_days', function (Blueprint $table) {
            // Adiciona o novo campo ao lado de plan_id
            $table->tinyInteger('day_of_week')->unsigned()->nullable()
                ->after('plan_id')
                ->comment('0=Domingo, 1=Segunda, ..., 6=Sábado');
        });

        // Migra dados existentes: mapeia day_order para day_of_week.
        // day_order começa em 1, então (day_order - 1) % 7 dá 0–6.
        DB::statement('UPDATE workout_plan_days SET day_of_week = (day_order - 1) % 7');

        Schema::table('workout_plan_days', function (Blueprint $table) {
            // Remove a coluna sequencial
            $table->dropColumn('day_order');

            // Índice para lookup rápido por plano + dia
            $table->unique(['plan_id', 'day_of_week'], 'udx_plan_day_of_week');
        });
    }

    public function down(): void
    {
        Schema::table('workout_plan_days', function (Blueprint $table) {
            $table->dropUnique('udx_plan_day_of_week');
            $table->dropColumn('day_of_week');
            $table->unsignedInteger('day_order')->default(1)->after('plan_id');
        });
    }
};
