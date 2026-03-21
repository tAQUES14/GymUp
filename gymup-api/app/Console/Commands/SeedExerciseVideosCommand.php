<?php

namespace App\Console\Commands;

use App\Models\Exercise;
use Illuminate\Console\Command;

class SeedExerciseVideosCommand extends Command
{
    protected $signature   = 'exercises:seed-videos {--dry-run : Preview changes without saving}';
    protected $description = 'Assign YouTube tutorial video URLs to exercises that have none';

    // ---------------------------------------------------------------------------
    // Curated map: exercise name (lowercase, trimmed) → YouTube video ID
    // Sources: ScottHermanFitness, Athlean-X, Jeff Nippard, Alan Thrall, Calisthenicmovement
    // ---------------------------------------------------------------------------
    private array $videoMap = [

        // ── Peito ──────────────────────────────────────────────────────────────
        'supino reto com barra'              => 'rT7DgCr-3pg', // Jeff Nippard – How To Bench Press
        'supino inclinado com halteres'      => 'DbFgADa6kZo', // ScottHermanFitness – Incline DB Press
        'supino declinado com barra'         => '9XkNRPDegxA', // ScottHermanFitness – Decline Bench
        'crucifixo com halteres'             => 'eozdVDA78K0', // ScottHermanFitness – DB Fly
        'crossover no cabo'                  => 'taI4XduLpTk', // Athlean-X – Cable Crossover
        'flexão de braços'                   => 'IODxDxX7oi4', // ScottHermanFitness – Push-Up

        // ── Costas ─────────────────────────────────────────────────────────────
        'puxada frontal na polia'            => 'CAwf7n6Luuc', // Athlean-X – Lat Pulldown
        'barra fixa (pull-up)'               => 'eGo4IYlbE5g', // Athlean-X – Perfect Pull-Up
        'remada curvada com barra'           => 'FWJR5Ve8bnQ', // ScottHermanFitness – Barbell Row
        'remada curvada com halteres'        => 'pYcpY20QaE8', // ScottHermanFitness – DB Row
        'remada sentada na polia baixa'      => 'GZbfZ033f74', // ScottHermanFitness – Seated Cable Row
        'remada unilateral com halter'       => 'roCP1_tMFQI', // ScottHermanFitness – One-Arm DB Row

        // ── Bíceps ─────────────────────────────────────────────────────────────
        'rosca direta com barra'             => 'kwG2ipFRgfo', // ScottHermanFitness – Barbell Curl
        'rosca alternada com halteres'       => 'sAq_ocpRh_I', // ScottHermanFitness – Alternating DB Curl
        'rosca martelo com halteres'         => 'TwD-YGVP4Bk', // ScottHermanFitness – Hammer Curl
        'rosca concentrada com halter'       => 'Jvj2wV0vOYU', // ScottHermanFitness – Concentration Curl
        'rosca scott (preacher curl)'        => 'fIwP-FRFNU8', // ScottHermanFitness – Preacher Curl

        // ── Tríceps ────────────────────────────────────────────────────────────
        'tríceps corda no cabo'              => 'vB5OHsJ3EME', // ScottHermanFitness – Rope Pushdown
        'tríceps testa com barra ez'         => '0rgHghKXPCY', // ScottHermanFitness – EZ Skull Crusher
        'tríceps francês com halter'         => 'OcCIyqHGLXU', // ScottHermanFitness – DB French Press
        'paralelas (tríceps dip)'            => '2z8JmcrW-As', // ScottHermanFitness – Tricep Dip
        'kickback com halter'                => '6SS6K3lAwZ8', // ScottHermanFitness – Tricep Kickback

        // ── Ombros ─────────────────────────────────────────────────────────────
        'elevação lateral com halteres'      => 'kDqklk1ZESo', // Jeff Nippard – Lateral Raise
        'desenvolvimento com halteres'       => 'qEwKCR5JCog', // ScottHermanFitness – DB Shoulder Press
        'desenvolvimento militar com barra'  => 'UEcFPNVp5Hc', // ScottHermanFitness – Barbell OHP
        'elevação frontal com halteres'      => 'hRjqiR4BKRM', // ScottHermanFitness – Front Raise
        'encolhimento de ombros'             => 'g6qbq4Lf1FI', // ScottHermanFitness – DB Shrug

        // ── Pernas ─────────────────────────────────────────────────────────────
        'agachamento livre com barra'        => 'ultWZbUMPL8', // Alan Thrall – How to Squat
        'leg press 45°'                      => 'yZmx_Ac3880', // ScottHermanFitness – Leg Press 45
        'stiff (levantamento terra romeno)'  => 'hCDzSR6bW10', // Athlean-X – Romanian Deadlift
        'avanço com halteres'                => 'D7KaRcUTQeE', // ScottHermanFitness – DB Lunge
        'agachamento búlgaro com halteres'   => 'kkdqtFzfLBc', // Jeff Nippard – Bulgarian Split Squat
        'extensão de joelho na máquina'      => '4ZDm5EbiFHM', // ScottHermanFitness – Leg Extension
        'flexão de joelho (leg curl) deitado'=> 'ELOCsoDSmrg', // ScottHermanFitness – Lying Leg Curl
        'panturrilha em pé na máquina'       => 'JbyjNymZOt0', // ScottHermanFitness – Standing Calf Raise

        // ── Abdômen / Core ─────────────────────────────────────────────────────
        'crunch abdominal'                   => 'Xyd_fa5zoEU', // ScottHermanFitness – Crunch
        'prancha frontal'                    => 'pSHjTRCQxIw', // ScottHermanFitness – Plank
        'elevação de pernas'                 => 'l4kQd9eWclE', // ScottHermanFitness – Hanging Leg Raise
        'russian twist'                      => '9UMxGGGLuX0', // ScottHermanFitness – Russian Twist
        'bicicleta abdominal'                => '9FGilxCbdz8', // ScottHermanFitness – Bicycle Crunch
        'abdominal oblíquo com halter'       => 'OHUoMdFRiYY', // ScottHermanFitness – Oblique Crunch

        // ── Cardio ─────────────────────────────────────────────────────────────
        'corrida na esteira'                 => 'lZyFQFsRrTY', // Nike Run Club – Treadmill Running Form
        'bicicleta ergométrica'              => 'DU4WJAzSaYw', // Sunny Health – Stationary Bike
        'elíptico'                           => 'V3ZYndsGyko', // Technogym – Elliptical form
        'corda de pular'                     => 'u3zgHI8QnqE', // CrossRope – Jump Rope
        'remo ergométrico'                   => 'H7RCqDa8XVw', // Concept2 – Rowing Machine form
        'escada rolante'                     => 'QA0lNmDHqw0', // ScottHermanFitness – StairMaster
        'caminhada inclinada'                => 'UQCQMJOA9aM', // Athlean-X – Incline Treadmill Walk
    ];

    public function handle(): int
    {
        $dry = $this->option('dry-run');
        if ($dry) $this->warn('DRY RUN — no changes saved.');

        $exercises = Exercise::whereNull('video_url')
            ->orWhere('video_url', '')
            ->get(['id', 'name', 'video_url']);

        $this->info("Exercises without video: {$exercises->count()}");
        $this->newLine();

        $updated = 0;
        $skipped = 0;

        foreach ($exercises as $exercise) {
            $key = mb_strtolower(trim($exercise->name));
            if (!isset($this->videoMap[$key])) {
                $this->line("  <fg=yellow>SKIP</> {$exercise->name}");
                $skipped++;
                continue;
            }

            $videoId  = $this->videoMap[$key];
            $videoUrl = "https://www.youtube.com/watch?v={$videoId}";

            $this->line("  <fg=green>SET</>  {$exercise->name}  → {$videoUrl}");

            if (!$dry) {
                $exercise->update(['video_url' => $videoUrl]);
            }

            $updated++;
        }

        $this->newLine();
        $this->info("Done. {$updated} updated, {$skipped} skipped (no mapping).");

        return self::SUCCESS;
    }
}
