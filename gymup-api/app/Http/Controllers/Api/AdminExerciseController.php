<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exercise;
use App\Models\ExerciseSubstitution;
use App\Models\GifFeedback;
use App\Services\ExerciseGifCatalog;
use App\Services\GifSuggestionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class AdminExerciseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $search  = trim($request->query('search', ''));
        $type    = trim($request->query('type', ''));
        $popular = $request->boolean('popular');
        $limit   = max(0, (int) $request->query('limit', 0));

        $columns = [
            'exercises.id', 'exercises.name', 'exercises.type', 'exercises.muscle_group',
            'exercises.default_rest', 'exercises.gif_file', 'exercises.description',
            'exercises.primary_muscle', 'exercises.secondary_muscles', 'exercises.execution_steps',
            'exercises.common_mistakes', 'exercises.tips', 'exercises.gym_id',
            'exercises.gif_confidence', 'exercises.gif_is_auto',
        ];

        $query = Exercise::query()
            ->when($search, fn ($q) => $q->where('exercises.name', 'ilike', "%{$search}%"))
            ->when($type,   fn ($q) => $q->where('exercises.type', $type));

        // When popular=1 and no text search, rank by usage across both workout tables
        if ($popular && !$search) {
            $query
                ->leftJoinSub(
                    DB::table('custom_workout_exercise')
                        ->selectRaw('exercise_id, COUNT(*) AS cwe_count')
                        ->groupBy('exercise_id'),
                    'cwe', 'exercises.id', '=', 'cwe.exercise_id'
                )
                ->leftJoinSub(
                    DB::table('workout_exercises')
                        ->selectRaw('exercise_id, COUNT(*) AS we_count')
                        ->groupBy('exercise_id'),
                    'we', 'exercises.id', '=', 'we.exercise_id'
                )
                ->orderByRaw('COALESCE(cwe.cwe_count, 0) + COALESCE(we.we_count, 0) DESC')
                ->orderBy('exercises.name');
        } else {
            $query->orderBy('exercises.muscle_group')->orderBy('exercises.name');
        }

        if ($limit > 0) {
            $query->limit($limit);
        }

        $exercises = $query->get($columns);

        return response()->json(['exercises' => $exercises]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'               => 'required|string|max:255',
            'type'               => 'nullable|in:strength,cardio,mobility',
            'muscle_group'       => 'required|string|max:100',
            'description'        => 'nullable|string',
            'gif_file'           => 'nullable|string|max:500',
            'default_rest'       => 'nullable|integer|min:0',
            'primary_muscle'     => 'nullable|string|max:100',
            'secondary_muscles'  => 'nullable|array',
            'secondary_muscles.*'=> 'string|max:100',
            'execution_steps'    => 'nullable|array',
            'execution_steps.*'  => 'string',
            'common_mistakes'    => 'nullable|array',
            'common_mistakes.*'  => 'string',
            'tips'               => 'nullable|array',
            'tips.*'             => 'string',
        ]);

        $exercise = Exercise::create([
            'name'              => $request->name,
            'type'              => $request->input('type', 'strength'),
            'muscle_group'      => $request->muscle_group,
            'description'       => $request->description,
            'gif_file'          => $request->gif_file,
            'default_rest'      => $request->input('default_rest', 60),
            'gym_id'            => $request->user()->gym_id,
            'created_by'        => $request->user()->id,
            'primary_muscle'    => $request->primary_muscle,
            'secondary_muscles' => $request->secondary_muscles,
            'execution_steps'   => $request->execution_steps,
            'common_mistakes'   => $request->common_mistakes,
            'tips'              => $request->tips,
        ]);

        return response()->json(['exercise' => $exercise], 201);
    }

    public function duplicate(Request $request, int $id): JsonResponse
    {
        $exercise = Exercise::find($id);

        if (!$exercise) {
            return response()->json(['message' => 'Exercício não encontrado.'], 404);
        }

        $copy = $exercise->replicate();
        $copy->name       = 'Cópia de ' . $exercise->name;
        $copy->gym_id     = $request->user()->gym_id;
        $copy->created_by = $request->user()->id;
        $copy->save();

        return response()->json(['exercise' => $copy], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        if ($request->user()->role === 'trainer') {
            return response()->json(['message' => 'Treinadores não podem editar exercícios da biblioteca. Use a duplicação para criar uma variação.'], 403);
        }

        $request->validate([
            'name'               => 'sometimes|required|string|max:255',
            'type'               => 'nullable|in:strength,cardio,mobility',
            'muscle_group'       => 'sometimes|required|string|max:100',
            'description'        => 'nullable|string',
            'gif_file'           => 'nullable|string|max:500',
            'default_rest'       => 'nullable|integer|min:0',
            'primary_muscle'     => 'nullable|string|max:100',
            'secondary_muscles'  => 'nullable|array',
            'secondary_muscles.*'=> 'string|max:100',
            'execution_steps'    => 'nullable|array',
            'execution_steps.*'  => 'string',
            'common_mistakes'    => 'nullable|array',
            'common_mistakes.*'  => 'string',
            'tips'               => 'nullable|array',
            'tips.*'             => 'string',
        ]);

        $exercise = Exercise::find($id);

        if (!$exercise) {
            return response()->json(['message' => 'Exercício não encontrado.'], 404);
        }

        $exercise->update($request->only([
            'name', 'type', 'muscle_group', 'description', 'gif_file', 'default_rest',
            'primary_muscle', 'secondary_muscles', 'execution_steps', 'common_mistakes', 'tips',
        ]));

        return response()->json(['exercise' => $exercise]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        if ($request->user()->role === 'trainer') {
            return response()->json(['message' => 'Treinadores não podem excluir exercícios da biblioteca.'], 403);
        }

        $exercise = Exercise::find($id);

        if (!$exercise) {
            return response()->json(['message' => 'Exercício não encontrado.'], 404);
        }

        $exercise->delete();

        return response()->json(['message' => 'Exercício excluído com sucesso.']);
    }

    /**
     * GET /api/admin/exercises/gif-mapping
     * Returns all exercises sorted for GIF review: missing first, then low-confidence auto, then manual.
     */
    public function gifMapping(): JsonResponse
    {
        $exercises = Exercise::orderBy('muscle_group')->orderBy('name')
            ->get(['id', 'name', 'muscle_group', 'type', 'gif_file', 'gif_confidence', 'gif_is_auto'])
            ->map(function (Exercise $e) {
                if (! $e->gif_file) {
                    $status = 'missing';
                    $sortKey = 0;
                } elseif ($e->gif_is_auto === false) {
                    $status = 'manual';
                    $sortKey = 2;
                } else {
                    $status = 'auto';
                    $sortKey = 1;
                }

                return [
                    'id'             => $e->id,
                    'name'           => $e->name,
                    'muscle_group'   => $e->muscle_group,
                    'type'           => $e->type,
                    'gif_file'       => $e->gif_file,
                    'gif_url'        => $e->gif_url,
                    'gif_confidence' => $e->gif_confidence,
                    'gif_is_auto'    => $e->gif_is_auto,
                    'status'         => $status,
                    '_sort'          => $sortKey,
                    '_confidence'    => $e->gif_confidence ?? 0,
                ];
            })
            ->sortBy([
                ['_sort', 'asc'],
                ['_confidence', 'asc'],
                ['name', 'asc'],
            ])
            ->values()
            ->map(fn ($e) => array_diff_key($e, ['_sort' => 0, '_confidence' => 0]));

        return response()->json(['exercises' => $exercises]);
    }

    /**
     * GET /api/admin/exercises/available-gifs
     * Lists all GIF files in storage with usage count per file.
     */
    public function availableGifs(): JsonResponse
    {
        // Build usage map: gif_file path → count of exercises using it
        $usageMap = Exercise::whereNotNull('gif_file')
            ->selectRaw('gif_file, count(*) as cnt')
            ->groupBy('gif_file')
            ->pluck('cnt', 'gif_file')
            ->toArray();

        $gifs = [];

        foreach (app(ExerciseGifCatalog::class)->all() as $relative) {
            $folder = dirname($relative);
            $filename = basename($relative);

            $gifs[] = [
                'path'        => $relative,
                'url'         => Exercise::gifPathToUrl($relative),
                'folder'      => $folder,
                'filename'    => pathinfo($filename, PATHINFO_FILENAME),
                'usage_count' => $usageMap[$relative] ?? 0,
            ];
        }

        // Sort: folder ASC, filename ASC
        usort($gifs, fn ($a, $b) => [$a['folder'], $a['filename']] <=> [$b['folder'], $b['filename']]);

        return response()->json(['gifs' => $gifs]);
    }

    /**
     * POST /api/admin/exercises/{id}/link-gif
     * Manually links (or clears) a GIF for an exercise.
     * Sets gif_is_auto = false to protect from future auto-overrides.
     * Logs the selection to gif_feedback and busts the suggestion cache.
     */
    public function linkGif(Request $request, int $id, GifSuggestionService $suggester): JsonResponse
    {
        $request->validate([
            'gif_file' => 'nullable|string|max:500',
        ]);

        $exercise = Exercise::find($id);

        if (! $exercise) {
            return response()->json(['message' => 'Exercício não encontrado.'], 404);
        }

        $gifFile = $request->input('gif_file');

        // Validate the file physically exists before saving
        if ($gifFile !== null) {
            if (! Storage::disk('public')->exists('exercises/' . $gifFile)) {
                return response()->json(['message' => 'Arquivo GIF não encontrado no servidor.'], 422);
            }
        }

        $exercise->update([
            'gif_file'       => $gifFile,
            'gif_confidence' => null,
            'gif_is_auto'    => false,
        ]);

        // Log admin selection for future weight improvements
        if ($gifFile !== null) {
            GifFeedback::create([
                'exercise_id'              => $exercise->id,
                'exercise_name_normalized' => $suggester->normalize($exercise->name),
                'selected_gif'             => $gifFile,
            ]);
        }

        // Bust the suggestion cache so the next call re-scores with the new feedback row
        $suggester->bust($exercise);

        return response()->json([
            'exercise' => [
                'id'             => $exercise->id,
                'gif_file'       => $exercise->gif_file,
                'gif_url'        => $exercise->gif_url,
                'gif_confidence' => $exercise->gif_confidence,
                'gif_is_auto'    => $exercise->gif_is_auto,
            ],
        ]);
    }

    /**
     * GET /api/admin/exercises/{id}/suggest-gifs
     * Returns the top 3 GIF candidates for an exercise using fuzzy name matching.
     * Scans only the muscle-group folder when known; falls back to all folders.
     */
    public function suggestGifs(int $id, GifSuggestionService $suggester): JsonResponse
    {
        $exercise = Exercise::find($id);

        if (! $exercise) {
            return response()->json(['message' => 'Exercício não encontrado.'], 404);
        }

        $suggestions = $suggester->suggest($exercise, limit: 3);

        return response()->json([
            'exercise'    => ['id' => $exercise->id, 'name' => $exercise->name],
            'suggestions' => $suggestions,
        ]);
    }

    /**
     * GET /api/admin/exercises/{id}/substitutions
     */
    public function substitutions(int $id): JsonResponse
    {
        $exercise = Exercise::find($id);

        if (!$exercise) {
            return response()->json(['message' => 'Exercício não encontrado.'], 404);
        }

        $subs = $exercise->substitutions()
            ->with('substitute:id,name,muscle_group,type,image_url')
            ->get()
            ->map(fn ($s) => [
                'id'           => $s->substitute->id,
                'name'         => $s->substitute->name,
                'muscle_group' => $s->substitute->muscle_group,
                'type'         => $s->substitute->type ?? 'strength',
                'image_url'    => $s->substitute->image_url,
                'priority'     => $s->priority,
            ]);

        return response()->json(['substitutions' => $subs]);
    }

    /**
     * POST /api/admin/exercises/{id}/substitutions
     */
    public function addSubstitution(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'substitute_exercise_id' => 'required|integer|exists:exercises,id',
            'priority'               => 'nullable|integer|min:0',
        ]);

        if ($request->substitute_exercise_id === $id) {
            return response()->json(['message' => 'Um exercício não pode ser substituto de si mesmo.'], 422);
        }

        $sub = ExerciseSubstitution::firstOrCreate(
            [
                'exercise_id'            => $id,
                'substitute_exercise_id' => $request->substitute_exercise_id,
            ],
            ['priority' => $request->input('priority', 0)]
        );

        return response()->json(['substitution' => $sub], 201);
    }

    /**
     * DELETE /api/admin/exercises/{id}/substitutions/{substituteId}
     */
    public function removeSubstitution(int $id, int $substituteId): JsonResponse
    {
        ExerciseSubstitution::where('exercise_id', $id)
            ->where('substitute_exercise_id', $substituteId)
            ->delete();

        return response()->json(['message' => 'Substituição removida.']);
    }

}
