<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->string('primary_muscle')->nullable()->after('muscle_group');
            $table->json('secondary_muscles')->nullable()->after('primary_muscle');
            $table->json('execution_steps')->nullable()->after('description');
            $table->json('common_mistakes')->nullable()->after('execution_steps');
            $table->json('tips')->nullable()->after('common_mistakes');
        });
    }

    public function down(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->dropColumn([
                'primary_muscle',
                'secondary_muscles',
                'execution_steps',
                'common_mistakes',
                'tips',
            ]);
        });
    }
};
