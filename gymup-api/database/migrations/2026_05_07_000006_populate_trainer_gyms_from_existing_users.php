<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $trainers = DB::table('users')
            ->whereIn('role', ['trainer', 'gym_admin'])
            ->whereNotNull('gym_id')
            ->select('id', 'gym_id')
            ->get();

        foreach ($trainers as $trainer) {
            DB::table('trainer_gyms')->insertOrIgnore([
                'trainer_id' => $trainer->id,
                'gym_id'     => $trainer->gym_id,
                'is_primary' => true,
                'created_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        // Backfill is non-destructive; down() intentionally left empty.
    }
};
