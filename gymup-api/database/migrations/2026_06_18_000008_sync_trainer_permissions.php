<?php

use Illuminate\Database\Migrations\Migration;
use Database\Seeders\RolesAndPermissionsSeeder;

return new class extends Migration
{
    public function up(): void
    {
        app(RolesAndPermissionsSeeder::class)->run();
    }

    public function down(): void {}
};
