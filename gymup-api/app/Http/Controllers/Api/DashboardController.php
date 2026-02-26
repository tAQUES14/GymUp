<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $user  = $request->user();
        $today = Carbon::today()->toDateString();

        // Uma única query — sem N+1
        $dates = Checkin::where('user_id', $user->id)
            ->orderBy('checkin_date', 'desc')
            ->pluck('checkin_date') // Collection<string>
            ->map(fn($d) => Carbon::parse($d)->toDateString())
            ->all();

        $totalCheckins    = count($dates);
        $hasCheckedInToday = in_array($today, $dates, true);

        // ── Streak ───────────────────────────────────────────────────────────
        // Percorre as datas (já em ordem decrescente) e conta dias consecutivos
        // a partir de hoje ou de ontem (se não fez check-in hoje ainda).
        // --- STREAK CORRETA ---
$streak = 0;

$expected = $hasCheckedInToday
    ? Carbon::today()
    : Carbon::yesterday();

foreach ($dates as $dateStr) {
    $date = Carbon::parse($dateStr);

    if ($date->equalTo($expected)) {
        $streak++;
        $expected = $expected->subDay();
    } elseif ($date->lt($expected)) {
        break;
    }
}

        return response()->json([
            'points_balance'    => $user->points_balance,
            'has_checked_in_today' => $hasCheckedInToday,
            'streak'            => $streak,
            'total_checkins'    => $totalCheckins,
        ]);
    }
}
