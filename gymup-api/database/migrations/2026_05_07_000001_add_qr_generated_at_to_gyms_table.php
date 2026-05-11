<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gyms', function (Blueprint $table) {
            $table->timestamp('qr_generated_at')->nullable()->after('qr_token');
        });

        // Backfill para academias que já têm qr_token
        DB::table('gyms')->whereNotNull('qr_token')->update([
            'qr_generated_at' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::table('gyms', function (Blueprint $table) {
            $table->dropColumn('qr_generated_at');
        });
    }
};
