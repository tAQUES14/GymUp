<?php

namespace Database\Seeders;

use App\Models\Gym;
use Illuminate\Database\Seeder;

class GymSeeder extends Seeder
{
    public function run(): void
    {
        Gym::firstOrCreate(
            ['name' => 'GymUp Default'],
            [
                'email'   => 'contato@gymup.com',
                'phone'   => null,
                'address' => null,
                'active'  => true,
            ]
        );
    }
}
