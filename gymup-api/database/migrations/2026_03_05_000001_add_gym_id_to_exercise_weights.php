<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('exercise_weights', function (Blueprint $table) {
            $table->unsignedBigInteger('gym_id')->nullable()->after('user_id');
            $table->index('gym_id', 'ew_idx_gym_id');
        });
    }

    public function down(): void
    {
        Schema::table('exercise_weights', function (Blueprint $table) {
            $table->dropIndex('ew_idx_gym_id');
            $table->dropColumn('gym_id');
        });
    }
};
