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
    Schema::create('point_transactions', function (Blueprint $table) {
        $table->id();

        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->foreignId('gym_id')->constrained()->onDelete('cascade');

        $table->enum('type', ['earn', 'spend']); // ganhou ou gastou
        $table->integer('points'); // valor positivo
        $table->string('description')->nullable(); // motivo (check-in, resgate, bônus etc)

        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('point_transactions');
    }
};
