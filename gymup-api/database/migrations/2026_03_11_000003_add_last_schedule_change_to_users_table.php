<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Tracks when the training schedule was last changed by a trainer/admin.
            // StreakService only checks for missed training days AFTER this date,
            // so a schedule change never retroactively breaks a streak.
            $table->date('last_schedule_change')->nullable()->after('last_workout_date');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('last_schedule_change');
        });
    }
};
