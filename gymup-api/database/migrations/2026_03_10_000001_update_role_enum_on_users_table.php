<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'pgsql') {
            // PostgreSQL: alter column type and constraints
            DB::statement('ALTER TABLE users ALTER COLUMN role TYPE varchar(20)');
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('super_admin', 'trainer', 'user'))");
            DB::statement("ALTER TABLE users ALTER COLUMN role SET DEFAULT 'user'");
        }

        // Migrate data values for all drivers
        DB::table('users')->where('role', 'admin')->update(['role' => 'super_admin']);
        DB::table('users')->where('role', 'student')->update(['role' => 'user']);
    }

    public function down(): void
    {
        DB::table('users')->where('role', 'super_admin')->update(['role' => 'admin']);
        DB::table('users')->where('role', 'user')->update(['role' => 'student']);
        DB::table('users')->where('role', 'trainer')->update(['role' => 'student']);

        $driver = DB::getDriverName();

        if ($driver === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('admin', 'student'))");
            DB::statement("ALTER TABLE users ALTER COLUMN role SET DEFAULT 'student'");
        }
    }
};
