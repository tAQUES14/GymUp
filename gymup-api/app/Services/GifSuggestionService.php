<?php

namespace App\Services;

use App\Models\Exercise;
use App\Models\GifFeedback;
use Illuminate\Support\Facades\Cache;


class GifSuggestionService
{
    public function __construct(private readonly ExerciseGifCatalog $catalog) {}

    private const ALGO_VERSION = 'v5';

    /** Maps exercise.muscle_group to the GIF storage folder name. */
    private const FOLDER_MAP = [
        'Peito'       => 'PEITORAL',
        'Costas'      => 'COSTAS E TRAPÉZIO',
        'Bíceps'      => 'BÍCEPS e ANTEBRAÇO',
        'Ombros'      => 'DELTÓIDES',
        'Pernas'      => 'MEMBROS INFERIORES E GLÚTEOS',
        'Core'        => 'ABDOMEN CORE',
        'Abdômen'     => 'ABDOMEN CORE',
        'Tríceps'     => 'TRÍCEPS',
        'Panturrilha' => 'PANTURRILHA',
    ];

    private const STOPWORDS = [
        'com', 'de', 'da', 'do', 'no', 'na', 'para',
        'e', 'a', 'o', 'as', 'os', 'dos', 'das', 'em',
        'ao', 'aos', 'um', 'uma', 'the', 'and', 'with', 'on',
    ];

    /** English → Portuguese fitness-term translations applied word-by-word in normalize(). */
    private const TERM_MAP = [
        'row'           => 'remada',
        'curl'          => 'rosca',
        'pulldown'      => 'puxada',
        'pullup'        => 'barra',
        'pushup'        => 'flexao',
        'squat'         => 'agachamento',
        'press'         => 'supino',
        'fly'           => 'crucifixo',
        'flye'          => 'crucifixo',
        'extension'     => 'extensao',
        'flexion'       => 'flexao',
        'raise'         => 'elevacao',
        'deadlift'      => 'terra',
        'lunge'         => 'afundo',
        'crunch'        => 'abdominal',
        'plank'         => 'prancha',
        'dip'           => 'mergulho',
        'shrug'         => 'encolhimento',
        'calf'          => 'panturrilha',
        'leg'           => 'perna',
        'chest'         => 'peito',
        'back'          => 'costas',
        'shoulder'      => 'ombro',
        'tricep'        => 'triceps',
        'triceps'       => 'triceps',
        'bicep'         => 'biceps',
        'biceps'        => 'biceps',
        'bench'         => 'supino',
        'cable'         => 'cabo',
        'dumbbell'      => 'halter',
        'barbell'       => 'barra',
        'machine'       => 'maquina',
        'seated'        => 'sentado',
        'standing'      => 'em pe',
        'incline'       => 'inclinado',
        'decline'       => 'declinado',
        'lateral'       => 'lateral',
        'front'         => 'frontal',
        'reverse'       => 'inverso',
        'hammer'        => 'martelo',
        'concentration' => 'concentrado',
        'overhead'      => 'acima da cabeca',
        'romanian'      => 'romeno',
        'glute'         => 'gluteo',
        'hip'           => 'quadril',
        'knee'          => 'joelho',
        'neck'          => 'pescoco',
        'wrist'         => 'pulso',
        'forearm'       => 'antebraco',
        'trapezius'     => 'trapezio',
        'trap'          => 'trapezio',
        'lat'           => 'latissimo',
        'lats'          => 'latissimo',
        'pec'           => 'peitoral',
        'pecs'          => 'peitoral',
        'abs'           => 'abdominal',
        'ab'            => 'abdominal',
    ];

    /**
     * Keywords that add +8 to the score when they appear in BOTH the normalized
     * exercise name and the normalized GIF filename.
     * Chosen because they meaningfully discriminate between exercises that share
     * the same base movement (e.g. "remada curvada" vs "remada cavalinho").
     */
    private const BOOST_KEYWORDS = [
        'curvada', 'unilateral', 'barra', 'halter', 'cabo', 'maquina',
        'inclinado', 'declinado', 'sentado', 'romeno', 'martelo',
        'concentrado', 'inverso', 'lateral', 'frontal', 'alternado',
        'bilateral', 'supinado', 'pronado', 'neutro',
    ];

    /**
     * Penalty rules: if the exercise name contains $key, deduct 15 points for
     * each $bad word found in the GIF filename.
     * Prevents anatomically wrong cross-category suggestions.
     */
    private const PENALTY_RULES = [
        'flexao'      => ['quadril', 'abdomen', 'agachamento'],
        'rosca'       => ['perna', 'agachamento', 'gluteo'],
        'agachamento' => ['triceps', 'biceps', 'rosca'],
        'remada'      => ['agachamento', 'perna'],
        'supino'      => ['agachamento', 'perna', 'abdominal'],
        'elevacao'    => ['agachamento', 'perna'],
        'extensao'    => ['agachamento', 'biceps'],
        'abdominal'   => ['agachamento', 'supino', 'remada'],
    ];

    // ── Public API ─────────────────────────────────────────────────────────────

    /**
     * Return the top $limit GIF suggestions for the given exercise.
     * Results are cached for 24 h under a key that includes ALGO_VERSION.
     *
     * @return array<int, array{file:string, url:string, score:int, confidence:string, folder:string, fallback?:bool}>
     */
    public function suggest(Exercise $exercise, int $limit = 3): array
    {
        return Cache::remember(
            $this->cacheKeyFor($exercise),
            86400,
            fn () => $this->computeSuggestions($exercise, $limit),
        );
    }

    /**
     * Invalidate the cached suggestions for an exercise.
     * Call this after a manual GIF selection so the next request re-scores
     * with the new feedback row already in the database.
     */
    public function bust(Exercise $exercise): void
    {
        Cache::forget($this->cacheKeyFor($exercise));
    }

    /**
     * Normalize a string for matching:
     *   1. transliterate accents → ASCII
     *   2. lowercase
     *   3. hyphens / underscores → spaces
     *   4. strip non-alpha chars
     *   5. apply English→Portuguese term translations (word by word)
     *   6. collapse whitespace
     */
    public function normalize(string $text): string
    {
        $text = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $text) ?: $text;
        $text = strtolower($text);
        $text = str_replace(['-', '_'], ' ', $text);
        $text = (string) preg_replace('/[^a-z\s]/', '', $text);
        $text = trim((string) preg_replace('/\s+/', ' ', $text));

        $words = explode(' ', $text);
        $words = array_map(fn ($w) => self::TERM_MAP[$w] ?? $w, $words);

        return implode(' ', $words);
    }

    // ── Cache key ──────────────────────────────────────────────────────────────

    private function cacheKeyFor(Exercise $exercise): string
    {
        return 'gif_suggestions.' . sha1(
            $this->normalize($exercise->name)
            . ':' . ($exercise->muscle_group ?? '')
            . ':' . self::ALGO_VERSION
        );
    }

    // ── Core computation ───────────────────────────────────────────────────────

    private function computeSuggestions(Exercise $exercise, int $limit): array
    {
        $candidates   = $this->getCandidates($exercise->muscle_group);
        $normExercise = $this->normalize($exercise->name);

        // No folder found at all → go straight to historical fallback
        if (empty($candidates)) {
            return $this->popularFallback($exercise->muscle_group, $limit);
        }

        // Load feedback in one query; flip to array for O(1) lookup
        $feedbackSet = $this->loadFeedback($normExercise);

        $scored = [];

        foreach ($candidates as $relative => $meta) {
            $normFile = $this->normalize($meta['filename']);

            [$base, $boost, $penalty] = $this->scoreBreakdown($normExercise, $normFile);
            $fb  = $this->feedbackBoost($relative, $feedbackSet);
            $raw = max(0.0, min(100.0, $base + $boost + $penalty + $fb));

            $score = (int) round($raw);

            $scored[] = [
                'file'       => $relative,
                'url'        => Exercise::gifPathToUrl($relative),
                'score'      => $score,
                'confidence' => $this->confidenceLabel($score, hadPenalty: $penalty < 0.0),
                'folder'     => $meta['folder'],
            ];
        }

        usort($scored, fn ($a, $b) => $b['score'] <=> $a['score']);
        $results = array_slice($scored, 0, $limit);

        // Fallback: nothing useful was scored — suggest by historical popularity
        if (empty($results) || $results[0]['score'] === 0) {
            return $this->popularFallback($exercise->muscle_group, $limit);
        }

        return $results;
    }

    // ── Scoring ────────────────────────────────────────────────────────────────

    /**
     * Return [base, keywordBoost, penalty] as three separate floats so the
     * caller can inspect each component (needed for the confidence guard).
     *
     * @return array{float, float, float}
     */
    private function scoreBreakdown(string $normExercise, string $normFile): array
    {
        $tokA    = $this->tokenize($normExercise);
        $tokB    = $this->tokenize($normFile);
        $jaccard = $this->jaccardScore($tokA, $tokB);

        // similar_text is O(n²) — skip it when Jaccard shows an obvious mismatch
        $similar = $jaccard > 30.0 ? $this->similarTextScore($normExercise, $normFile) : 0.0;

        $base    = max($jaccard, $similar);
        $boost   = $this->keywordBoost($normExercise, $normFile);
        $penalty = $this->applyPenalty($normExercise, $normFile);

        return [$base, $boost, $penalty];
    }

    /**
     * Add +8 for each discriminating keyword that appears in both strings.
     */
    private function keywordBoost(string $normExercise, string $normFile): float
    {
        $boost = 0.0;

        foreach (self::BOOST_KEYWORDS as $word) {
            if (str_contains($normExercise, $word) && str_contains($normFile, $word)) {
                $boost += 8.0;
            }
        }

        return $boost;
    }

    /**
     * Subtract 15 points for each cross-category mismatch found.
     */
    private function applyPenalty(string $normExercise, string $normFile): float
    {
        $penalty = 0.0;

        foreach (self::PENALTY_RULES as $key => $bads) {
            if (! str_contains($normExercise, $key)) {
                continue;
            }

            foreach ($bads as $bad) {
                if (str_contains($normFile, $bad)) {
                    $penalty -= 15.0;
                }
            }
        }

        return $penalty;
    }

    /**
     * Add +15 if an admin has previously selected this exact GIF for this
     * normalized exercise name. Turns historical human choices into a signal.
     *
     * @param array<string, int> $feedbackSet  [ gif_path => _ ]  (pre-flipped for O(1) lookup)
     */
    private function feedbackBoost(string $relative, array $feedbackSet): float
    {
        return isset($feedbackSet[$relative]) ? 15.0 : 0.0;
    }

    /**
     * Confidence label with penalty guard.
     *
     * Guard: even if the clamped score reaches 80+, we cap at 'medium' when a
     * semantic penalty was applied — the match is suspicious regardless of the
     * final number.
     *
     *   score ≥ 80 AND no penalty → "high"
     *   score ≥ 60               → "medium"
     *   otherwise                → "low"
     */
    private function confidenceLabel(int $score, bool $hadPenalty = false): string
    {
        if ($score >= 80 && ! $hadPenalty) {
            return 'high';
        }

        if ($score >= 60) {
            return 'medium';
        }

        return 'low';
    }

    // ── Feedback helpers ───────────────────────────────────────────────────────

    /**
     * Load all GIFs previously chosen for this normalized exercise name.
     * Returns a flipped array for O(1) existence checks.
     *
     * @return array<string, int>  [ selected_gif => array_index ]
     */
    private function loadFeedback(string $normExercise): array
    {
        return GifFeedback::where('exercise_name_normalized', $normExercise)
            ->pluck('selected_gif')
            ->flip()
            ->all();
    }

    /**
     * Fallback: when fuzzy scoring yields nothing useful, return the most
     * frequently selected GIFs for this muscle group from the feedback log.
     * Falls back to globally popular GIFs if the group has no history yet.
     *
     * @return array<int, array{file:string, url:string, score:int, confidence:string, folder:string, fallback:bool}>
     */
    private function popularFallback(?string $muscleGroup, int $limit): array
    {
        $folder = $muscleGroup ? (self::FOLDER_MAP[$muscleGroup] ?? null) : null;

        $query = GifFeedback::selectRaw('selected_gif, count(*) as cnt')
            ->groupBy('selected_gif')
            ->orderByDesc('cnt')
            ->limit($limit);

        if ($folder) {
            $query->where('selected_gif', 'like', $folder . '/%');
        }

        return $query
            ->get()
            ->map(fn ($row) => [
                'file'       => $row->selected_gif,
                'url'        => Exercise::gifPathToUrl($row->selected_gif),
                'score'      => 0,
                'confidence' => 'low',
                'folder'     => $folder ?? dirname($row->selected_gif),
                'fallback'   => true,
            ])
            ->all();
    }

    // ── Text scoring primitives ────────────────────────────────────────────────

    /** @return string[] */
    private function tokenize(string $normalized): array
    {
        $tokens = explode(' ', $normalized);

        return array_values(array_filter(
            $tokens,
            fn ($t) => $t !== '' && ! in_array($t, self::STOPWORDS, true),
        ));
    }

    private function jaccardScore(array $a, array $b): float
    {
        if (empty($a) && empty($b)) {
            return 100.0;
        }

        $intersection = count(array_intersect($a, $b));
        $union        = count(array_unique(array_merge($a, $b)));

        return $union > 0 ? ($intersection / $union) * 100.0 : 0.0;
    }

    private function similarTextScore(string $a, string $b): float
    {
        if ($a === '' && $b === '') {
            return 100.0;
        }

        similar_text($a, $b, $percent);

        return (float) $percent;
    }

    // ── File scanning ──────────────────────────────────────────────────────────

    /**
     * Candidates to score. Scans only the muscle-group folder when known;
     * falls back to all non-bonus folders otherwise.
     *
     * @return array<string, array{filename: string, folder: string}>
     */
    private function getCandidates(?string $muscleGroup): array
    {
        $expectedFolder = $muscleGroup ? (self::FOLDER_MAP[$muscleGroup] ?? null) : null;

        if ($expectedFolder) {
            return $this->scanFolder($expectedFolder);
        }

        $candidates = [];

        foreach ($this->catalog->all() as $relative) {
            $folder = dirname($relative);

            if (stripos($folder, 'bonus') !== false || stripos($folder, 'gifs -') !== false) {
                continue;
            }

            $filename = pathinfo(basename($relative), PATHINFO_FILENAME);
            $candidates[$relative] = [
                'filename' => $filename,
                'folder'   => $folder,
            ];
        }

        return $candidates;
    }

    /** @return array<string, array{filename: string, folder: string}> */
    private function scanFolder(string $folder): array
    {
        $result = [];

        foreach ($this->catalog->inFolder($folder) as $relative) {
            $result[$relative] = [
                'filename' => pathinfo(basename($relative), PATHINFO_FILENAME),
                'folder'   => $folder,
            ];
        }

        return $result;
    }
}
