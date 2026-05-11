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
            $table->string('invite_code', 8)->nullable()->unique()->after('city');
        });

        // Popula academias existentes com códigos únicos
        $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        DB::table('gyms')->whereNull('invite_code')->get()->each(function ($gym) use ($chars) {
            do {
                $code = '';
                for ($i = 0; $i < 6; $i++) {
                    $code .= $chars[random_int(0, strlen($chars) - 1)];
                }
            } while (DB::table('gyms')->where('invite_code', $code)->exists());

            DB::table('gyms')->where('id', $gym->id)->update(['invite_code' => $code]);
        });
    }

    public function down(): void
    {
        Schema::table('gyms', function (Blueprint $table) {
            $table->dropColumn('invite_code');
        });
    }
};
