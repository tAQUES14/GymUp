<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gyms', function (Blueprint $table) {
            $table->unsignedBigInteger('chain_id')->nullable()->after('id');
            $table->foreign('chain_id')->references('id')->on('gym_chains')->nullOnDelete();
            $table->index('chain_id');
        });
    }

    public function down(): void
    {
        Schema::table('gyms', function (Blueprint $table) {
            $table->dropForeign(['chain_id']);
            $table->dropIndex(['chain_id']);
            $table->dropColumn('chain_id');
        });
    }
};
