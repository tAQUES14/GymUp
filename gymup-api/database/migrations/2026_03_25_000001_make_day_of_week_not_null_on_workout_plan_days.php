<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Torna day_of_week NOT NULL em workout_plan_days.
 *
 * Antes de aplicar NOT NULL, qualquer registro com day_of_week=null
 * é removido — esses dias são órfãos (nunca apareceriam no endpoint)
 * e não têm valor para o usuário.
 *
 * Se preferir preservá-los, altere a lógica de limpeza abaixo.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Remove dias órfãos (day_of_week = null) antes de aplicar NOT NULL.
        DB::table('workout_plan_days')->whereNull('day_of_week')->delete();

        Schema::table('workout_plan_days', function (Blueprint $table) {
            $table->tinyInteger('day_of_week')->unsigned()->nullable(false)->change();
        });
    }

    public function down(): void
    {
        Schema::table('workout_plan_days', function (Blueprint $table) {
            $table->tinyInteger('day_of_week')->unsigned()->nullable()->change();
        });
    }
};
