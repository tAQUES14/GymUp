<?php

namespace App\Console\Commands;

use App\Models\Exercise;
use Illuminate\Console\Command;

class FixExerciseGifMappings extends Command
{
    protected $signature   = 'exercises:fix-gif-mappings
                                {--dry-run : Simulate all changes without saving}';

    protected $description = 'Applies deterministic manual GIF mappings and corrects known wrong links';

    /**
     * Exercises whose current gif_file is wrong and must be replaced.
     * null means "no suitable GIF exists — set to null."
     * Applied unconditionally (no --force needed) because these are actively incorrect.
     */
    private const CORRECTIONS = [
        // Was linked to "Remada inclinada.gif" — wrong exercise entirely.
        // No cardio/treadmill GIF exists in storage.
        'Caminhada inclinada' => null,

        // Was linked to "Flexão de quadril banco.gif" — completely wrong movement.
        // Closest push-up GIF available in PEITORAL; not a perfect standard push-up
        // but correct muscle group and movement pattern.
        'Flexão de braços' => 'PEITORAL/Flexão apoio alto.gif',

        // Was linked to "Elevação frontal com halteres.gif" — wrong plane of movement.
        // Lateral raise 01 is the standard dumbbell lateral raise.
        'Elevação lateral com halteres' => 'DELTÓIDES/Elevação lateral 01.gif',
    ];

    /**
     * Exercises that were ambiguous or unmatched by the auto-linker.
     * Each entry maps exercise name → verified gif path.
     * Applied only when gif_file IS NULL (safe by default).
     *
     * NOTE: "Agachamento livre com barra" references the Bonus folder because
     * no standard barbell squat GIF exists in the primary MEMBROS INFERIORES folder.
     *
     * NOTE: "Bicicleta abdominal" maps to "Abdominal bicleta.gif" — the filename
     * in storage has a typo ("bicleta" instead of "bicicleta").
     *
     * NOTE: "Tríceps testa com barra ez" maps to "Triceps testa 01.gif" (skull crusher),
     * NOT "Triceps frances com barra.gif" which is an overhead extension — a different
     * movement.
     */
    private const MANUAL_MAPPINGS = [
        // ── Abdômen ──────────────────────────────────────────────────────────
        'Elevação de pernas'           => 'ABDOMEN CORE/Elevação de pernas solo.gif',
        'Abdominal oblíquo com halter' => 'ABDOMEN CORE/ABS obliquo.gif',
        'Bicicleta abdominal'          => 'ABDOMEN CORE/Abdominal bicleta.gif',

        // ── Bíceps ───────────────────────────────────────────────────────────
        'Rosca concentrada com halter' => 'BÍCEPS e ANTEBRAÇO/Rosca concentrada masculino.gif',
        'Rosca martelo com halteres'   => 'BÍCEPS e ANTEBRAÇO/Rosca martelo alternada.gif',
        'Rosca scott (preacher curl)'  => 'BÍCEPS e ANTEBRAÇO/Rosca scott barra reta.gif',

        // ── Costas ───────────────────────────────────────────────────────────
        'Remada curvada com barra'         => 'COSTAS E TRAPÉZIO/Remada curvada pronada.gif',
        'Remada curvada com halteres'      => 'COSTAS E TRAPÉZIO/Remada com halteres.gif',
        'Encolhimento de ombros'           => 'COSTAS E TRAPÉZIO/Encolhimento com halteres.gif',
        'Remada sentada na polia baixa'    => 'COSTAS E TRAPÉZIO/cable-seated-row.gif',

        // ── Pernas ───────────────────────────────────────────────────────────
        'Agachamento búlgaro com halteres'    => 'MEMBROS INFERIORES E GLÚTEOS/Bulgaro com halteres.gif',
        'Agachamento livre com barra'         => 'Gifs - Bonus/Membros Inferiores (53)/Agachamento livre com barra.gif',
        'Extensão de joelho na máquina'       => 'MEMBROS INFERIORES E GLÚTEOS/Cadeira extensora.gif',
        'Flexão de joelho (leg curl) deitado' => 'MEMBROS INFERIORES E GLÚTEOS/Mesa flexora.gif',

        // ── Tríceps ──────────────────────────────────────────────────────────
        'Kickback com halter'        => 'TRÍCEPS/dumbbell-tricep-kickback.gif',
        'Tríceps testa com barra ez' => 'TRÍCEPS/Triceps testa 01.gif',
    ];

    /**
     * Cardio exercises that have no matching GIF in storage.
     * These are set to (or confirmed as) null.
     * Any wrong auto-link that may exist will be cleared.
     */
    private const CARDIO_NULL = [
        'Bicicleta ergométrica',
        'Caminhada inclinada',
        'Corda de pular',
        'Corrida na esteira',
        'Elíptico',
        'Escada rolante',
        'Remo ergométrico',
    ];

    public function handle(): int
    {
        $dryRun = $this->option('dry-run');

        // Load all exercises indexed by name for O(1) lookup
        $exercises = Exercise::all()->keyBy('name');

        $corrected  = 0;
        $mapped     = 0;
        $nulled     = 0;
        $skipped    = [];
        $missing    = [];

        // ── Step 1: Correct wrong matches ────────────────────────────────────
        $this->line('  <comment>── Corrections ─────────────────────────────</comment>');

        foreach (self::CORRECTIONS as $name => $targetPath) {
            $exercise = $exercises->get($name);

            if (! $exercise) {
                $missing[] = $name;
                continue;
            }

            if ($targetPath !== null && ! $this->gifExists($targetPath)) {
                $this->line("  <fg=red>✘ FILE NOT FOUND</>: {$name}  →  {$targetPath}");
                $skipped[] = $name;
                continue;
            }

            $was = $exercise->gif_file ?? 'null';
            $now = $targetPath ?? 'null';

            if (! $dryRun) {
                $exercise->update([
                    'gif_file'       => $targetPath,
                    'gif_confidence' => null,
                    'gif_is_auto'    => false,
                ]);
            }

            $label = $targetPath ? '<info>✔</info>' : '<fg=yellow>∅</>';
            $this->line("  {$label} {$name}");
            $this->line("      was: {$was}");
            $this->line("      now: {$now}");

            $corrected++;
        }

        // ── Step 2: Apply manual mappings (null → GIF) ────────────────────
        $this->newLine();
        $this->line('  <comment>── Manual mappings ──────────────────────────</comment>');

        foreach (self::MANUAL_MAPPINGS as $name => $targetPath) {
            $exercise = $exercises->get($name);

            if (! $exercise) {
                $missing[] = $name;
                continue;
            }

            if ($exercise->gif_file !== null) {
                // Already has a (presumably correct) value — don't touch it
                $skipped[] = "{$name} (already has gif_file)";
                continue;
            }

            if (! $this->gifExists($targetPath)) {
                $this->line("  <fg=red>✘ FILE NOT FOUND</>: {$name}  →  {$targetPath}");
                $skipped[] = $name;
                continue;
            }

            if (! $dryRun) {
                $exercise->update([
                    'gif_file'       => $targetPath,
                    'gif_confidence' => null,
                    'gif_is_auto'    => false,
                ]);
            }

            $this->line("  <info>✔</info> {$name}  →  {$targetPath}");
            $mapped++;
        }

        // ── Step 3: Confirm cardio exercises as null ─────────────────────
        $this->newLine();
        $this->line('  <comment>── Cardio (no GIF available) ─────────────────</comment>');

        foreach (self::CARDIO_NULL as $name) {
            $exercise = $exercises->get($name);

            if (! $exercise) {
                $missing[] = $name;
                continue;
            }

            $hadWrongLink = $exercise->gif_file !== null;

            if ($hadWrongLink) {
                if (! $dryRun) {
                    $exercise->update([
                        'gif_file'       => null,
                        'gif_confidence' => null,
                        'gif_is_auto'    => false,
                    ]);
                }
                $this->line("  <fg=yellow>∅ cleared wrong link</>: {$name}  (was: {$exercise->gif_file})");
                $corrected++;
            } else {
                $this->line("  <fg=gray>· confirmed null</>: {$name}");
            }

            $nulled++;
        }

        // ── Summary ──────────────────────────────────────────────────────────
        $this->newLine();
        $this->line('  ┌───────────────────────────────────────┐');
        $this->line("  │  <info>Corrected:              {$corrected}</info>             │");
        $this->line("  │  <info>Mapped manually:         {$mapped}</info>             │");
        $this->line("  │  <fg=yellow>Left null intentionally: {$nulled}</fg=yellow>             │");

        if (! empty($skipped)) {
            $this->line("  │  <comment>Skipped:                 " . count($skipped) . '</comment>             │');
        }

        if (! empty($missing)) {
            $this->line("  │  <fg=red>Exercise not in DB:      " . count($missing) . '</fg=red>             │');
        }

        $this->line('  └───────────────────────────────────────┘');

        if (! empty($skipped)) {
            $this->newLine();
            $this->line('  <comment>Skipped:</comment>');
            foreach ($skipped as $s) {
                $this->line("    · {$s}");
            }
        }

        if (! empty($missing)) {
            $this->newLine();
            $this->line('  <fg=red>Exercise name not found in DB (check spelling):</fg=red>');
            foreach ($missing as $m) {
                $this->line("    · {$m}");
            }
        }

        if ($dryRun) {
            $this->newLine();
            $this->warn('  Dry run — no changes were saved.');
        }

        return self::SUCCESS;
    }

    /**
     * Check that the GIF file physically exists in storage before saving the path.
     */
    private function gifExists(string $relativePath): bool
    {
        return file_exists(storage_path('app/public/exercises/' . $relativePath));
    }
}
