<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('workout_exercises', function (Blueprint $table) {
            // normal | superset | dropset | circuit
            $table->string('technique', 20)->default('normal')->after('exercise_order');
            // Groups exercises belonging to the same superset or circuit
            $table->unsignedInteger('group_id')->nullable()->after('technique');
            // Number of rounds — used for circuit
            $table->unsignedInteger('rounds')->nullable()->after('group_id');
            // Number of weight drops — used for dropset
            $table->unsignedInteger('drops')->nullable()->after('rounds');
        });
    }

    public function down(): void
    {
        Schema::table('workout_exercises', function (Blueprint $table) {
            $table->dropColumn(['technique', 'group_id', 'rounds', 'drops']);
        });
    }
};
