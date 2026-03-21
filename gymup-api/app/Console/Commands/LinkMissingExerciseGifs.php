<?php

namespace App\Console\Commands;

use App\Models\Exercise;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

class LinkMissingExerciseGifs extends Command
{
    protected $signature   = 'exercises:link-missing-gifs
                                {--dry-run : Simulate matches without saving}
                                {--force : Also re-link exercises that already have a gif_file}';

    protected $description = 'Links GIF files to exercises that still have gif_file = null';

    /** Minimum score (0–100) to consider a candidate a match. */
    private const SCORE_THRESHOLD = 65.0;

    /**
     * If the top two candidates both clear the threshold and are within this
     * many points of each other, the match is considered ambiguous and skipped.
     */
    private const AMBIGUITY_DELTA = 8.0;

    private const STOPWORDS = [
        'com', 'de', 'da', 'do', 'no', 'na', 'para',
        'e', 'a', 'o', 'as', 'os', 'dos', 'das', 'em',
        'ao', 'aos', 'um', 'uma',
    ];

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

    public function handle(): int
    {
        $dryRun = $this->option('dry-run');
        $force  = $this->option('force');

        [$globalMap, $byFolder] = $this->buildGifMaps();

        $totalGifs = array_sum(array_map('count', $byFolder));
        $this->line("  Found <comment>{$totalGifs}</comment> GIF files across " . count($byFolder) . ' folders.');
        $this->newLine();

        // Never process manually-mapped exercises (gif_is_auto = false), even with --force
        $query = $force
            ? Exercise::where(fn ($q) => $q->whereNull('gif_is_auto')->orWhere('gif_is_auto', true))
            : Exercise::whereNull('gif_file');

        $exercises = $query->orderBy('muscle_group')->orderBy('name')->get();

        $this->line("  Processing <comment>{$exercises->count()}</comment> exercise(s)...");
        $this->newLine();

        $linked    = 0;
        $ambiguous = [];
        $unmatched = [];

        foreach ($exercises as $exercise) {
            $result = $this->findBestMatch($exercise, $globalMap, $byFolder);

            if ($result === null) {
                $unmatched[] = "{$exercise->name} [{$exercise->muscle_group}]";
                continue;
            }

            if ($result['ambiguous']) {
                $ambiguous[] = $exercise->name
                    . " [{$exercise->muscle_group}]"
                    . " — top: {$result['path']} ({$result['score']}%)"
                    . ", runner-up: {$result['runner_up']} ({$result['runner_up_score']}%)";
                continue;
            }

            if (! $dryRun) {
                $exercise->update([
                    'gif_file'       => $result['path'],
                    'gif_confidence' => (int) round($result['score']),
                    'gif_is_auto'    => true,
                ]);
            }

            $this->line("  <info>✔</info> {$exercise->name}  →  {$result['path']} <fg=gray>({$result['score']}%)</>");
            $linked++;
        }

        // ── Summary ─────────────────────────────────────────────────────────
        $this->newLine();
        $this->line("  <info>Linked:             {$linked}</info>");
        $this->line("  <comment>Skipped (ambiguous): " . count($ambiguous) . '</comment>');
        $this->line('  <fg=red>Unmatched:          ' . count($unmatched) . '</>');

        if (! empty($ambiguous)) {
            $this->newLine();
            $this->line('  <comment>Ambiguous — review manually:</comment>');
            foreach ($ambiguous as $entry) {
                $this->line("    - {$entry}");
            }
        }

        if (! empty($unmatched)) {
            $this->newLine();
            $this->line('  <comment>Still unmatched:</comment>');
            foreach ($unmatched as $name) {
                $this->line("    - {$name}");
            }
        }

        if ($dryRun) {
            $this->newLine();
            $this->warn('  Dry run — no changes were saved.');
        }

        return self::SUCCESS;
    }

    /**
     * Find the best GIF match for an exercise, respecting muscle-group folder preference.
     *
     * Returns an array with:
     *   path, score, ambiguous (bool), runner_up, runner_up_score
     * or null if nothing clears the threshold.
     */
    private function findBestMatch(Exercise $exercise, array $globalMap, array $byFolder): ?array
    {
        $expectedFolder   = self::FOLDER_MAP[$exercise->muscle_group] ?? null;
        $folderKey        = $expectedFolder ? Str::slug($expectedFolder) : null;
        $folderCandidates = $folderKey ? ($byFolder[$folderKey] ?? []) : [];

        // Score every candidate; folder candidates scored first so ties favour them
        $scored = [];

        foreach ($folderCandidates as $path) {
            $filename           = pathinfo($path, PATHINFO_FILENAME);
            $scored[$path]      = $this->score($exercise->name, $filename);
        }

        foreach ($globalMap as $path) {
            if (! isset($scored[$path])) {            // don't overwrite folder score
                $filename      = pathinfo($path, PATHINFO_FILENAME);
                $scored[$path] = $this->score($exercise->name, $filename);
            }
        }

        // Keep only candidates that clear the threshold, sorted descending
        $passing = array_filter($scored, fn ($s) => $s >= self::SCORE_THRESHOLD);
        arsort($passing);

        if (empty($passing)) {
            return null;
        }

        $paths  = array_keys($passing);
        $scores = array_values($passing);

        $topPath  = $paths[0];
        $topScore = $scores[0];

        // Ambiguity: runner-up also clears threshold and is too close to the top
        if (isset($paths[1]) && ($topScore - $scores[1]) < self::AMBIGUITY_DELTA) {
            return [
                'path'             => $topPath,
                'score'            => round($topScore, 1),
                'ambiguous'        => true,
                'runner_up'        => $paths[1],
                'runner_up_score'  => round($scores[1], 1),
            ];
        }

        return [
            'path'      => $topPath,
            'score'     => round($topScore, 1),
            'ambiguous' => false,
        ];
    }

    /**
     * Compute a 0–100 similarity score between an exercise name and a GIF filename.
     * Takes the maximum of Jaccard token overlap and similar_text().
     */
    private function score(string $exerciseName, string $filename): float
    {
        $normExercise = $this->normalize($exerciseName);
        $normFile     = $this->normalize($filename);

        $tokA = $this->tokenize($normExercise);
        $tokB = $this->tokenize($normFile);

        return max(
            $this->jaccardScore($tokA, $tokB),
            $this->similarTextScore($normExercise, $normFile),
        );
    }

    /**
     * Normalize a string:
     *   - transliterate accents to ASCII
     *   - lowercase
     *   - hyphens/underscores → spaces
     *   - strip numbers and punctuation (numbers are artifacts like "01" in filenames)
     *   - collapse whitespace
     */
    private function normalize(string $text): string
    {
        $text = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $text) ?: $text;
        $text = strtolower($text);
        $text = str_replace(['-', '_'], ' ', $text);
        $text = preg_replace('/[^a-z\s]/', '', $text);   // strips digits + punctuation

        return trim((string) preg_replace('/\s+/', ' ', $text));
    }

    /** @return string[] */
    private function tokenize(string $normalized): array
    {
        $tokens = explode(' ', $normalized);
        $tokens = array_filter($tokens, fn ($t) => $t !== '' && ! in_array($t, self::STOPWORDS, true));

        return array_values($tokens);
    }

    /** Jaccard index on token sets (× 100). */
    private function jaccardScore(array $a, array $b): float
    {
        if (empty($a) && empty($b)) {
            return 100.0;
        }

        $intersection = count(array_intersect($a, $b));
        $union        = count(array_unique(array_merge($a, $b)));

        return $union > 0 ? ($intersection / $union) * 100.0 : 0.0;
    }

    /** similar_text() percentage between two normalized strings. */
    private function similarTextScore(string $a, string $b): float
    {
        if ($a === '' && $b === '') {
            return 100.0;
        }

        similar_text($a, $b, $percent);

        return (float) $percent;
    }

    /**
     * Scan storage/app/public/exercises and return:
     *   $globalMap  : [ fileSlug => "FOLDER/filename.gif" ]
     *   $byFolder   : [ folderSlug => [ fileSlug => "FOLDER/filename.gif" ] ]
     */
    private function buildGifMaps(): array
    {
        $globalMap = [];
        $byFolder  = [];
        $basePath  = storage_path('app/public/exercises');
        $folders   = glob($basePath . '/*', GLOB_ONLYDIR) ?: [];

        foreach ($folders as $folderPath) {
            $folder = basename($folderPath);

            if (stripos($folder, 'bonus') !== false || stripos($folder, 'gifs -') !== false) {
                continue;
            }

            $folderSlug = Str::slug($folder);
            $gifs       = glob($folderPath . '/*.{gif,GIF}', GLOB_BRACE) ?: [];

            foreach ($gifs as $gifPath) {
                $fileSlug = Str::slug(pathinfo($gifPath, PATHINFO_FILENAME));
                $relative = $folder . '/' . basename($gifPath);

                if (! isset($globalMap[$fileSlug])) {
                    $globalMap[$fileSlug] = $relative;
                }

                $byFolder[$folderSlug][$fileSlug] = $relative;
            }
        }

        return [$globalMap, $byFolder];
    }
}
