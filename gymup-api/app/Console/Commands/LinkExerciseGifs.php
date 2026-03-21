<?php

namespace App\Console\Commands;

use App\Models\Exercise;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

class LinkExerciseGifs extends Command
{
    protected $signature   = 'exercises:link-gifs
                                {--force : Re-link exercises that already have a gif_file}
                                {--dry-run : Preview matches without saving}';

    protected $description = 'Automatically links GIF files to exercises using fuzzy name matching';

    private const SCORE_THRESHOLD = 70.0;

    private const STOPWORDS = [
        'com', 'de', 'para', 'no', 'na', 'em', 'e', 'a', 'o',
        'as', 'os', 'do', 'da', 'dos', 'das', 'ao', 'aos',
        'um', 'uma', 'the', 'and', 'with', 'on', 'in',
    ];

    /**
     * Maps exercise.muscle_group values to GIF storage folder names.
     */
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

        $exercises  = Exercise::all();
        $exactCount = 0;
        $fuzzyCount = 0;
        $skipped    = 0;
        $unmatched  = [];

        foreach ($exercises as $exercise) {
            // Never override manual mappings — even with --force
            if ($exercise->gif_is_auto === false) {
                $skipped++;
                continue;
            }

            if ($exercise->gif_file && ! $force) {
                $skipped++;
                continue;
            }

            $result = $this->findMatch($exercise, $globalMap, $byFolder);

            if ($result) {
                ['path' => $path, 'type' => $type, 'score' => $score] = $result;
                $confidence = (int) round($score);

                if (! $dryRun) {
                    $exercise->update([
                        'gif_file'       => $path,
                        'gif_confidence' => $confidence,
                        'gif_is_auto'    => true,
                    ]);
                }

                $label = $type === 'exact' ? '<info>✔ Exact</info>' : '<comment>~ Fuzzy</comment>';
                $scoreStr = $type === 'fuzzy' ? " <fg=gray>({$score}%)</>" : '';
                $this->line("  {$label}: {$exercise->name}  →  {$path}{$scoreStr}");

                $type === 'exact' ? $exactCount++ : $fuzzyCount++;
            } else {
                $unmatched[] = $exercise->name . ' [' . ($exercise->muscle_group ?? 'n/a') . ']';
            }
        }

        $this->newLine();
        $this->line("  <info>✔ Exact: {$exactCount}</info>");
        $this->line("  <comment>✔ Fuzzy: {$fuzzyCount}</comment>");
        $this->line('  <fg=red>❌ Unmatched: ' . count($unmatched) . '</>');

        if ($skipped > 0) {
            $this->line("  <fg=gray>→ {$skipped} already linked (use --force to re-link)</>");
        }

        if (! empty($unmatched)) {
            $this->newLine();
            $this->line('  <comment>Unmatched exercises:</comment>');
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
     * Find the best matching GIF path for an exercise.
     * Priority:
     *   1. Exact slug match in the expected muscle-group folder.
     *   2. Exact slug match globally.
     *   3. Best fuzzy match in the expected folder (score ≥ threshold).
     *   4. Best fuzzy match globally (score ≥ threshold).
     *
     * @return array{path:string,type:string,score:float}|null
     */
    private function findMatch(Exercise $exercise, array $globalMap, array $byFolder): ?array
    {
        $exerciseSlug   = Str::slug($exercise->name);
        $expectedFolder = self::FOLDER_MAP[$exercise->muscle_group] ?? null;
        $folderKey      = $expectedFolder ? Str::slug($expectedFolder) : null;
        $folderCandidates = $folderKey ? ($byFolder[$folderKey] ?? []) : [];

        // 1. Exact slug match in expected folder
        if (isset($folderCandidates[$exerciseSlug])) {
            return ['path' => $folderCandidates[$exerciseSlug], 'type' => 'exact', 'score' => 100.0];
        }

        // 2. Exact slug match globally
        if (isset($globalMap[$exerciseSlug])) {
            return ['path' => $globalMap[$exerciseSlug], 'type' => 'exact', 'score' => 100.0];
        }

        // 3. Best fuzzy match — prefer folder, fall back to global
        $result = $this->bestFuzzyMatch($exercise->name, $folderCandidates);
        if ($result) {
            return array_merge($result, ['type' => 'fuzzy']);
        }

        $result = $this->bestFuzzyMatch($exercise->name, $globalMap);
        if ($result) {
            return array_merge($result, ['type' => 'fuzzy']);
        }

        return null;
    }

    /**
     * Score every candidate and return the one with the highest score above the threshold.
     *
     * @param  array<string,string> $candidates  [ fileSlug => relativePath ]
     * @return array{path:string,score:float}|null
     */
    private function bestFuzzyMatch(string $exerciseName, array $candidates): ?array
    {
        if (empty($candidates)) {
            return null;
        }

        $bestScore = self::SCORE_THRESHOLD - 0.001; // must strictly exceed threshold
        $bestPath  = null;

        foreach ($candidates as $fileSlug => $path) {
            $filename = pathinfo($path, PATHINFO_FILENAME);
            $score    = $this->computeScore($exerciseName, $filename);

            if ($score > $bestScore) {
                $bestScore = $score;
                $bestPath  = $path;
            }
        }

        if ($bestPath === null) {
            return null;
        }

        return ['path' => $bestPath, 'score' => round($bestScore, 1)];
    }

    /**
     * Compute a similarity score (0–100) between an exercise name and a GIF filename.
     *
     * Uses two signals and takes the maximum:
     *   - Jaccard token overlap  (order-independent, handles reordered words)
     *   - similar_text()         (character-level, handles partial overlaps)
     */
    private function computeScore(string $exerciseName, string $filename): float
    {
        $normExercise = $this->normalize($exerciseName);
        $normFile     = $this->normalize($filename);

        $tokensExercise = $this->tokenize($normExercise);
        $tokensFile     = $this->tokenize($normFile);

        $tokenScore  = $this->jaccardScore($tokensExercise, $tokensFile);
        $stringScore = $this->similarTextScore($normExercise, $normFile);

        return max($tokenScore, $stringScore);
    }

    /**
     * Normalize a string for matching:
     *   - transliterate accents → ASCII
     *   - lowercase
     *   - replace hyphens/underscores with spaces
     *   - strip remaining punctuation
     *   - collapse whitespace
     */
    private function normalize(string $text): string
    {
        // Transliterate accented characters to ASCII equivalents
        $text = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $text) ?: $text;

        $text = strtolower($text);

        // Hyphens and underscores act as word separators
        $text = str_replace(['-', '_'], ' ', $text);

        // Remove anything that isn't a letter, digit, or space
        $text = preg_replace('/[^a-z0-9\s]/', '', $text);

        // Collapse whitespace
        return trim((string) preg_replace('/\s+/', ' ', $text));
    }

    /**
     * Split a normalized string into meaningful tokens, removing stopwords.
     *
     * @return string[]
     */
    private function tokenize(string $normalized): array
    {
        $tokens = explode(' ', $normalized);
        $tokens = array_filter($tokens, fn ($t) => $t !== '' && ! in_array($t, self::STOPWORDS, true));

        return array_values($tokens);
    }

    /**
     * Jaccard similarity = |intersection| / |union|  (× 100).
     *
     * @param  string[] $a
     * @param  string[] $b
     */
    private function jaccardScore(array $a, array $b): float
    {
        if (empty($a) && empty($b)) {
            return 100.0;
        }

        $intersection = count(array_intersect($a, $b));
        $union        = count(array_unique(array_merge($a, $b)));

        return $union > 0 ? ($intersection / $union) * 100.0 : 0.0;
    }

    /**
     * similar_text() percentage between two normalized strings.
     */
    private function similarTextScore(string $a, string $b): float
    {
        if ($a === '' && $b === '') {
            return 100.0;
        }

        similar_text($a, $b, $percent);

        return (float) $percent;
    }

    /**
     * Scan storage/app/public/exercises for all GIF files and return two maps:
     *   - $globalMap  : [ fileSlug => "FOLDER/filename.gif" ]
     *   - $byFolder   : [ folderSlug => [ fileSlug => "FOLDER/filename.gif" ] ]
     */
    private function buildGifMaps(): array
    {
        $globalMap = [];
        $byFolder  = [];
        $basePath  = storage_path('app/public/exercises');
        $folders   = glob($basePath . '/*', GLOB_ONLYDIR) ?: [];

        foreach ($folders as $folderPath) {
            $folder = basename($folderPath);

            // Skip misc/bonus folders
            if (stripos($folder, 'bonus') !== false || stripos($folder, 'gifs -') !== false) {
                continue;
            }

            $folderSlug = Str::slug($folder);
            $gifs       = glob($folderPath . '/*.{gif,GIF}', GLOB_BRACE) ?: [];

            foreach ($gifs as $gifPath) {
                $filename   = pathinfo($gifPath, PATHINFO_FILENAME);
                $fileSlug   = Str::slug($filename);
                $relative   = $folder . '/' . basename($gifPath);

                // Global map: first occurrence wins
                if (! isset($globalMap[$fileSlug])) {
                    $globalMap[$fileSlug] = $relative;
                }

                // Per-folder map: last occurrence wins (handles in-folder duplicates)
                $byFolder[$folderSlug][$fileSlug] = $relative;
            }
        }

        return [$globalMap, $byFolder];
    }
}
