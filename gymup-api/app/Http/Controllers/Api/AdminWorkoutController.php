<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomWorkout;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminWorkoutController extends Controller
{
    /**
     * Lista apenas os treinos-modelo da academia (biblioteca).
     * Cópias atribuídas a alunos não aparecem aqui.
     */
    public function index(Request $request): JsonResponse
    {
        $gymId  = $request->user()->activeGymId();
        $search = trim($request->query('search', ''));

        $userIds = User::where('gym_id', $gymId)->pluck('id');

        $workouts = CustomWorkout::whereIn('user_id', $userIds)
            ->where('is_template', true)
            ->when($search, fn ($q) => $q->where('name', 'ilike', "%{$search}%"))
            ->withCount('exercises')
            ->withCount('copies as assigned_count')
            ->with(['user:id,name'])
            ->latest()
            ->get()
            ->map(fn ($w) => $this->formatWorkout($w));

        return response()->json(['workouts' => $workouts]);
    }

    /**
     * Detalhe de um treino-modelo: informações + exercícios + lista de atribuições.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $gymId   = $request->user()->activeGymId();
        $userIds = User::where('gym_id', $gymId)->pluck('id');

        $workout = CustomWorkout::whereIn('user_id', $userIds)
            ->where('is_template', true)
            ->with(['exercises', 'user:id,name'])
            ->withCount('copies as assigned_count')
            ->findOrFail($id);

        // Alunos que receberam este treino (cópias)
        $assignments = CustomWorkout::where('template_id', $id)
            ->whereIn('user_id', $userIds)
            ->with('user:id,name,email')
            ->latest()
            ->get()
            ->map(fn ($a) => [
                'assignment_id' => $a->id,
                'user_id'       => $a->user_id,
                'user_name'     => $a->user?->name  ?? '—',
                'user_email'    => $a->user?->email ?? '',
                'assigned_at'   => $a->created_at?->format('Y-m-d'),
            ]);

        return response()->json([
            'id'             => $workout->id,
            'name'           => $workout->name,
            'description'    => $workout->description,
            'level'          => $workout->level,
            'duration'       => $workout->duration,
            'is_generated'   => $workout->is_generated,
            'created_by'     => $workout->is_generated ? 'IA GymUp' : ($workout->user?->name ?? '—'),
            'assigned_count' => $workout->assigned_count,
            'exercises'      => $workout->exercises->map(fn ($e) => [
                'id'           => $e->id,
                'name'         => $e->name,
                'muscle_group' => $e->muscle_group,
                'image_url'    => $e->image_url,
                'sets'         => $e->pivot->sets,
                'reps'         => $e->pivot->reps,
                'rest'         => $e->pivot->rest,
            ]),
            'assignments' => $assignments,
        ]);
    }

    /**
     * Cria um novo treino-modelo na biblioteca da academia.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'                    => 'required|string|max:255',
            'description'             => 'nullable|string',
            'level'                   => 'nullable|string|max:50',
            'duration'                => 'nullable|integer|min:1|max:300',
            'exercises'               => 'required|array|min:1',
            'exercises.*.exercise_id' => 'required|exists:exercises,id',
            'exercises.*.sets'        => 'required|integer|min:1|max:20',
            'exercises.*.reps'        => 'required|integer|min:1|max:100',
            'exercises.*.rest'        => 'nullable|integer|min:0|max:600',
        ]);

        $workout = CustomWorkout::create([
            'user_id'      => $request->user()->id,
            'name'         => $request->name,
            'description'  => $request->description,
            'level'        => $request->level,
            'duration'     => $request->duration,
            'is_generated' => false,
            'is_template'  => true,
        ]);

        $syncData = [];
        foreach ($request->exercises as $item) {
            $syncData[$item['exercise_id']] = [
                'sets' => $item['sets'],
                'reps' => $item['reps'],
                'rest' => $item['rest'] ?? 60,
            ];
        }
        $workout->exercises()->sync($syncData);
        $workout->load('user:id,name');

        return response()->json(
            $this->formatWorkout($workout->loadCount(['exercises', 'copies as assigned_count'])),
            201
        );
    }

    /**
     * Atualiza um treino-modelo (metadados + exercícios).
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $gymId   = $request->user()->activeGymId();
        $userIds = User::where('gym_id', $gymId)->pluck('id');

        $workout = CustomWorkout::whereIn('user_id', $userIds)
            ->where('is_template', true)
            ->findOrFail($id);

        $request->validate([
            'name'                    => 'sometimes|required|string|max:255',
            'description'             => 'nullable|string',
            'level'                   => 'nullable|string|max:50',
            'duration'                => 'nullable|integer|min:1|max:300',
            'exercises'               => 'sometimes|required|array|min:1',
            'exercises.*.exercise_id' => 'required|exists:exercises,id',
            'exercises.*.sets'        => 'required|integer|min:1|max:20',
            'exercises.*.reps'        => 'required|integer|min:1|max:100',
            'exercises.*.rest'        => 'nullable|integer|min:0|max:600',
        ]);

        $workout->update($request->only(['name', 'description', 'level', 'duration']));

        if ($request->has('exercises')) {
            $syncData = [];
            foreach ($request->exercises as $item) {
                $syncData[$item['exercise_id']] = [
                    'sets' => $item['sets'],
                    'reps' => $item['reps'],
                    'rest' => $item['rest'] ?? 60,
                ];
            }
            $workout->exercises()->sync($syncData);
        }

        return response()->json(['message' => 'Treino atualizado com sucesso.']);
    }

    /**
     * Exclui um treino-modelo (e todas as cópias atribuídas).
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $gymId   = $request->user()->activeGymId();
        $userIds = User::where('gym_id', $gymId)->pluck('id');

        $workout = CustomWorkout::whereIn('user_id', $userIds)
            ->where('is_template', true)
            ->findOrFail($id);

        // Remove cópias dos alunos junto com o modelo
        CustomWorkout::where('template_id', $id)->delete();
        $workout->delete();

        return response()->json(['message' => 'Treino e todas as atribuições foram removidos.']);
    }

    /**
     * Atribui o treino-modelo a múltiplos alunos (cria cópias independentes).
     */
    public function assign(Request $request, int $id): JsonResponse
    {
        $gymId   = $request->user()->activeGymId();
        $userIds = User::where('gym_id', $gymId)->pluck('id');

        $template = CustomWorkout::whereIn('user_id', $userIds)
            ->where('is_template', true)
            ->with('exercises')
            ->findOrFail($id);

        $request->validate([
            'user_ids'   => 'required|array|min:1',
            'user_ids.*' => 'integer',
        ]);

        $validUserIds = User::whereIn('id', $request->user_ids)
            ->where('gym_id', $gymId)
            ->where('role', 'user')
            ->pluck('id');

        $pivotData = [];
        foreach ($template->exercises as $exercise) {
            $pivotData[$exercise->id] = [
                'sets' => $exercise->pivot->sets,
                'reps' => $exercise->pivot->reps,
                'rest' => $exercise->pivot->rest,
            ];
        }

        $assigned = 0;
        $skipped  = 0;

        foreach ($validUserIds as $userId) {
            $alreadyHas = CustomWorkout::where('user_id', $userId)
                ->where('template_id', $template->id)
                ->exists();

            if ($alreadyHas) { $skipped++; continue; }

            $copy = CustomWorkout::create([
                'user_id'      => $userId,
                'name'         => $template->name,
                'description'  => $template->description,
                'level'        => $template->level,
                'duration'     => $template->duration,
                'is_generated' => false,
                'is_template'  => false,
                'template_id'  => $template->id,
            ]);

            $copy->exercises()->sync($pivotData);
            $assigned++;
        }

        $message = match (true) {
            $assigned > 0 && $skipped > 0 => "{$assigned} aluno(s) receberam o treino. {$skipped} já possuíam este modelo.",
            $assigned > 0                  => "{$assigned} aluno(s) receberam o treino com sucesso.",
            default                        => "Todos os alunos selecionados já possuem este treino.",
        };

        return response()->json(['message' => $message, 'assigned' => $assigned, 'skipped' => $skipped]);
    }

    /**
     * Remove a atribuição de um aluno específico (deleta a cópia).
     */
    public function removeAssignment(Request $request, int $templateId, int $assignmentId): JsonResponse
    {
        $gymId   = $request->user()->activeGymId();
        $userIds = User::where('gym_id', $gymId)->pluck('id');

        // Garante que o template pertence à academia
        CustomWorkout::whereIn('user_id', $userIds)
            ->where('is_template', true)
            ->findOrFail($templateId);

        $assignment = CustomWorkout::where('id', $assignmentId)
            ->where('template_id', $templateId)
            ->whereIn('user_id', $userIds)
            ->firstOrFail();

        $assignment->delete();

        return response()->json(['message' => 'Atribuição removida com sucesso.']);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function formatWorkout(CustomWorkout $w): array
    {
        return [
            'id'             => $w->id,
            'name'           => $w->name,
            'description'    => $w->description,
            'level'          => $w->level,
            'duration'       => $w->duration,
            'exercises_count' => $w->exercises_count,
            'assigned_count' => $w->assigned_count ?? 0,
            'is_generated'   => $w->is_generated,
            'is_template'    => true,
            'created_by'     => $w->is_generated ? 'IA GymUp' : ($w->user?->name ?? '—'),
            'created_at'     => $w->created_at?->format('Y-m-d'),
        ];
    }
}
