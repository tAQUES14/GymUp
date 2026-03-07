<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gym_challenges', function (Blueprint $table) {
            // 'points' | 'physical' | 'none'
            $table->string('reward_type', 20)->default('points')->after('status');
            $table->text('reward_description')->nullable()->after('reward_type');
        });
    }

    public function down(): void
    {
        Schema::table('gym_challenges', function (Blueprint $table) {
            $table->dropColumn(['reward_type', 'reward_description']);
        });
    }
};
