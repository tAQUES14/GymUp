<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminUserController extends Controller
{
    // ── LIST ──────────────────────────────────────────────────────────────────

    public function index(Request $request): JsonResponse
    {
        $gymId  = $request->user()->activeGymId();
        $search = trim($request->query('search', ''));
        $gym    = Gym::find($gymId);
        $chainId = $gym?->chain_id;

        $baseQuery = fn (bool $ownGym) => function ($q) use ($gymId, $search, $chainId, $ownGym) {
            if ($ownGym) {
                $q->where('gym_id', $gymId);
            } else {
                $chainGymIds = Gym::where('chain_id', $chainId)->where('id', '!=', $gymId)->pluck('id');
                $q->whereIn('gym_id', $chainGymIds)
                  ->whereHas('workoutSessions', fn ($s) => $s->where('checkin_gym_id', $gymId));
            }
            $q->where('role', 'user')
              ->when($search, fn ($q) => $q->where(
                  fn ($q) => $q
                      ->where('name',  'ilike', "%{$search}%")
                      ->orWhere('email', 'ilike', "%{$search}%")
              ))
              ->withCount(['workoutSessions as workouts_total' => fn ($q) => $q->where('points_granted', true)])
              ->withMax(
                  ['workoutSessions as last_activity_at' => fn ($q) => $q->where('points_granted', true)],
                  'finished_at'
              )
              ->orderBy('name');
        };

        $mapUser = fn (User $user, bool $isVisitor, ?string $homeGymName) => [
            'id'             => $user->id,
            'name'           => $user->name,
            'email'          => $user->email,
            'points_balance' => $user->points_balance,
            'workouts_total' => $user->workouts_total ?? 0,
            'last_activity'  => $user->last_activity_at
                ? Carbon::parse($user->last_activity_at)->format('Y-m-d')
                : null,
            'status'         => $this->resolveStatus($user->last_activity_at),
            'is_visitor'     => $isVisitor,
            'home_gym_name'  => $homeGymName,
        ];

        $own = User::query()->tap($baseQuery(true))->get()
            ->map(fn ($u) => $mapUser($u, false, null));

        $visitors = collect();
        if ($chainId) {
            $chainGymIds = Gym::where('chain_id', $chainId)->where('id', '!=', $gymId)->pluck('id');
            if ($chainGymIds->isNotEmpty()) {
                $gymNames = Gym::whereIn('id', $chainGymIds)->pluck('name', 'id');
                $visitors = User::query()->tap($baseQuery(false))->get()
                    ->map(fn ($u) => $mapUser($u, true, $gymNames[$u->gym_id] ?? null));
            }
        }

        $users = $own->concat($visitors)->sortBy('name')->values();

        return response()->json(['users' => $users]);
    }

    // ── SHOW ──────────────────────────────────────────────────────────────────

    public function show(Request $request, int $id): JsonResponse
    {
        $gymId   = $request->user()->activeGymId();
        $gym     = Gym::find($gymId);
        $chainId = $gym?->chain_id;

        $withStats = fn ($q) => $q
            ->withCount(['workoutSessions as workouts_total' => fn ($q) => $q->where('points_granted', true)])
            ->withMax(
                ['workoutSessions as last_activity_at' => fn ($q) => $q->where('points_granted', true)],
                'finished_at'
            );

        $user = User::where('gym_id', $gymId)
            ->where('role', 'user')
            ->where('id', $id)
            ->tap($withStats)
            ->first();

        $isVisitor   = false;
        $homeGymName = null;

        if (! $user && $chainId) {
            $chainGymIds = Gym::where('chain_id', $chainId)->where('id', '!=', $gymId)->pluck('id');
            $user = User::whereIn('gym_id', $chainGymIds)
                ->where('role', 'user')
                ->where('id', $id)
                ->whereHas('workoutSessions', fn ($q) => $q->where('checkin_gym_id', $gymId))
                ->tap($withStats)
                ->first();
            if ($user) {
                $isVisitor   = true;
                $homeGymName = Gym::find($user->gym_id)?->name;
            }
        }

        abort_unless($user, 404);

        // Recent workout sessions
        $sessions = $user->workoutSessions()
            ->orderByDesc('finished_at')
            ->limit(20)
            ->get()
            ->map(fn ($s) => [
                'id'             => $s->id,
                'started_at'     => $s->started_at?->format('Y-m-d H:i'),
                'finished_at'    => $s->finished_at?->format('Y-m-d H:i'),
                'progress'       => $s->progress,
                'points_granted' => $s->points_granted,
            ]);

        // Recent point transactions
        $transactions = $user->pointTransactions()
            ->orderByDesc('created_at')
            ->limit(30)
            ->get()
            ->map(fn ($t) => [
                'id'          => $t->id,
                'type'        => $t->type,
                'category'    => $t->category ?? 'workout',
                'points'      => $t->points,
                'description' => $t->description,
                'created_at'  => $t->created_at->format('Y-m-d H:i'),
            ]);

        // Recent redemptions
        $redemptions = $user->redemptions()
            ->with('reward:id,name')
            ->orderByDesc('created_at')
            ->limit(30)
            ->get()
            ->map(fn ($r) => [
                'id'           => $r->id,
                'reward_name'  => $r->reward?->name ?? '—',
                'points_spent' => $r->points_spent,
                'status'       => $r->status,
                'approved_at'  => $r->approved_at?->format('Y-m-d H:i'),
                'created_at'   => $r->created_at->format('Y-m-d H:i'),
            ]);

        return response()->json([
            'id'                  => $user->id,
            'name'                => $user->name,
            'email'               => $user->email,
            'birth_date'          => $user->birth_date?->format('Y-m-d'),
            'height'              => $user->height,
            'weight'              => $user->weight,
            'points_balance'      => $user->points_balance,
            'current_streak'      => (int) ($user->current_streak ?? 0),
            'best_streak'         => (int) ($user->best_streak ?? 0),
            'workouts_total'      => $user->workouts_total ?? 0,
            'last_activity'       => $user->last_activity_at
                ? Carbon::parse($user->last_activity_at)->format('Y-m-d')
                : null,
            'status'              => $this->resolveStatus($user->last_activity_at),
            'is_visitor'          => $isVisitor,
            'home_gym_name'       => $homeGymName,
            'sessions'            => $sessions,
            'transactions'        => $transactions,
            'redemptions'         => $redemptions,
        ]);
    }

    // ── UPDATE ────────────────────────────────────────────────────────────────

    public function update(Request $request, int $id): JsonResponse
    {
        $gymId = $request->user()->activeGymId();

        $user = User::where('gym_id', $gymId)
            ->where('role', 'user')
            ->where('id', $id)
            ->first();

        if (! $user) {
            $this->abortIfVisitor($id, $gymId);
            abort(404);
        }

        $data = $request->validate([
            'name'       => 'sometimes|string|max:255',
            'email'      => "sometimes|email|unique:users,email,{$id}",
            'birth_date' => 'sometimes|nullable|date|before:today',
            'height'     => 'sometimes|nullable|numeric|min:100|max:250',
            'weight'     => 'sometimes|nullable|numeric|min:20|max:300',
        ]);

        $user->update($data);

        return response()->json([
            'message' => 'Aluno atualizado com sucesso.',
            'user'    => array_merge($data, ['id' => $user->id, 'name' => $user->name, 'email' => $user->email]),
        ]);
    }

    // ── DESTROY ───────────────────────────────────────────────────────────────

    public function destroy(Request $request, int $id): JsonResponse
    {
        $gymId = $request->user()->activeGymId();

        $user = User::where('gym_id', $gymId)
            ->where('role', 'user')
            ->where('id', $id)
            ->first();

        if (! $user) {
            $this->abortIfVisitor($id, $gymId);
            abort(404);
        }

        $user->delete();

        return response()->json(['message' => 'Aluno removido com sucesso.']);
    }

    // ── ADJUST POINTS ─────────────────────────────────────────────────────────

    public function adjustPoints(Request $request, int $id): JsonResponse
    {
        $gymId = $request->user()->activeGymId();

        $user = User::where('gym_id', $gymId)
            ->where('role', 'user')
            ->where('id', $id)
            ->first();

        if (! $user) {
            $this->abortIfVisitor($id, $gymId);
            abort(404);
        }

        $data = $request->validate([
            'points'      => 'required|integer|not_in:0',
            'description' => 'required|string|max:255',
        ]);

        $pts  = abs($data['points']);
        $type = $data['points'] > 0 ? 'earn' : 'spend';

        // Prevent balance from going negative
        if ($type === 'spend' && $user->points_balance < $pts) {
            return response()->json([
                'message' => 'Saldo insuficiente para esta operação.',
            ], 422);
        }

        $user->pointTransactions()->create([
            'gym_id'      => $gymId,
            'type'        => $type,
            'category'    => 'manual',
            'points'      => $pts,
            'description' => $data['description'],
        ]);

        $user->increment('points_balance', $data['points']);

        return response()->json([
            'message'        => 'Pontos ajustados com sucesso.',
            'points_balance' => $user->fresh()->points_balance,
        ]);
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    private function abortIfVisitor(int $userId, int $gymId): void
    {
        $gym     = Gym::find($gymId);
        $chainId = $gym?->chain_id;
        if (! $chainId) return;

        $chainGymIds = Gym::where('chain_id', $chainId)->where('id', '!=', $gymId)->pluck('id');
        $isVisitor   = User::whereIn('gym_id', $chainGymIds)
            ->where('role', 'user')
            ->where('id', $userId)
            ->whereHas('workoutSessions', fn ($q) => $q->where('checkin_gym_id', $gymId))
            ->exists();

        if ($isVisitor) {
            abort(403, 'Visitantes não podem ser modificados.');
        }
    }

    private function resolveStatus(?string $lastActivityAt): string
    {
        if (!$lastActivityAt) {
            return 'new';
        }
        return Carbon::parse($lastActivityAt)->gte(now()->subDays(30))
            ? 'active'
            : 'inactive';
    }
}
