<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Redemption;
use App\Models\PointTransaction;

class AdminDashboardController extends Controller
{
    public function index(Request $request)
    {
        $admin = $request->user();

        $gymId = $admin->gym_id;

        $totalStudents = User::where('gym_id', $gymId)
            ->where('role', 'student')
            ->count();

        $totalPointsDistributed = PointTransaction::where('gym_id', $gymId)
            ->where('type', 'earn')
            ->sum('points');

        $pendingRedemptions = Redemption::where('gym_id', $gymId)
            ->where('status', 'pending')
            ->count();

        $approvedRedemptions = Redemption::where('gym_id', $gymId)
            ->where('status', 'approved')
            ->count();

        $topStudents = User::where('gym_id', $gymId)
            ->where('role', 'student')
            ->orderByDesc('points_balance')
            ->limit(5)
            ->select('id', 'name', 'points_balance')
            ->get();

        return response()->json([
            'total_students' => $totalStudents,
            'total_points_distributed' => $totalPointsDistributed,
            'pending_redemptions' => $pendingRedemptions,
            'approved_redemptions' => $approvedRedemptions,
            'top_students' => $topStudents,
        ]);
    }
}