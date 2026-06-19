<?php

use Illuminate\Database\Migrations\Migration;
use Database\Seeders\DemoWeekSeeder;

return new class extends Migration
{
    public function up(): void
    {
        app(DemoWeekSeeder::class)->run();
    }

    public function down(): void {}
};
