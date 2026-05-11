<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Checkin;
use App\Models\Gym;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NetworkController extends Controller
{
    // ── HELPERS ───────────────────────────────────────────────────────────────

    private function resolveChainId(Request $request): int
    {
        $user = $request->user();
        $gym  = Gym::find($user->gym_id);
        abort_unless($gym && $gym->chain_id, 400, 'network_admin sem rede configurada.');
        return (int) $gym->chain_id;
    }

    private function chainGymIds(int $chainId)
    {
        return Gym::where('chain_id', $chainId)->pluck('id');
    }

    private function formatGym(Gym $gym): array
    {
        return [
            'id'      => $gym->id,
            'name'    => $gym->name,
            'address' => $gym->address,
            'city'    => $gym->city,
            'active'  => (bool) $gym->active,
        ];
    }

    // ── DASHBOARD ─────────────────────────────────────────────────────────────

    public function dashboard(Request $request): JsonResponse
    {
        $chainId   = $this->resolveChainId($request);
        $gymIds    = $this->chainGymIds($chainId);
        $weekStart = Carbon::now()->startOfWeek();
        $weekEnd   = Carbon::now()->endOfWeek();

        $totalStudents = User::whereIn('gym_id', $gymIds)->where('role', 'user')->count();

        $weeklyCheckins = Checkin::whereIn('gym_id', $gymIds)
            ->whereBetween('checkin_date', [$weekStart->toDateString(), $weekEnd->toDateString()])
            ->count();

        $totalTrainers = User::where('role', 'trainer')
            ->whereHas('gyms', fn ($q) => $q->whereIn('gyms.id', $gymIds))
            ->count();

        $gymNames = Gym::whereIn('id', $gymIds)->pluck('name', 'id');

        $top5 = User::whereIn('gym_id', $gymIds)
            ->where('role', 'user')
            ->orderByDesc('points_balance')
            ->limit(5)
            ->get(['id', 'name', 'gym_id', 'points_balance'])
            ->map(fn ($u) => [
                'id'             => $u->id,
                'name'           => $u->name,
                'gym_name'       => $gymNames[$u->gym_id] ?? null,
                'points_balance' => $u->points_balance,
            ]);

        $branches = Gym::whereIn('id', $gymIds)
            ->withCount(['users as students_count' => fn ($q) => $q->where('role', 'user')])
            ->get()
            ->map(fn ($g) => [
                'id'              => $g->id,
                'name'            => $g->name,
                'city'            => $g->city,
                'students_count'  => $g->students_count ?? 0,
                'weekly_checkins' => Checkin::where('gym_id', $g->id)
                    ->whereBetween('checkin_date', [$weekStart->toDateString(), $weekEnd->toDateString()])
                    ->count(),
            ]);

        return response()->json([
            'total_students'  => $totalStudents,
            'weekly_checkins' => $weeklyCheckins,
            'total_branches'  => $gymIds->count(),
            'total_trainers'  => $totalTrainers,
            'top_students'    => $top5,
            'branches'        => $branches,
        ]);
    }

    // ── GYMS ──────────────────────────────────────────────────────────────────

    public function listGyms(Request $request): JsonResponse
    {
        $chainId = $this->resolveChainId($request);

        $gyms = Gym::where('chain_id', $chainId)
            ->withCount(['users as students_count' => fn ($q) => $q->where('role', 'user')])
            ->orderBy('name')
            ->get()
            ->map(fn ($g) => array_merge($this->formatGym($g), [
                'students_count' => $g->students_count ?? 0,
            ]));

        return response()->json(['gyms' => $gyms]);
    }

    public function storeGym(Request $request): JsonResponse
    {
        $chainId = $this->resolveChainId($request);

        $data = $request->validate([
            'name'    => 'required|string|max:255',
            'address' => 'nullable|string|max:500',
            'city'    => 'nullable|string|max:100',
        ]);

        $gym = Gym::create(array_merge($data, [
            'chain_id' => $chainId,
            'active'   => true,
        ]));

        return response()->json(['gym' => $this->formatGym($gym)], 201);
    }

    public function updateGym(Request $request, int $id): JsonResponse
    {
        $chainId = $this->resolveChainId($request);

        $gym = Gym::where('id', $id)->where('chain_id', $chainId)->first();
        abort_unless($gym, 403, 'Acesso negado. Filial não pertence à sua rede.');

        $data = $request->validate([
            'name'    => 'sometimes|string|max:255',
            'address' => 'sometimes|nullable|string|max:500',
            'city'    => 'sometimes|nullable|string|max:100',
        ]);

        $gym->update($data);

        return response()->json(['gym' => $this->formatGym($gym)]);
    }

    // ── TRAINERS ──────────────────────────────────────────────────────────────

    public function listTrainers(Request $request): JsonResponse
    {
        $chainId = $this->resolveChainId($request);
        $gymIds  = $this->chainGymIds($chainId);

        $trainers = User::where('role', 'trainer')
            ->whereHas('gyms', fn ($q) => $q->whereIn('gyms.id', $gymIds))
            ->with(['gyms' => fn ($q) => $q->whereIn('gyms.id', $gymIds)->select('gyms.id', 'gyms.name')])
            ->get()
            ->map(fn ($t) => [
                'id'    => $t->id,
                'name'  => $t->name,
                'email' => $t->email,
                'gyms'  => $t->gyms->map(fn ($g) => ['id' => $g->id, 'name' => $g->name])->values(),
            ]);

        return response()->json(['trainers' => $trainers]);
    }

    public function linkTrainerGym(Request $request, int $trainerId): JsonResponse
    {
        $chainId = $this->resolveChainId($request);
        $gymIds  = $this->chainGymIds($chainId);

        $data  = $request->validate(['gym_id' => 'required|integer|exists:gyms,id']);
        $gymId = (int) $data['gym_id'];

        abort_unless($gymIds->contains($gymId), 403, 'Filial não pertence à sua rede.');

        $trainer = User::where('id', $trainerId)->where('role', 'trainer')->firstOrFail();

        if (! $trainer->gyms()->where('gyms.id', $gymId)->exists()) {
            $trainer->gyms()->attach($gymId, ['is_primary' => false, 'created_at' => now()]);
        }

        return response()->json(['message' => 'Trainer vinculado à filial com sucesso.']);
    }

    public function unlinkTrainerGym(Request $request, int $trainerId, int $gymId): JsonResponse
    {
        $chainId = $this->resolveChainId($request);
        $gymIds  = $this->chainGymIds($chainId);

        abort_unless($gymIds->contains($gymId), 403, 'Filial não pertence à sua rede.');

        $trainer = User::where('id', $trainerId)->where('role', 'trainer')->firstOrFail();

        if ($trainer->gyms()->count() <= 1) {
            return response()->json([
                'message' => 'O trainer precisa estar vinculado a pelo menos uma filial.',
            ], 422);
        }

        $trainer->gyms()->detach($gymId);

        return response()->json(['message' => 'Trainer desvinculado da filial com sucesso.']);
    }

    // ── RANKING ───────────────────────────────────────────────────────────────

    public function ranking(Request $request): JsonResponse
    {
        $request->merge(['scope' => 'chain']);
        return app(RankingController::class)->index($request);
    }
}
