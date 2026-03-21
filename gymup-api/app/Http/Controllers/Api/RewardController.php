<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Reward;

class RewardController extends Controller
{
    public function index(Request $request)
    {
        $rewards = Reward::where('gym_id', $request->user()->gym_id)
            ->where('active', true)
            ->get(['id', 'name', 'description', 'points_cost', 'stock', 'image_url', 'category']);

        return response()->json($rewards);
    }
}
