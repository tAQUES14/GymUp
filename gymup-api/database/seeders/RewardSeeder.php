<?php

namespace Database\Seeders;

use App\Models\Gym;
use App\Models\Reward;
use Illuminate\Database\Seeder;

class RewardSeeder extends Seeder
{
    public function run(): void
    {
        $gym = Gym::first();

        if (!$gym) {
            return;
        }

        $rewards = [
            [
                'name'             => 'Garrafa Esportiva',
                'description'      => 'Garrafa térmica de 750ml com logo da academia.',
                'points_cost'      => 100,
                'stock'            => 50,
                'discount_percent' => null,
            ],
            [
                'name'             => 'Camiseta GymUp',
                'description'      => 'Camiseta dry-fit exclusiva da academia.',
                'points_cost'      => 250,
                'stock'            => 30,
                'discount_percent' => null,
            ],
            [
                'name'             => '10% de Desconto na Mensalidade',
                'description'      => 'Desconto aplicado na próxima mensalidade.',
                'points_cost'      => 500,
                'stock'            => null,
                'discount_percent' => 10.00,
            ],
            [
                'name'             => 'Sessão de Personal Trainer',
                'description'      => 'Uma sessão individual com personal trainer.',
                'points_cost'      => 300,
                'stock'            => 20,
                'discount_percent' => null,
            ],
            [
                'name'             => 'Shaker de Proteína',
                'description'      => 'Copo shaker de 600ml para suplementos.',
                'points_cost'      => 80,
                'stock'            => 100,
                'discount_percent' => null,
            ],
            [
                'name'             => 'Toalha de Academia',
                'description'      => 'Toalha de microfibra com logo GymUp.',
                'points_cost'      => 150,
                'stock'            => 40,
                'discount_percent' => null,
            ],
            [
                'name'             => '20% de Desconto na Mensalidade',
                'description'      => 'Desconto de 20% aplicado na próxima mensalidade.',
                'points_cost'      => 900,
                'stock'            => null,
                'discount_percent' => 20.00,
            ],
            [
                'name'             => 'Mês Grátis',
                'description'      => 'Uma mensalidade inteiramente grátis.',
                'points_cost'      => 2000,
                'stock'            => 5,
                'discount_percent' => 100.00,
            ],
        ];

        foreach ($rewards as $reward) {
            Reward::firstOrCreate(
                ['gym_id' => $gym->id, 'name' => $reward['name']],
                array_merge($reward, ['gym_id' => $gym->id])
            );
        }
    }
}
