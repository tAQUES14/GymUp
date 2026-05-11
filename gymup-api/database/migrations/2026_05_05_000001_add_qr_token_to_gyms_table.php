<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gyms', function (Blueprint $table) {
            $table->string('qr_token')->nullable()->unique()->after('active');
        });

        // Popula academias existentes que ainda não têm token
        DB::table('gyms')->whereNull('qr_token')->orderBy('id')->each(function ($gym) {
            DB::table('gyms')->where('id', $gym->id)->update([
                'qr_token' => (string) Str::uuid(),
            ]);
        });
    }

    public function down(): void
    {
        Schema::table('gyms', function (Blueprint $table) {
            $table->dropColumn('qr_token');
        });
    }
};
