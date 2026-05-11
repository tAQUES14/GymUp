<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gym_challenges', function (Blueprint $table) {
            // 'community' = coletivo da academia (1 ativo por vez)
            // 'personal'  = conquista individual (vários ativos simultâneos)
            $table->string('scope', 20)->default('community')->after('type');
            $table->index(['gym_id', 'scope', 'status']);
        });
    }

    public function down(): void
    {
        Schema::table('gym_challenges', function (Blueprint $table) {
            $table->dropIndex(['gym_id', 'scope', 'status']);
            $table->dropColumn('scope');
        });
    }
};
