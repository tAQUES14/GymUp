<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('workout_sessions', function (Blueprint $table) {
            $table->unsignedBigInteger('checkin_gym_id')->nullable()->after('gym_id');
            $table->foreign('checkin_gym_id')->references('id')->on('gyms')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('workout_sessions', function (Blueprint $table) {
            $table->dropForeign(['checkin_gym_id']);
            $table->dropColumn('checkin_gym_id');
        });
    }
};
