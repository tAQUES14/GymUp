<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Gym;
use Laravel\Sanctum\Sanctum;
use Illuminate\Foundation\Testing\RefreshDatabase;

class CheckinTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_checkin_once_per_day()
    {
        $gym = Gym::factory()->create();

        $user = User::factory()->create([
            'gym_id' => $gym->id,
            'points_balance' => 0
        ]);

        Sanctum::actingAs($user);

        $response = $this->postJson('/api/checkin');
        $response->assertStatus(200);

        $response2 = $this->postJson('/api/checkin');
        $response2->assertStatus(409);
    }
}