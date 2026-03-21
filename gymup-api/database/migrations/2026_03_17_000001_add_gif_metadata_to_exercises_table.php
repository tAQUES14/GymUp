<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->unsignedTinyInteger('gif_confidence')->nullable()->after('gif_file');
            $table->boolean('gif_is_auto')->nullable()->after('gif_confidence');
        });
    }

    public function down(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->dropColumn(['gif_confidence', 'gif_is_auto']);
        });
    }
};
