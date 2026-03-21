<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('workout_exercises', function (Blueprint $table) {
            // Make strength-specific fields optional so cardio rows can have null
            $table->unsignedInteger('sets')->nullable()->change();
            $table->string('reps')->nullable()->change();

            // New cardio-specific fields
            $table->unsignedInteger('duration_minutes')->nullable()->after('rest_seconds');
            $table->decimal('distance_km', 5, 2)->nullable()->after('duration_minutes');
        });
    }

    public function down(): void
    {
        Schema::table('workout_exercises', function (Blueprint $table) {
            $table->dropColumn(['duration_minutes', 'distance_km']);
            $table->unsignedInteger('sets')->nullable(false)->change();
            $table->string('reps')->nullable(false)->change();
        });
    }
};
