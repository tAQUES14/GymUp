<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\AchievementService;
use Illuminate\Http\Request;

class AchievementController extends Controller
{
    public function index(Request $request, AchievementService $achievements)
    {
        return response()->json($achievements->allFor($request->user()));
    }
}
