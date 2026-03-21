<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedInteger('current_streak')->default(0)->after('weekly_streak');
            $table->unsignedInteger('best_streak')->default(0)->after('current_streak');
            $table->date('last_workout_date')->nullable()->after('best_streak');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['current_streak', 'best_streak', 'last_workout_date']);
        });
    }
};
