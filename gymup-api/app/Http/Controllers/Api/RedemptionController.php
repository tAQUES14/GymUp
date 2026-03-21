<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AdminLog;
use App\Models\Redemption;
use App\Models\Reward;
use App\Models\User;
use App\Models\UserNotification;
use App\Services\PointService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RedemptionController extends Controller
{
    /**
     * POST /api/redeem
     *
     * Creates a pending redemption and immediately reserves the points.
     *
     * Why deduct at store() rather than approve():
     *   If points are only checked but not deducted, a user with 100 pts can
     *   create 5 pending requests for 100-pt rewards — all pass the balance
     *   check since no deduction happened yet. Deducting immediately makes the
     *   balance the source of truth and prevents over-commitment.
     *
     * Race condition guard:
     *   The user row is locked (lockForUpdate) before reading points_balance
     *   so two concurrent store() calls cannot both pass the check with the
     *   same stale balance.
     */
    public function store(Request $request, PointService $pointService)
    {
        $request->validate([
            'reward_id' => 'required|integer|exists:rewards,id',
        ]);

        $user = $request->user();

        $reward = Reward::where('id', $request->reward_id)
            ->where('gym_id', $user->gym_id)
            ->where('active', true)
            ->first();

        if (!$reward) {
            return response()->json(['message' => 'Recompensa não encontrada.'], 404);
        }

        if ($reward->stock !== null && $reward->stock <= 0) {
            return response()->json(['message' => 'Sem estoque disponível.'], 400);
        }

        $alreadyPending = Redemption::where('user_id', $user->id)
            ->where('reward_id', $reward->id)
            ->where('status', 'pending')
            ->exists();

        if ($alreadyPending) {
            return response()->json([
                'message' => 'Você já possui uma solicitação pendente para esta recompensa.',
            ], 409);
        }

        try {
            DB::transaction(function () use ($user, $reward, $pointService) {
                // Lock the user row so concurrent requests read a fresh balance.
                $lockedUser = User::where('id', $user->id)->lockForUpdate()->first();

                $redemption = Redemption::create([
                    'user_id'      => $lockedUser->id,
                    'reward_id'    => $reward->id,
                    'gym_id'       => $lockedUser->gym_id,
                    'points_spent' => $reward->points_cost,
                    'status'       => 'pending',
                ]);

                // spendPoints throws \Exception if balance < cost → rolls back.
                $pointService->spendPoints(
                    $lockedUser,
                    $reward->points_cost,
                    'Resgate solicitado: ' . $reward->name,
                    'redemption',
                    $redemption->id
                );
            });
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'message'        => 'Solicitação registrada. Pontos reservados até aprovação.',
            'points_balance' => (int) $user->fresh()->points_balance,
        ], 201);
    }

    /**
     * GET /api/user/redemptions
     *
     * Returns the authenticated student's own redemption history.
     */
    public function userIndex(Request $request)
    {
        $redemptions = Redemption::with('reward:id,name,image_url,category')
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($redemptions);
    }

    /**
     * POST /api/admin/redemptions/{id}/approve
     *
     * Marks the redemption as approved and decrements reward stock.
     * Points were already deducted at store(), so no point movement here.
     *
     * Concurrency guarantees:
     *   - lockForUpdate on the redemption row prevents double-approval when
     *     two admin requests arrive simultaneously for the same redemption.
     *   - lockForUpdate on the reward row prevents two approvals for different
     *     redemptions of the same reward from both passing the stock check
     *     when stock = 1.
     *
     * "Processing" state is NOT needed here: lockForUpdate ensures the second
     * concurrent request waits until the first transaction commits, at which
     * point it reads status = 'approved' and returns 404 cleanly.
     */
    public function approve(Request $request, $id)
    {
        $admin = $request->user();
        $error = null;

        DB::transaction(function () use ($id, $admin, &$error) {
            $redemption = Redemption::with('user')
                ->where('id', $id)
                ->lockForUpdate()
                ->first();

            if (!$redemption || $redemption->status !== 'pending') {
                $error = ['message' => 'Solicitação inválida ou já processada.', 'code' => 404];
                return;
            }

            if ($redemption->gym_id !== $admin->gym_id) {
                $error = ['message' => 'Acesso não autorizado para esta academia.', 'code' => 403];
                return;
            }

            // Lock the reward row to prevent a concurrent approval from passing
            // the stock check before either transaction decrements it.
            $reward = Reward::where('id', $redemption->reward_id)->lockForUpdate()->first();

            if ($reward->stock !== null && $reward->stock <= 0) {
                $error = ['message' => 'Sem estoque disponível.', 'code' => 400];
                return;
            }

            if ($reward->stock !== null) {
                $reward->decrement('stock');
            }

            $redemption->update([
                'status'      => 'approved',
                'approved_at' => now(),
            ]);

            UserNotification::notify(
                $redemption->user_id,
                'Resgate aprovado!',
                "Seu resgate de \"{$reward->name}\" foi aprovado. Retire com a equipe da academia."
            );

            AdminLog::record(
                $admin,
                'approve_redemption',
                'redemption',
                $redemption->id,
                "Aprovou resgate #{$redemption->id} — {$reward->name} para {$redemption->user->name}"
            );
        });

        if ($error) {
            return response()->json(['message' => $error['message']], $error['code']);
        }

        return response()->json(['message' => 'Resgate aprovado com sucesso.']);
    }

    /**
     * POST /api/admin/redemptions/{id}/reject
     *
     * Rejects a pending redemption and refunds the reserved points to the user.
     * A rejection_reason (optional) is stored for transparency.
     */
    public function reject(Request $request, $id, PointService $pointService)
    {
        $request->validate([
            'reason' => 'nullable|string|max:255',
        ]);

        $admin = $request->user();
        $error = null;

        DB::transaction(function () use ($id, $admin, $request, $pointService, &$error) {
            $redemption = Redemption::with('reward', 'user')
                ->where('id', $id)
                ->lockForUpdate()
                ->first();

            if (!$redemption || $redemption->status !== 'pending') {
                $error = ['message' => 'Solicitação inválida ou já processada.', 'code' => 404];
                return;
            }

            if ($redemption->gym_id !== $admin->gym_id) {
                $error = ['message' => 'Acesso não autorizado para esta academia.', 'code' => 403];
                return;
            }

            // Refund the points that were reserved at request creation.
            $pointService->earnPoints(
                $redemption->user,
                $redemption->points_spent,
                'Resgate recusado: ' . $redemption->reward->name,
                'redemption',
                $redemption->id
            );

            $reason = $request->input('reason');

            $redemption->update([
                'status'           => 'rejected',
                'rejected_at'      => now(),
                'rejection_reason' => $reason,
            ]);

            $reasonText = $reason ? " Motivo: {$reason}." : '';

            UserNotification::notify(
                $redemption->user_id,
                'Resgate não aprovado',
                "Seu resgate de \"{$redemption->reward->name}\" foi rejeitado.{$reasonText} Seus pontos foram devolvidos."
            );

            $logReason = $reason ? " (motivo: {$reason})" : '';

            AdminLog::record(
                $admin,
                'reject_redemption',
                'redemption',
                $redemption->id,
                "Rejeitou resgate #{$redemption->id} — {$redemption->reward->name} para {$redemption->user->name}{$logReason}"
            );
        });

        if ($error) {
            return response()->json(['message' => $error['message']], $error['code']);
        }

        return response()->json(['message' => 'Resgate rejeitado. Pontos devolvidos ao aluno.']);
    }

    /**
     * GET /api/admin/redemptions
     *
     * Lists redemptions for the authenticated admin's gym.
     *
     * Filters (all optional, combinable):
     *   ?status=pending|approved|rejected
     *   ?user=João         (searches name or email, case-insensitive)
     *   ?reward=Camiseta   (searches reward name, case-insensitive)
     *   ?per_page=20
     */
    public function index(Request $request)
    {
        $query = Redemption::with(['user:id,name,email', 'reward:id,name,points_cost'])
            ->where('redemptions.gym_id', $request->user()->gym_id)
            ->orderByDesc('redemptions.created_at');

        if ($request->filled('status')) {
            $status = $request->query('status');
            if (!in_array($status, ['pending', 'approved', 'rejected'])) {
                return response()->json(['message' => 'Status inválido.'], 422);
            }
            $query->where('status', $status);
        }

        // Filter by user name or email (partial, case-insensitive)
        if ($request->filled('user')) {
            $search = '%' . $request->query('user') . '%';
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'ilike', $search)
                  ->orWhere('email', 'ilike', $search);
            });
        }

        // Filter by reward name (partial, case-insensitive)
        if ($request->filled('reward')) {
            $search = '%' . $request->query('reward') . '%';
            $query->whereHas('reward', function ($q) use ($search) {
                $q->where('name', 'ilike', $search);
            });
        }

        $perPage = max(1, min((int) $request->query('per_page', 20), 50));

        return response()->json($query->paginate($perPage));
    }
}
