<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\WorkoutHistory;
use Illuminate\Support\Facades\Auth;

class WorkoutHistoryController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'workout_id' => 'required|string',
            'workout_name' => 'required|string',
            'duration_minutes' => 'required|integer',
            'sets_completed' => 'required|integer',
            'sets_total' => 'required|integer',
            'points_earned' => 'required|integer',
            'had_checkin' => 'required|boolean'
        ]);

        $history = WorkoutHistory::create([
            'user_id' => Auth::id(),
            ...$validated
        ]);

        return response()->json($history, 201);
    }

    public function index()
    {
        return response()->json(
            WorkoutHistory::where('user_id', Auth::id())
                ->latest()
                ->get()
        );
    }
}