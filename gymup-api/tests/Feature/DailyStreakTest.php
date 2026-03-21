<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Gym;
use App\Models\User;
use App\Models\Checkin;
use App\Models\WorkoutSession;
use App\Models\UserTrainingSchedule;
use App\Services\StreakService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

/**
 * Daily Streak Tests
 *
 * Streak rule: increases when a workout is completed on a planned training day.
 * Rest days: streak unchanged.
 * Missed training day: streak resets to 0.
 */
class DailyStreakTest extends TestCase
{
    use RefreshDatabase;

    private Gym $gym;
    private User $user;

    protected function setUp(): void
    {
        parent::setUp();

        $this->gym  = Gym::factory()->create();
        $this->user = User::factory()->create([
            'gym_id'         => $this->gym->id,
            'points_balance' => 0,
            'current_streak' => 0,
            'best_streak'    => 0,
        ]);

        Sanctum::actingAs($this->user);
    }

    /**
     * Assign training days to the user (0=Sun, 1=Mon, ..., 6=Sat).
     */
    private function setSchedule(array $days): void
    {
        foreach ($days as $day) {
            UserTrainingSchedule::create([
                'user_id'     => $this->user->id,
                'gym_id'      => $this->gym->id,
                'day_of_week' => $day,
            ]);
        }
    }

    /**
     * Simulate a workout completed with points on the given date.
     */
    private function completeWorkoutOn(Carbon $date): WorkoutSession
    {
        return WorkoutSession::create([
            'user_id'           => $this->user->id,
            'gym_id'            => $this->gym->id,
            'started_at'        => $date->copy()->subMinutes(30),
            'finished_at'       => $date,
            'progress'          => 100,
            'points_granted'    => true,
            'points_granted_at' => $date,
        ]);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Cenário 1: Treino seg, ter, desc qua, treino qui — streak = 3
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function scenario_1_rest_day_does_not_break_streak(): void
    {
        // Mon, Tue, Thu, Fri are training days — Wed is rest
        $this->setSchedule([1, 2, 4, 5]);

        $monday    = Carbon::parse('2026-03-09'); // Monday
        $tuesday   = Carbon::parse('2026-03-10'); // Tuesday
        $thursday  = Carbon::parse('2026-03-12'); // Thursday (rest on Wednesday)

        $this->completeWorkoutOn($monday);
        $this->completeWorkoutOn($tuesday);
        $this->completeWorkoutOn($thursday);

        $service = new StreakService();

        // Simulate processing each workout
        $this->user->last_workout_date = null;
        $this->user->current_streak    = 0;
        $this->user->save();

        // Monday workout
        Carbon::setTestNow($monday);
        $this->user->refresh();
        $result = $service->processWorkoutForDailyStreak($this->user);
        $this->assertEquals(1, $result['streak']);

        // Tuesday workout
        Carbon::setTestNow($tuesday);
        $this->user->refresh();
        $result = $service->processWorkoutForDailyStreak($this->user);
        $this->assertEquals(2, $result['streak']);

        // Thursday workout — Wednesday was a rest day, streak should NOT break
        Carbon::setTestNow($thursday);
        $this->user->refresh();
        $result = $service->processWorkoutForDailyStreak($this->user);
        $this->assertEquals(3, $result['streak'], 'Rest day (Wed) must not break streak');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Cenário 2: Treino seg, ter, faltou qua (dia de treino) — streak = 0
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function scenario_2_missed_training_day_breaks_streak(): void
    {
        // Mon, Tue, Wed, Thu are training days
        $this->setSchedule([1, 2, 3, 4]);

        $monday    = Carbon::parse('2026-03-09');
        $tuesday   = Carbon::parse('2026-03-10');
        $thursday  = Carbon::parse('2026-03-12'); // Wed (training day) was skipped

        $this->completeWorkoutOn($monday);
        $this->completeWorkoutOn($tuesday);
        // Intentionally no workout on Wednesday
        $this->completeWorkoutOn($thursday);

        $service = new StreakService();

        $this->user->last_workout_date = null;
        $this->user->current_streak    = 0;
        $this->user->save();

        Carbon::setTestNow($monday);
        $this->user->refresh();
        $service->processWorkoutForDailyStreak($this->user);

        Carbon::setTestNow($tuesday);
        $this->user->refresh();
        $service->processWorkoutForDailyStreak($this->user);

        // Thursday: check misses Wednesday → streak breaks to 0, then increments to 1
        Carbon::setTestNow($thursday);
        $this->user->refresh();
        $result = $service->processWorkoutForDailyStreak($this->user);

        $this->assertEquals(1, $result['streak'], 'After missing Wed, streak should reset to 1 (this workout)');
        $this->assertEquals(2, $result['best_streak'], 'best_streak should still reflect previous high of 2');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Cenário 3: Treino seg, desc ter, treino qua — streak = 2
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function scenario_3_non_consecutive_training_days_with_rest_between(): void
    {
        // Mon and Wed are training days — Tue is rest
        $this->setSchedule([1, 3]);

        $monday    = Carbon::parse('2026-03-09');
        $wednesday = Carbon::parse('2026-03-11');

        $this->completeWorkoutOn($monday);
        // Tuesday skipped — it is a rest day
        $this->completeWorkoutOn($wednesday);

        $service = new StreakService();

        $this->user->last_workout_date = null;
        $this->user->current_streak    = 0;
        $this->user->save();

        Carbon::setTestNow($monday);
        $this->user->refresh();
        $result = $service->processWorkoutForDailyStreak($this->user);
        $this->assertEquals(1, $result['streak']);

        // Wednesday: Tuesday was a rest day — streak continues
        Carbon::setTestNow($wednesday);
        $this->user->refresh();
        $result = $service->processWorkoutForDailyStreak($this->user);
        $this->assertEquals(2, $result['streak'], 'Rest day (Tue) must not interrupt streak');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Edge: treinar duas vezes no mesmo dia — streak conta só uma vez
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function same_day_workout_is_idempotent(): void
    {
        $this->setSchedule([1]); // Monday only

        $monday = Carbon::parse('2026-03-09');
        Carbon::setTestNow($monday);

        $this->completeWorkoutOn($monday);
        $this->completeWorkoutOn($monday); // second workout same day

        $service = new StreakService();

        $this->user->last_workout_date = null;
        $this->user->current_streak    = 0;
        $this->user->save();

        $service->processWorkoutForDailyStreak($this->user);
        $this->user->refresh();
        $result = $service->processWorkoutForDailyStreak($this->user);

        $this->assertEquals(1, $result['streak'], 'Second workout on the same day must not double-count streak');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Edge: dia de descanso — streak permanece inalterado via GET /dashboard
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function rest_day_dashboard_call_leaves_streak_unchanged(): void
    {
        // Only Monday is a training day; user already has a 3-day streak
        $this->setSchedule([1]);

        $this->user->update([
            'current_streak'    => 3,
            'best_streak'       => 3,
            'last_workout_date' => '2026-03-09', // Last Monday
        ]);

        // Simulate a Wednesday (rest day) — no training scheduled
        $wednesday = Carbon::parse('2026-03-11');
        Carbon::setTestNow($wednesday);

        $this->user->refresh();
        $service = new StreakService();
        $result  = $service->getStreakState($this->user);

        $this->assertEquals(3, $result['streak'], 'Streak must remain 3 on a rest day');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Edge: best_streak é atualizado corretamente
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function best_streak_updates_when_current_exceeds_it(): void
    {
        $this->setSchedule([1, 2, 3]); // Mon, Tue, Wed

        $monday    = Carbon::parse('2026-03-09');
        $tuesday   = Carbon::parse('2026-03-10');
        $wednesday = Carbon::parse('2026-03-11');

        $this->completeWorkoutOn($monday);
        $this->completeWorkoutOn($tuesday);
        $this->completeWorkoutOn($wednesday);

        $service = new StreakService();

        $this->user->last_workout_date = null;
        $this->user->current_streak    = 0;
        $this->user->best_streak       = 0;
        $this->user->save();

        Carbon::setTestNow($monday);
        $this->user->refresh();
        $service->processWorkoutForDailyStreak($this->user);

        Carbon::setTestNow($tuesday);
        $this->user->refresh();
        $service->processWorkoutForDailyStreak($this->user);

        Carbon::setTestNow($wednesday);
        $this->user->refresh();
        $result = $service->processWorkoutForDailyStreak($this->user);

        $this->assertEquals(3, $result['streak']);
        $this->assertEquals(3, $result['best_streak']);

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Edge: sem agenda de treinos — streak não é alterado
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function user_without_schedule_streak_is_not_modified(): void
    {
        // No schedule set
        $monday = Carbon::parse('2026-03-09');
        $this->completeWorkoutOn($monday);

        Carbon::setTestNow($monday);
        $this->user->refresh();

        $service = new StreakService();
        $result  = $service->processWorkoutForDailyStreak($this->user);

        $this->assertEquals(0, $result['streak'], 'Without a training schedule, streak must stay 0');

        Carbon::setTestNow(null);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Integration: admin sets schedule, user reads it
    // ──────────────────────────────────────────────────────────────────────────

    /** @test */
    public function api_can_set_and_retrieve_training_schedule(): void
    {
        // Only trainer/gym_admin can write the schedule
        $trainer = \App\Models\User::factory()->create([
            'gym_id' => $this->gym->id,
            'role'   => 'trainer',
        ]);
        \Laravel\Sanctum\Sanctum::actingAs($trainer);

        $response = $this->putJson("/api/admin/users/{$this->user->id}/training-schedule", [
            'days' => [1, 2, 4, 5], // Mon, Tue, Thu, Fri
        ]);

        $response->assertOk()
            ->assertJsonFragment(['training_days' => [1, 2, 4, 5]]);

        $this->assertCount(4, UserTrainingSchedule::where('user_id', $this->user->id)->get());

        // The student reads back their own schedule
        \Laravel\Sanctum\Sanctum::actingAs($this->user);
        $getResponse = $this->getJson('/api/training-schedule');
        $getResponse->assertOk()
            ->assertJsonFragment(['training_days' => [1, 2, 4, 5]]);
    }

    /** @test */
    public function api_replaces_schedule_on_update(): void
    {
        $trainer = \App\Models\User::factory()->create([
            'gym_id' => $this->gym->id,
            'role'   => 'trainer',
        ]);
        \Laravel\Sanctum\Sanctum::actingAs($trainer);

        $this->putJson("/api/admin/users/{$this->user->id}/training-schedule", ['days' => [1, 2, 3]]);
        $this->putJson("/api/admin/users/{$this->user->id}/training-schedule", ['days' => [4, 5]]);

        $this->assertCount(2, UserTrainingSchedule::where('user_id', $this->user->id)->get());
    }
}
