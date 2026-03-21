<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCustomWorkoutRequest;
use App\Models\CustomWorkout;
use App\Services\ExerciseOverrideService;
use Illuminate\Support\Facades\Auth;

class CustomWorkoutController extends Controller
{
    public function __construct(private ExerciseOverrideService $overrideService)
    {
    }

    public function index()
    {
        $userId   = Auth::id();
        $workouts = CustomWorkout::where('user_id', $userId)
            ->with('exercises')
            ->latest()
            ->get();

        // Batch-load all overrides for this user (one query — avoids N+1)
        $exerciseIds = $workouts
            ->flatMap(fn ($w) => $w->exercises->pluck('id'))
            ->unique()->values()->all();

        $overrides = $this->overrideService->loadOverridesForUser($userId, $exerciseIds);

        $result = $workouts->map(function ($workout) use ($overrides) {
            return $this->formatWorkout($workout, $overrides);
        });

        return response()->json($result);
    }

    public function show($id)
    {
        $userId  = Auth::id();
        $workout = CustomWorkout::where('user_id', $userId)
            ->where('id', $id)
            ->firstOrFail();

        $workout->load('exercises');

        $exerciseIds = $workout->exercises->pluck('id')->values()->all();
        $overrides   = $this->overrideService->loadOverridesForUser($userId, $exerciseIds);

        return response()->json($this->formatWorkout($workout, $overrides));
    }

    public function store(StoreCustomWorkoutRequest $request)
    {
        $userId  = Auth::id();
        $workout = CustomWorkout::create([
            'user_id'      => $userId,
            'name'         => $request->name,
            'description'  => $request->description,
            'level'        => $request->level,
            'duration'     => $request->duration,
            'is_generated' => $request->boolean('is_generated'),
        ]);

        foreach ($request->exercises as $item) {
            $workout->exercises()->attach($item['exercise_id'], [
                'sets' => $item['sets'],
                'reps' => $item['reps'],
                'rest' => $item['rest'] ?? 60,
            ]);
        }

        $workout->load('exercises');

        $exerciseIds = $workout->exercises->pluck('id')->values()->all();
        $overrides   = $this->overrideService->loadOverridesForUser($userId, $exerciseIds);

        return response()->json($this->formatWorkout($workout, $overrides), 201);
    }

    public function destroy($id)
    {
        $workout = CustomWorkout::where('user_id', Auth::id())
            ->where('id', $id)
            ->firstOrFail();

        $workout->delete();

        return response()->json(['message' => 'Treino deletado com sucesso']);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function formatWorkout(CustomWorkout $workout, $overrides): array
    {
        $exercises = $workout->exercises->map(function ($exercise) use ($overrides) {
            $pivot = $exercise->pivot;

            return $this->overrideService->resolveForApi(
                $exercise,
                $overrides->get($exercise->id),
                [
                    'sets' => $pivot->sets,
                    'reps' => $pivot->reps,
                    'rest' => $pivot->rest,
                ]
            );
        })->values()->all();

        return [
            'id'           => $workout->id,
            'name'         => $workout->name,
            'description'  => $workout->description,
            'level'        => $workout->level,
            'duration'     => $workout->duration,
            'is_generated' => $workout->is_generated,
            'exercises'    => $exercises,
        ];
    }
}
