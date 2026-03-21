<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('custom_workouts', function (Blueprint $table) {
            // Marca treinos que são modelos da academia (não pertencem a um aluno específico)
            $table->boolean('is_template')->default(false)->after('is_generated');
            // Rastreia de qual modelo este treino foi copiado
            $table->unsignedBigInteger('template_id')->nullable()->after('is_template');
            $table->foreign('template_id')
                  ->references('id')
                  ->on('custom_workouts')
                  ->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('custom_workouts', function (Blueprint $table) {
            $table->dropForeign(['template_id']);
            $table->dropColumn(['is_template', 'template_id']);
        });
    }
};
