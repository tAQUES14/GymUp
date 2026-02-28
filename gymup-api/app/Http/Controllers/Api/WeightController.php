<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ExerciseWeight;
use Illuminate\Http\Request;

class WeightController extends Controller
{
    public function store(Request $request, $exerciseId)
    {
        $request->validate([
            'weight' => 'required|numeric',
            'reps'   => 'required|integer',
            'note'   => 'nullable|string'
        ]);

        $weight = ExerciseWeight::create([
            'user_id'     => $request->user()->id,
            'exercise_id' => $exerciseId,
            'weight'      => $request->weight,
            'reps'        => $request->reps,
            'note'        => $request->note,
        ]);

        return response()->json($weight, 201);
    }

    public function last(Request $request, $exerciseId)
    {
        $last = ExerciseWeight::where('user_id', $request->user()->id)
            ->where('exercise_id', $exerciseId)
            ->latest()
            ->first();

        if (!$last) {
            return response()->json(null, 200);
        }

        return response()->json($last);
    }
}