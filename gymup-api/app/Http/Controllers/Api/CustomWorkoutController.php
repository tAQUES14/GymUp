<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCustomWorkoutRequest;
use App\Models\CustomWorkout;
use Illuminate\Support\Facades\Auth;

class CustomWorkoutController extends Controller
{
    public function index()
    {
        $workouts = CustomWorkout::where('user_id', Auth::id())
            ->with('exercises')
            ->latest()
            ->get();

        return response()->json($workouts);
    }

    public function show($id)
    {
        $workout = CustomWorkout::where('user_id', Auth::id())
            ->where('id', $id)
            ->firstOrFail();

        $workout->load('exercises');

        return response()->json($workout);
    }

    public function store(StoreCustomWorkoutRequest $request)
    {
        $workout = CustomWorkout::create([
            'user_id'      => Auth::id(),
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

        return response()->json($workout->load('exercises'), 201);
    }

    public function destroy($id)
    {
        $workout = CustomWorkout::where('user_id', Auth::id())
            ->where('id', $id)
            ->firstOrFail();

        $workout->delete();

        return response()->json(['message' => 'Treino deletado com sucesso']);
    }
}
