<?php

namespace Database\Factories;

use App\Models\Checkin;
use App\Models\User;
use App\Models\Gym;
use Illuminate\Database\Eloquent\Factories\Factory;
use Carbon\Carbon;

class CheckinFactory extends Factory
{
    protected $model = Checkin::class;

    public function definition(): array
    {
        return [
            'gym_id' => Gym::factory(),
            'user_id' => User::factory(),
            'checkin_date' => Carbon::today(),
        ];
    }
}