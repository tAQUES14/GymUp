<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->unsignedBigInteger('gym_id')->nullable()->after('id');
            $table->unsignedBigInteger('created_by')->nullable()->after('gym_id');
            $table->text('description')->nullable()->after('default_rest');
            $table->string('video_url')->nullable()->after('description');

            $table->foreign('gym_id')->references('id')->on('gyms')->onDelete('set null');
            $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->dropForeign(['gym_id']);
            $table->dropForeign(['created_by']);
            $table->dropColumn(['gym_id', 'created_by', 'description', 'video_url']);
        });
    }
};
