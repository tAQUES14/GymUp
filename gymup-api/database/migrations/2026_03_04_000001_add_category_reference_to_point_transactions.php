<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('point_transactions', function (Blueprint $table) {
            $table->string('category', 30)->default('workout')->after('type');
            $table->unsignedBigInteger('reference_id')->nullable()->after('description');
            $table->index('category');
        });
    }

    public function down(): void
    {
        Schema::table('point_transactions', function (Blueprint $table) {
            $table->dropIndex(['category']);
            $table->dropColumn(['category', 'reference_id']);
        });
    }
};
