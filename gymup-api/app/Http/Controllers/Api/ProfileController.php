<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user()->load('gym:id,name');

        $totalCheckins = DB::table('checkins')
            ->where('user_id', $user->id)
            ->count();

        // Calcula streak atual usando window function do Postgres.
        // Agrupa datas consecutivas subtraindo o row_number, formando "ilhas".
        // Retorna o tamanho da ilha mais recente, desde que o último check-in
        // tenha sido hoje ou ontem (streak ainda ativo).
        $streakRow = DB::selectOne("
            WITH ordered AS (
                SELECT checkin_date,
                       checkin_date - (ROW_NUMBER() OVER (ORDER BY checkin_date))::int AS grp
                FROM checkins
                WHERE user_id = ?
            ),
            groups AS (
                SELECT grp,
                       COUNT(*)             AS streak,
                       MAX(checkin_date)    AS last_day
                FROM ordered
                GROUP BY grp
            )
            SELECT streak
            FROM groups
            WHERE last_day >= CURRENT_DATE - INTERVAL '1 day'
            ORDER BY last_day DESC
            LIMIT 1
        ", [$user->id]);

        $currentStreak = $streakRow ? (int) $streakRow->streak : 0;

        return response()->json([
            'id'             => $user->id,
            'name'           => $user->name,
            'email'          => $user->email,
            'role'           => $user->role,
            'points_balance' => (int) $user->points_balance,
            'total_checkins' => $totalCheckins,
            'current_streak' => $currentStreak,
            'gym'            => $user->gym ? [
                'id'   => $user->gym->id,
                'name' => $user->gym->name,
            ] : null,
        ]);
    }
}
