<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Remove current_day_index de user_workout_plans.
 *
 * Na lógica baseada em calendário, o "dia atual" é sempre determinado
 * pelo day_of_week do plano comparado com a data atual. Não há mais
 * necessidade de rastrear uma posição sequencial.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_workout_plans', function (Blueprint $table) {
            $table->dropColumn('current_day_index');
        });
    }

    public function down(): void
    {
        Schema::table('user_workout_plans', function (Blueprint $table) {
            $table->unsignedInteger('current_day_index')->default(1)->after('plan_id');
        });
    }
};
