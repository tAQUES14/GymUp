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
    Schema::create('redemptions', function (Blueprint $table) {
        $table->id();

        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->foreignId('reward_id')->constrained()->onDelete('cascade');
        $table->foreignId('gym_id')->constrained()->onDelete('cascade');

        $table->integer('points_spent');

        $table->enum('status', ['pending', 'approved', 'rejected'])
              ->default('pending');

        $table->timestamp('approved_at')->nullable();

        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('redemptions');
    }
};
