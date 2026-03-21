<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exercise;
use Illuminate\Http\JsonResponse;

class ExerciseController extends Controller
{
    /**
     * Lightweight exercise library — only the fields needed for list views.
     * gif_file is included so the gif_url accessor can compute the full URL.
     */
    public function index(): JsonResponse
    {
        $exercises = Exercise::select('id', 'name', 'muscle_group', 'primary_muscle', 'gif_file')
            ->orderBy('muscle_group')
            ->orderBy('name')
            ->get();

        return response()->json($exercises);
    }

    /**
     * Full exercise details — description, steps, tips, mistakes, etc.
     */
    public function show(int $id): JsonResponse
    {
        $exercise = Exercise::findOrFail($id);

        return response()->json($exercise);
    }
}
