<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Gym;
use App\Models\Checkin;
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
            'points_balance' => 0,
        ]);

        Sanctum::actingAs($user);

        $response = $this->postJson('/api/checkin');
        $response->assertStatus(200);

        $response2 = $this->postJson('/api/checkin');
        $response2->assertStatus(400);
    }

    public function test_checkin_does_not_give_points()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create([
            'gym_id'         => $gym->id,
            'points_balance' => 0,
        ]);

        Sanctum::actingAs($user);

        $this->postJson('/api/checkin')->assertStatus(200);

        $user->refresh();
        $this->assertEquals(0, $user->points_balance);
    }

    public function test_checkin_creates_record_with_date()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);

        Sanctum::actingAs($user);

        $this->postJson('/api/checkin')->assertStatus(200);

        $this->assertDatabaseHas('checkins', [
            'user_id'      => $user->id,
            'checkin_date' => now()->toDateString(),
        ]);
    }

    public function test_checkin_status_returns_correct_state()
    {
        $gym  = Gym::factory()->create();
        $user = User::factory()->create(['gym_id' => $gym->id]);

        Sanctum::actingAs($user);

        $response = $this->getJson('/api/checkin/status');
        $response->assertStatus(200);
        $this->assertFalse($response->json('checked_in_today'));

        $this->postJson('/api/checkin');

        $response = $this->getJson('/api/checkin/status');
        $this->assertTrue($response->json('checked_in_today'));
    }
}
