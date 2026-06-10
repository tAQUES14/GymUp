<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;
use App\Models\GymChain;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class SuperChainController extends Controller
{
    // ── LIST ──────────────────────────────────────────────────────────────────

    public function index(Request $request): JsonResponse
    {
        $search = trim($request->query('search', ''));

        $query = GymChain::withCount('gyms')
            ->when($search, fn ($q) => $q->where('name', 'ilike', "%{$search}%"))
            ->orderBy('name');

        $paginated = $query->paginate($request->integer('per_page', 20));

        return response()->json([
            'data' => $paginated->map(fn ($c) => [
                'id'         => $c->id,
                'name'       => $c->name,
                'slug'       => $c->slug,
                'logo_url'   => $c->logo_url,
                'status'     => $c->status ?? 'active',
                'closed_at'  => $c->closed_at?->format('Y-m-d'),
                'gyms_count' => $c->gyms_count,
                'created_at' => $c->created_at->format('Y-m-d'),
            ]),
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page'    => $paginated->lastPage(),
                'per_page'     => $paginated->perPage(),
                'total'        => $paginated->total(),
            ],
        ]);
    }

    // ── STORE ─────────────────────────────────────────────────────────────────

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'     => 'required|string|max:255',
            'slug'     => ['nullable', 'string', 'max:100', 'regex:/^[a-z0-9-]+$/', 'unique:gym_chains,slug'],
            'logo_url' => 'nullable|string|max:1000',
        ]);

        if (empty($data['slug'])) {
            $base = Str::slug($data['name']);
            $slug = $base;
            $i    = 1;
            while (GymChain::where('slug', $slug)->exists()) {
                $slug = "{$base}-{$i}";
                $i++;
            }
            $data['slug'] = $slug;
        }

        $chain = GymChain::create($data);

        return response()->json(['chain' => $this->format($chain->loadCount('gyms'))], 201);
    }

    // ── SHOW ──────────────────────────────────────────────────────────────────

    public function show(int $id): JsonResponse
    {
        $chain = GymChain::withCount('gyms')->findOrFail($id);

        $gyms = Gym::where('chain_id', $id)
            ->withCount(['users as students_count' => fn ($q) => $q->where('role', 'user')])
            ->orderBy('name')
            ->get()
            ->map(fn ($g) => [
                'id'             => $g->id,
                'name'           => $g->name,
                'students_count' => $g->students_count ?? 0,
            ]);

        return response()->json([
            'id'         => $chain->id,
            'name'       => $chain->name,
            'slug'       => $chain->slug,
            'logo_url'   => $chain->logo_url,
            'status'     => $chain->status ?? 'active',
            'closed_at'  => $chain->closed_at?->format('Y-m-d'),
            'gyms_count' => $chain->gyms_count,
            'created_at' => $chain->created_at->format('Y-m-d'),
            'gyms'       => $gyms,
        ]);
    }

    // ── UPDATE ────────────────────────────────────────────────────────────────

    public function update(Request $request, int $id): JsonResponse
    {
        $chain = GymChain::findOrFail($id);

        $data = $request->validate([
            'name'     => 'sometimes|string|max:255',
            'slug'     => ['sometimes', 'string', 'max:100', 'regex:/^[a-z0-9-]+$/', Rule::unique('gym_chains', 'slug')->ignore($id)],
            'logo_url' => 'sometimes|nullable|string|max:1000',
        ]);

        $chain->update($data);

        return response()->json(['chain' => $this->format($chain->loadCount('gyms'))]);
    }

    // ── DESTROY ───────────────────────────────────────────────────────────────

    public function destroy(int $id): JsonResponse
    {
        $chain = GymChain::findOrFail($id);

        DB::transaction(function () use ($chain) {
            Gym::where('chain_id', $chain->id)->update(['chain_id' => null]);

            $chain->update([
                'status'    => 'closed',
                'closed_at' => now(),
            ]);
        });

        return response()->json(['message' => 'Rede encerrada. As filiais ficaram independentes.']);
    }

    public function reactivate(int $id): JsonResponse
    {
        $chain = GymChain::findOrFail($id);

        $chain->update([
            'status'    => 'active',
            'closed_at' => null,
        ]);

        return response()->json(['chain' => $this->format($chain->loadCount('gyms'))]);
    }

    // ── LINK GYM ─────────────────────────────────────────────────────────────

    public function linkGym(Request $request, int $id): JsonResponse
    {
        $chain = GymChain::findOrFail($id);

        if (($chain->status ?? 'active') === 'closed') {
            return response()->json([
                'message' => 'Reative a rede antes de vincular novas academias.',
            ], 422);
        }

        $data = $request->validate([
            'gym_id' => 'required|integer|exists:gyms,id',
        ]);

        $gym = Gym::findOrFail($data['gym_id']);

        if ($gym->chain_id !== null && $gym->chain_id !== $id) {
            return response()->json([
                'message' => 'Esta academia já pertence a outra rede.',
            ], 422);
        }

        $gym->update(['chain_id' => $chain->id]);

        return response()->json(['message' => 'Academia vinculada com sucesso.']);
    }

    // ── UNLINK GYM ───────────────────────────────────────────────────────────

    public function unlinkGym(int $id, int $gymId): JsonResponse
    {
        $chain = GymChain::findOrFail($id);
        $gym   = Gym::where('chain_id', $chain->id)->where('id', $gymId)->firstOrFail();

        $gym->update(['chain_id' => null]);

        return response()->json(['message' => 'Academia desvinculada com sucesso.']);
    }

    // ── INDEPENDENT GYMS (helper para o modal de vinculação) ─────────────────

    public function independentGyms(Request $request): JsonResponse
    {
        $search = trim($request->query('search', ''));

        $gyms = Gym::whereNull('chain_id')
            ->when($search, fn ($q) => $q->where('name', 'ilike', "%{$search}%"))
            ->orderBy('name')
            ->limit(50)
            ->get(['id', 'name']);

        return response()->json(['gyms' => $gyms]);
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    public function gyms(Request $request): JsonResponse
    {
        $search = trim($request->query('search', ''));

        $query = Gym::query()
            ->with('chain:id,name')
            ->withCount([
                'users as students_count' => fn ($q) => $q->where('role', 'user'),
                'users as admins_count' => fn ($q) => $q->where('role', 'gym_admin'),
                'trainers as trainers_count',
            ])
            ->when($search, function ($q) use ($search) {
                $q->where(function ($inner) use ($search) {
                    $inner->where('name', 'ilike', "%{$search}%")
                        ->orWhere('city', 'ilike', "%{$search}%")
                        ->orWhere('email', 'ilike', "%{$search}%")
                        ->orWhereHas('chain', fn ($chain) => $chain->where('name', 'ilike', "%{$search}%"));
                });
            })
            ->orderBy('name');

        $paginated = $query->paginate($request->integer('per_page', 20));

        return response()->json([
            'data' => $paginated->map(fn ($g) => [
                'id'             => $g->id,
                'name'           => $g->name,
                'email'          => $g->email,
                'phone'          => $g->phone,
                'address'        => $g->address,
                'city'           => $g->city,
                'active'         => (bool) $g->active,
                'invite_code'    => $g->invite_code,
                'chain'          => $g->chain ? [
                    'id'   => $g->chain->id,
                    'name' => $g->chain->name,
                ] : null,
                'students_count' => $g->students_count ?? 0,
                'admins_count'   => $g->admins_count ?? 0,
                'trainers_count' => $g->trainers_count ?? 0,
                'created_at'     => $g->created_at?->format('Y-m-d'),
            ]),
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page'    => $paginated->lastPage(),
                'per_page'     => $paginated->perPage(),
                'total'        => $paginated->total(),
            ],
            'summary' => [
                'total'       => Gym::count(),
                'active'      => Gym::where('active', true)->count(),
                'independent' => Gym::whereNull('chain_id')->count(),
                'in_chains'   => Gym::whereNotNull('chain_id')->count(),
            ],
        ]);
    }

    private function format(GymChain $chain): array
    {
        return [
            'id'         => $chain->id,
            'name'       => $chain->name,
            'slug'       => $chain->slug,
            'logo_url'   => $chain->logo_url,
            'status'     => $chain->status ?? 'active',
            'closed_at'  => $chain->closed_at?->format('Y-m-d'),
            'gyms_count' => $chain->gyms_count ?? 0,
            'created_at' => $chain->created_at->format('Y-m-d'),
        ];
    }
}
