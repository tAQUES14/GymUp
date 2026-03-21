<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->foreignId('gym_id')->nullable()->constrained()->onDelete('cascade');
        $table->string('role', 20)->default('user');
        $table->integer('points_balance')->default(0);
        $table->decimal('height', 5, 2)->nullable();
        $table->decimal('weight', 5, 2)->nullable();
        $table->date('birth_date')->nullable();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropForeign(['gym_id']);
        $table->dropColumn([
            'gym_id',
            'role',
            'points_balance',
            'height',
            'weight',
            'birth_date'
        ]);
    });
}
};
