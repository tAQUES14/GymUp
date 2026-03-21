<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_plan_days', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('plan_id');
            $table->unsignedInteger('day_order');
            $table->string('name');
            $table->boolean('rest_day')->default(false);
            $table->timestamps();

            $table->foreign('plan_id')->references('id')->on('workout_plans')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_plan_days');
    }
};
