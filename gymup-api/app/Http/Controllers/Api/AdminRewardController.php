<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Redemption;
use App\Models\Reward;
use App\Services\ImageService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminRewardController extends Controller
{
    public function __construct(private ImageService $images) {}

    public function index(Request $request): JsonResponse
    {
        $gymId = $request->user()->gym_id;

        $rewards = Reward::where('gym_id', $gymId)
            ->withCount([
                'redemptions',
                'redemptions as pending_count' => fn ($q) => $q->where('status', 'pending'),
            ])
            ->orderByDesc('created_at')
            ->get();

        return response()->json(['rewards' => $rewards]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'             => 'required|string|max:150',
            'description'      => 'nullable|string|max:600',
            'category'         => 'required|in:physical,service,discount',
            'points_cost'      => 'required|integer|min:1',
            'stock'            => 'nullable|integer|min:0',
            'discount_percent' => 'nullable|numeric|min:0|max:100',
            'active'           => 'boolean',
            'image'            => 'nullable|image|mimes:jpeg,png,jpg,webp,gif|max:10240',
        ]);

        $imageUrl = null;
        if ($request->hasFile('image')) {
            $imageUrl = $this->images->store($request->file('image'), 'rewards');
        }

        $reward = Reward::create([
            'gym_id'           => $request->user()->gym_id,
            'name'             => $data['name'],
            'description'      => $data['description'] ?? null,
            'image_url'        => $imageUrl,
            'category'         => $data['category'],
            'points_cost'      => $data['points_cost'],
            'stock'            => $data['stock'] ?? null,
            'discount_percent' => $data['discount_percent'] ?? null,
            'active'           => $data['active'] ?? true,
        ]);

        return response()->json(['reward' => $reward], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $reward = Reward::where('gym_id', $request->user()->gym_id)
            ->findOrFail($id);

        $data = $request->validate([
            'name'             => 'required|string|max:150',
            'description'      => 'nullable|string|max:600',
            'category'         => 'required|in:physical,service,discount',
            'points_cost'      => 'required|integer|min:1',
            'stock'            => 'nullable|integer|min:0',
            'discount_percent' => 'nullable|numeric|min:0|max:100',
            'active'           => 'boolean',
            'image'            => 'nullable|image|mimes:jpeg,png,jpg,webp,gif|max:10240',
            'remove_image'     => 'boolean',
        ]);

        if ($request->hasFile('image')) {
            if ($reward->image_url) {
                $this->images->delete($reward->image_url);
            }
            $data['image_url'] = $this->images->store($request->file('image'), 'rewards');
        } elseif (!empty($data['remove_image'])) {
            if ($reward->image_url) {
                $this->images->delete($reward->image_url);
            }
            $data['image_url'] = null;
        }

        $reward->update($data);

        return response()->json(['reward' => $reward->fresh()]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $reward = Reward::where('gym_id', $request->user()->gym_id)
            ->findOrFail($id);

        $pending = Redemption::where('reward_id', $id)->where('status', 'pending')->count();
        if ($pending > 0) {
            return response()->json([
                'message' => "Não é possível excluir: existem {$pending} resgate(s) pendente(s) para esta recompensa.",
            ], 409);
        }

        if ($reward->image_url) {
            $this->images->delete($reward->image_url);
        }

        $reward->delete();

        return response()->json(['message' => 'Recompensa removida.']);
    }

    public function toggle(Request $request, int $id): JsonResponse
    {
        $reward = Reward::where('gym_id', $request->user()->gym_id)
            ->findOrFail($id);

        $reward->update(['active' => !$reward->active]);

        return response()->json(['active' => $reward->active]);
    }
}
