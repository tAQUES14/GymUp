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
    Schema::create('checkins', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->foreignId('gym_id')->constrained()->onDelete('cascade');

        $table->date('checkin_date'); // 1 por dia
        $table->timestamp('checked_in_at')->useCurrent(); // horário real

        $table->timestamps();

        $table->unique(['user_id', 'checkin_date']);
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('checkins');
    }
};
