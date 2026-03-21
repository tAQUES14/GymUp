<?php

namespace App\Console\Commands;

use App\Models\Exercise;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class EnrichExercisesCommand extends Command
{
    protected $signature   = 'exercises:enrich {--dry-run : Preview changes without persisting}';
    protected $description = 'Deduplicate, normalize names, and enrich exercises with educational content';

    public function handle(): int
    {
        $dry = $this->option('dry-run');
        if ($dry) $this->warn('DRY RUN — no changes saved.');

        $this->info('Loading exercises…');
        $exercises = Exercise::all();
        $this->line("  → {$exercises->count()} total");
        $this->newLine();

        // Step 1 ─ Deduplicate
        $this->info('Step 1: Deduplicating…');
        $kept = $this->deduplicate($exercises, $dry);
        $this->newLine();

        // Step 2 ─ Enrich
        $this->info('Step 2: Enriching content…');
        $updated = 0;
        foreach ($kept as $ex) {
            $patch = [];

            // Normalize name
            $canon = $this->canonicalName($ex->name);
            if ($ex->name !== $canon) {
                $patch['name'] = $canon;
            }

            // Fill missing content
            if ($this->needsContent($ex)) {
                $content = $this->resolveContent($ex);
                foreach ($content as $k => $v) {
                    if ($v !== null && $ex->{$k} === null) {
                        $patch[$k] = $v;
                    }
                }
            }

            if (!empty($patch)) {
                $label = $patch['name'] ?? $ex->name;
                $this->line("  ✓ {$label}");
                if (!$dry) $ex->update($patch);
                $updated++;
            }
        }

        $this->newLine();
        $this->info("Done. {$updated} exercises updated.");
        return self::SUCCESS;
    }

    // ── Deduplication ─────────────────────────────────────────────────────────

    private function deduplicate($exercises, bool $dry): array
    {
        $groups = [];
        foreach ($exercises as $ex) {
            $groups[$this->normalizedKey($ex->name)][] = $ex;
        }

        $kept    = [];
        $removed = 0;

        foreach ($groups as $group) {
            if (count($group) === 1) { $kept[] = $group[0]; continue; }

            usort($group, fn($a, $b) => $this->score($b) <=> $this->score($a));
            $winner = $group[0];
            $losers = array_slice($group, 1);

            $names = implode(', ', array_map(fn($e) => "\"{$e->name}\"", $losers));
            $this->line("  Merge {$names} → \"{$winner->name}\"");

            if (!$dry) {
                foreach ($losers as $loser) {
                    $this->redirectRefs($loser->id, $winner->id);
                    $loser->delete();
                }
            }
            $kept[] = $winner;
            $removed += count($losers);
        }

        $this->line("  → {$removed} duplicates removed, " . count($kept) . ' kept.');
        return $kept;
    }

    private function redirectRefs(int $from, int $to): void
    {
        // custom_workout_exercise: avoid creating duplicate pivot rows
        DB::table('custom_workout_exercise')
            ->where('exercise_id', $from)
            ->whereNotExists(fn($q) => $q
                ->from('custom_workout_exercise as x')
                ->whereColumn('x.custom_workout_id', 'custom_workout_exercise.custom_workout_id')
                ->where('x.exercise_id', $to))
            ->update(['exercise_id' => $to]);
        DB::table('custom_workout_exercise')->where('exercise_id', $from)->delete();

        foreach (['workout_exercises', 'exercise_weights'] as $table) {
            if (DB::getSchemaBuilder()->hasTable($table)) {
                DB::table($table)->where('exercise_id', $from)->update(['exercise_id' => $to]);
            }
        }

        DB::table('exercise_substitutions')->where('exercise_id', $from)->update(['exercise_id' => $to]);
        DB::table('exercise_substitutions')->where('substitute_exercise_id', $from)->update(['substitute_exercise_id' => $to]);

        if (DB::getSchemaBuilder()->hasTable('user_exercise_overrides')) {
            DB::table('user_exercise_overrides')->where('exercise_id', $from)->update(['exercise_id' => $to]);
        }
    }

    private function score(Exercise $ex): int
    {
        return count($ex->execution_steps ?? []) * 3
             + count($ex->common_mistakes ?? []) * 2
             + count($ex->tips            ?? []) * 2
             + (empty($ex->description)   ? 0 : 2)
             + (empty($ex->video_url)     ? 0 : 1)
             + (empty($ex->primary_muscle)? 0 : 1);
    }

    // ── Name normalisation ────────────────────────────────────────────────────

    private function normalizedKey(string $name): string
    {
        $low = mb_strtolower(trim($name));
        // strip parentheticals for matching
        $stripped = trim(preg_replace('/\s*[\(\[].*?[\)\]]/', '', $low));
        return $this->nameAliases[$stripped] ?? $this->nameAliases[$low] ?? $low;
    }

    private function canonicalName(string $name): string
    {
        $key = $this->normalizedKey($name);
        $lib = $this->library();
        if (isset($lib[$key]['name'])) return $lib[$key]['name'];
        // Sentence-case fallback
        return mb_strtoupper(mb_substr($name, 0, 1)) . mb_substr($name, 1);
    }

    // ── Content resolution ────────────────────────────────────────────────────

    private function needsContent(Exercise $ex): bool
    {
        return empty($ex->execution_steps) || count($ex->execution_steps) === 0;
    }

    private function resolveContent(Exercise $ex): array
    {
        $key = $this->normalizedKey($ex->name);
        $lib = $this->library();
        if (isset($lib[$key])) {
            $entry = $lib[$key];
            return [
                'name'              => $entry['name']              ?? null,
                'primary_muscle'    => $entry['primary_muscle']    ?? null,
                'secondary_muscles' => $entry['secondary_muscles'] ?? null,
                'description'       => $entry['description']       ?? null,
                'execution_steps'   => $entry['execution_steps']   ?? null,
                'common_mistakes'   => $entry['common_mistakes']   ?? null,
                'tips'              => $entry['tips']               ?? null,
            ];
        }
        return $this->genericContent($ex);
    }

    private function genericContent(Exercise $ex): array
    {
        $g = $ex->muscle_group ?? 'Geral';
        return [
            'description'     => "Exercício de {$g} para desenvolvimento de força e hipertrofia muscular.",
            'execution_steps' => [
                'Ajuste o equipamento e posicione-se de forma correta e segura.',
                'Mantenha o core contraído e a coluna neutra durante toda a execução.',
                'Execute o movimento de forma controlada em toda a amplitude.',
                'Controle a fase excêntrica (retorno) por 2 a 3 segundos.',
                'Realize as séries e repetições prescritas focando na contração muscular.',
            ],
            'common_mistakes' => [
                'Usar carga excessiva comprometendo a técnica de execução.',
                'Executar o movimento de forma rápida e descontrolada.',
                'Não completar a amplitude total do movimento.',
            ],
            'tips' => [
                'Foque na contração do músculo alvo em cada repetição.',
                'Mantenha a respiração controlada durante todo o exercício.',
                'Progrida as cargas de forma gradual e consciente.',
            ],
        ];
    }

    // ── Aliases ───────────────────────────────────────────────────────────────

    private array $nameAliases = [
        // Peito
        'supino reto'                          => 'supino reto com barra',
        'supino plano'                         => 'supino reto com barra',
        'supino inclinado'                     => 'supino inclinado com barra',
        'supino declinado'                     => 'supino declinado com barra',
        'crucifixo'                            => 'crucifixo com halteres',
        'crossover'                            => 'crossover no cabo',
        'peck deck'                            => 'peck deck (máquina)',
        'flexão de braço'                      => 'flexão de braços',
        'flexao de bracos'                     => 'flexão de braços',
        'pullover'                             => 'pullover com halter',
        'supino fechado'                       => 'supino fechado (pegada estreita)',
        'mergulho no banco'                    => 'mergulho no banco (chest dip)',
        // Costas
        'barra fixa'                           => 'barra fixa (pull-up)',
        'pull-up'                              => 'barra fixa (pull-up)',
        'pull up'                              => 'barra fixa (pull-up)',
        'puxada na frente'                     => 'puxada frontal na polia',
        'puxada'                               => 'puxada frontal na polia',
        'puxada na polia'                      => 'puxada frontal na polia',
        'puxada frontal'                       => 'puxada frontal na polia',
        'puxada neutra'                        => 'puxada neutra na polia',
        'remada curvada'                       => 'remada curvada com barra',
        'remada unilateral'                    => 'remada unilateral com halter',
        'remada com halteres'                  => 'remada curvada com halteres',
        'remada cavalinho'                     => 'remada cavalinho (t-bar)',
        'remada t'                             => 'remada cavalinho (t-bar)',
        'remada baixa'                         => 'remada sentada na polia baixa',
        'remada sentada no cabo'               => 'remada sentada na polia baixa',
        'remada sentada'                       => 'remada sentada na polia baixa',
        'hiperextensão'                        => 'hiperextensão lombar',
        'hiperextensao'                        => 'hiperextensão lombar',
        'levantamento terra'                   => 'levantamento terra (deadlift)',
        'deadlift'                             => 'levantamento terra (deadlift)',
        'chin up'                              => 'chin-up (barra supinada)',
        'chin-up'                              => 'chin-up (barra supinada)',
        'face pull'                            => 'remada face pull',
        'remada invertida'                     => 'remada invertida (australian pull-up)',
        // Bíceps
        'rosca direta'                         => 'rosca direta com barra',
        'rosca barra'                          => 'rosca direta com barra',
        'rosca alternada'                      => 'rosca alternada com halteres',
        'rosca martelo'                        => 'rosca martelo com halteres',
        'rosca martelo com haltere'            => 'rosca martelo com halteres',
        'rosca concentrada'                    => 'rosca concentrada com halter',
        'rosca inclinada'                      => 'rosca inclinada com halteres',
        'rosca scott'                          => 'rosca scott (preacher curl)',
        'preacher curl'                        => 'rosca scott (preacher curl)',
        'rosca 21'                             => 'rosca 21 com barra',
        'rosca inversa'                        => 'rosca inversa com barra',
        'rosca spider'                         => 'rosca spider com halteres',
        'rosca zottman'                        => 'rosca zottman com halteres',
        'rosca cabo'                           => 'rosca com cabo unilateral',
        // Tríceps
        'triceps pulley'                       => 'tríceps pulley (barra reta)',
        'triceps corda'                        => 'tríceps corda no cabo',
        'tríceps corda'                        => 'tríceps corda no cabo',
        'triceps testa'                        => 'tríceps testa com barra ez',
        'tríceps testa'                        => 'tríceps testa com barra ez',
        'skull crusher'                        => 'tríceps testa com barra ez',
        'tríceps francês'                      => 'tríceps francês com halter',
        'triceps frances'                      => 'tríceps francês com halter',
        'tríceps francês com barra'            => 'tríceps testa com barra ez',
        'extensão de tríceps com haltere'      => 'tríceps francês com halter',
        'fundos'                               => 'paralelas (tríceps dip)',
        'fundos (dips)'                        => 'paralelas (tríceps dip)',
        'mergulho'                             => 'paralelas (tríceps dip)',
        'paralelas'                            => 'paralelas (tríceps dip)',
        'tríceps coice'                        => 'kickback com halter',
        'kickback'                             => 'kickback com halter',
        // Ombros
        'desenvolvimento militar'              => 'desenvolvimento militar com barra',
        'press militar com barra'              => 'desenvolvimento militar com barra',
        'overhead press'                       => 'desenvolvimento militar com barra',
        'desenvolvimento'                      => 'desenvolvimento com halteres',
        'elevação lateral'                     => 'elevação lateral com halteres',
        'elevacao lateral'                     => 'elevação lateral com halteres',
        'elevação frontal'                     => 'elevação frontal com halteres',
        'elevacao frontal'                     => 'elevação frontal com halteres',
        'remada alta'                          => 'remada alta com barra',
        'upright row'                          => 'remada alta com barra',
        'pássaro'                              => 'pássaro com halteres (deltoide posterior)',
        'passaro'                              => 'pássaro com halteres (deltoide posterior)',
        'arnold press'                         => 'arnold press com halteres',
        'encolhimento'                         => 'encolhimento de ombros',
        // Pernas
        'agachamento'                          => 'agachamento livre com barra',
        'agachamento livre'                    => 'agachamento livre com barra',
        'squat'                                => 'agachamento livre com barra',
        'leg press'                            => 'leg press 45°',
        'leg press 45'                         => 'leg press 45°',
        'extensão de joelho'                   => 'extensão de joelho na máquina',
        'extensao de joelho'                   => 'extensão de joelho na máquina',
        'cadeira extensora'                    => 'extensão de joelho na máquina',
        'leg extension'                        => 'extensão de joelho na máquina',
        'flexão de joelho'                     => 'flexão de joelho (leg curl) deitado',
        'flexao de joelho'                     => 'flexão de joelho (leg curl) deitado',
        'mesa flexora'                         => 'flexão de joelho (leg curl) deitado',
        'leg curl'                             => 'flexão de joelho (leg curl) deitado',
        'stiff'                                => 'stiff (levantamento terra romeno)',
        'stiff com barra'                      => 'stiff (levantamento terra romeno)',
        'rdl'                                  => 'stiff (levantamento terra romeno)',
        'avanço'                               => 'avanço com halteres',
        'avanco'                               => 'avanço com halteres',
        'lunge'                                => 'avanço com halteres',
        'agachamento sumô'                     => 'agachamento sumô com barra',
        'agachamento sumo'                     => 'agachamento sumô com barra',
        'panturrilha em pé'                    => 'panturrilha em pé na máquina',
        'panturrilha em pe'                    => 'panturrilha em pé na máquina',
        'panturrilha sentada'                  => 'panturrilha sentado na máquina',
        'agachamento frontal'                  => 'agachamento frontal com barra',
        'agachamento hack'                     => 'agachamento hack na máquina',
        'step up'                              => 'step-up no banco',
        'agachamento búlgaro'                  => 'agachamento búlgaro com halteres',
        'agachamento bulgaro'                  => 'agachamento búlgaro com halteres',
        'agachamento goblet'                   => 'agachamento goblet com kettlebell',
        'afundo reverso'                       => 'afundo reverso com halteres',
        'nordic curl'                          => 'nordic curl',
        'wall sit'                             => 'wall sit (cadeira na parede)',
        // Glúteos
        'hip thrust'                           => 'hip thrust com barra',
        'ponte de glúteo'                      => 'ponte de glúteo',
        'ponte de gluteo'                      => 'ponte de glúteo',
        'coice de burro'                       => 'coice de burro (donkey kick)',
        'donkey kick'                          => 'coice de burro (donkey kick)',
        'glute kickback'                       => 'glute kickback na máquina',
        // Abdômen
        'abdominal'                            => 'crunch abdominal',
        'crunch'                               => 'crunch abdominal',
        'abdominal crunch'                     => 'crunch abdominal',
        'prancha'                              => 'prancha frontal',
        'plank'                                => 'prancha frontal',
        'elevação de pernas'                   => 'elevação de pernas',
        'elevacao de pernas'                   => 'elevação de pernas',
        'bicicleta'                            => 'bicicleta abdominal',
        'abdominal bicicleta'                  => 'bicicleta abdominal',
        'russian twist'                        => 'russian twist',
        'abdominal oblíquo'                    => 'abdominal oblíquo com halter',
        'abdominal obliquo'                    => 'abdominal oblíquo com halter',
        'ab wheel'                             => 'abdominal com roda (ab wheel)',
        'dragon flag'                          => 'dragon flag',
        'flutter kicks'                        => 'flutter kicks',
        'hollow hold'                          => 'hollow hold',
        'dead bug'                             => 'dead bug',
        // Cardio
        'esteira'                              => 'corrida na esteira',
        'corrida leve'                         => 'corrida na esteira',
        'corrida'                              => 'corrida na esteira',
        'bike ergométrica'                     => 'bicicleta ergométrica',
        'bike ergomet'                         => 'bicicleta ergométrica',
        'eliptico'                             => 'elíptico',
        'corda'                                => 'corda de pular',
        'jump rope'                            => 'corda de pular',
        'burpee'                               => 'burpee (hiit)',
        'hiit'                                 => 'burpee (hiit)',
        'remo ergométrico'                     => 'remo ergométrico',
        'escada rolante'                       => 'escada rolante',
        'caminhada inclinada'                  => 'caminhada inclinada',
    ];

    // ── Content library ───────────────────────────────────────────────────────

    private function library(): array
    {
        return [

            // ── PEITO ─────────────────────────────────────────────────────────

            'supino reto com barra' => [
                'name' => 'Supino reto com barra', 'primary_muscle' => 'Peito',
                'secondary_muscles' => ['Tríceps', 'Deltoide anterior'],
                'description' => 'Exercício multiarticular para desenvolvimento do peitoral maior com barra.',
                'execution_steps' => [
                    'Deite no banco com os pés apoiados no chão e as costas levemente arqueadas.',
                    'Segure a barra com pegada um pouco mais larga que os ombros.',
                    'Desça a barra de forma controlada até tocar levemente o peito na altura dos mamilos.',
                    'Empurre a barra para cima de forma explosiva até a extensão completa dos cotovelos.',
                ],
                'common_mistakes' => [
                    'Elevar os quadris do banco durante a execução.',
                    'Deixar os cotovelos abertos a 90°, sobrecarregando os ombros.',
                    'Não descer a barra até o peito, limitando a amplitude.',
                ],
                'tips' => [
                    'Imagine "dobrar" a barra com as mãos para fora para ativar mais o peitoral.',
                    'Mantenha as escápulas retraídas e deprimidas durante todo o movimento.',
                ],
            ],

            'supino inclinado com barra' => [
                'name' => 'Supino inclinado com barra', 'primary_muscle' => 'Peito',
                'secondary_muscles' => ['Tríceps', 'Deltoide anterior'],
                'description' => 'Versão inclinada do supino, focando na porção clavicular do peitoral.',
                'execution_steps' => [
                    'Ajuste o banco em 30 a 45 graus e deite com os pés apoiados.',
                    'Segure a barra com pegada um pouco mais larga que os ombros.',
                    'Desça a barra de forma controlada até a parte superior do peito.',
                    'Empurre a barra para cima até a extensão completa dos cotovelos.',
                ],
                'common_mistakes' => [
                    'Usar inclinação acima de 45°, transferindo o esforço para os deltoides.',
                    'Não manter o core estabilizado durante a execução.',
                ],
                'tips' => [
                    'A inclinação de 30° é ideal para focar na porção clavicular.',
                    'Mantenha os pés bem apoiados no chão para estabilidade.',
                ],
            ],

            'supino inclinado com halteres' => [
                'name' => 'Supino inclinado com halteres', 'primary_muscle' => 'Peito',
                'secondary_muscles' => ['Tríceps', 'Deltoide anterior'],
                'description' => 'Supino inclinado com halteres para desenvolvimento da porção superior do peitoral.',
                'execution_steps' => [
                    'Ajuste o banco em 30 a 45 graus e deite com um halter em cada mão.',
                    'Posicione os halteres na altura do peito superior com cotovelos dobrados.',
                    'Empurre os halteres para cima e levemente para dentro até quase se tocarem.',
                    'Desça de forma controlada abrindo os cotovelos.',
                ],
                'common_mistakes' => [
                    'Usar inclinação acima de 45°, sobrecarregando os deltoides anteriores.',
                    'Perder o controle dos halteres na fase excêntrica.',
                ],
                'tips' => [
                    'Os halteres permitem maior amplitude que a barra.',
                    'Controle a descida em 2 a 3 segundos.',
                ],
            ],

            'supino declinado com barra' => [
                'name' => 'Supino declinado com barra', 'primary_muscle' => 'Peito',
                'secondary_muscles' => ['Tríceps'],
                'description' => 'Supino em posição declinada, ativando a porção inferior do peitoral.',
                'execution_steps' => [
                    'Ajuste o banco em declínio de 15 a 30 graus e prenda os pés.',
                    'Segure a barra com pegada um pouco mais larga que os ombros.',
                    'Desça a barra de forma controlada até a parte inferior do peito.',
                    'Empurre a barra para cima até a extensão completa dos cotovelos.',
                ],
                'common_mistakes' => [
                    'Usar uma amplitude muito curta no movimento de descida.',
                    'Não fixar os pés adequadamente no suporte.',
                ],
                'tips' => [
                    'Peça ajuda de um parceiro ao desmontar a barra.',
                    'Use um agarre de polegar cruzado para mais segurança.',
                ],
            ],

            'crucifixo com halteres' => [
                'name' => 'Crucifixo com halteres', 'primary_muscle' => 'Peito',
                'secondary_muscles' => ['Deltoide anterior'],
                'description' => 'Exercício de isolamento para o peitoral com ampla abertura dos braços.',
                'execution_steps' => [
                    'Deite no banco com um halter em cada mão, braços estendidos acima do peito.',
                    'Abra os braços lateralmente em arco amplo, mantendo leve flexão nos cotovelos.',
                    'Desça até sentir o alongamento no peitoral, não passando de 180° de abertura.',
                    'Retorne fechando os braços em arco como se abraçasse uma árvore.',
                ],
                'common_mistakes' => [
                    'Usar carga excessiva e perder o padrão de arco do movimento.',
                    'Descer os halteres abaixo do nível do banco, sobrecarregando os ombros.',
                ],
                'tips' => [
                    'É um exercício de isolamento — use cargas menores que no supino.',
                    'Foque no alongamento e na contração a cada repetição.',
                ],
            ],

            'crossover no cabo' => [
                'name' => 'Crossover no cabo', 'primary_muscle' => 'Peito',
                'secondary_muscles' => ['Deltoide anterior'],
                'description' => 'Exercício de isolamento do peitoral com tensão constante pelo cabo.',
                'execution_steps' => [
                    'Ajuste as roldanas na posição alta e segure um cabo em cada mão.',
                    'Avance um passo à frente com leve inclinação para criar tensão.',
                    'Puxe os cabos para baixo e para frente em arco até as mãos se cruzarem.',
                    'Contraia o peitoral por 1 segundo no cruzamento, depois retorne.',
                ],
                'common_mistakes' => [
                    'Dobrar excessivamente os cotovelos, reduzindo a ativação do peitoral.',
                    'Usar o impulso do corpo em vez de controlar o movimento.',
                ],
                'tips' => [
                    'Varie a altura das roldanas para atingir porções diferentes do peitoral.',
                    'Mantenha o tronco estável e o core ativado.',
                ],
            ],

            'peck deck (máquina)' => [
                'name' => 'Peck deck (máquina)', 'primary_muscle' => 'Peito',
                'secondary_muscles' => [],
                'description' => 'Máquina de isolamento para o peitoral, sem solicitação dos tríceps.',
                'execution_steps' => [
                    'Ajuste o assento de modo que os cotovelos fiquem na altura dos ombros.',
                    'Apoie os antebraços nas almofadas com as costas bem coladas ao banco.',
                    'Feche os braços à frente contraindo o peitoral no ponto final.',
                    'Segure a contração por 1 segundo antes de abrir controladamente.',
                ],
                'common_mistakes' => [
                    'Afastar as costas do banco durante a execução.',
                    'Abrir demais os braços, sobrecarregando os ombros.',
                ],
                'tips' => [
                    'Ideal para isolamento do peitoral sem recrutar os tríceps.',
                    'Controle especialmente a fase excêntrica.',
                ],
            ],

            'flexão de braços' => [
                'name' => 'Flexão de braços', 'primary_muscle' => 'Peito',
                'secondary_muscles' => ['Tríceps', 'Deltoide anterior'],
                'description' => 'Exercício clássico de peso corporal para peitoral, tríceps e ombros.',
                'execution_steps' => [
                    'Posicione as mãos no chão um pouco mais largas que os ombros.',
                    'Forme uma linha reta da cabeça aos calcanhares.',
                    'Desça o peito até quase tocar o chão, cotovelos em 45° em relação ao corpo.',
                    'Empurre de volta à posição inicial até a extensão dos cotovelos.',
                ],
                'common_mistakes' => [
                    'Deixar o quadril subir ou cair durante o movimento.',
                    'Abrir os cotovelos a 90°, lesionando os ombros.',
                ],
                'tips' => [
                    'Mantenha o pescoço neutro, sem olhar para cima ou para baixo.',
                    'Para facilitar, apoie os joelhos no chão.',
                ],
            ],

            // ── COSTAS ────────────────────────────────────────────────────────

            'barra fixa (pull-up)' => [
                'name' => 'Barra fixa (pull-up)', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Bíceps', 'Deltoide posterior'],
                'description' => 'Exercício de peso corporal para grande dorsal e bíceps com pegada pronada.',
                'execution_steps' => [
                    'Segure a barra com pegada pronada, mais larga que os ombros.',
                    'Pendure-se com os braços completamente estendidos.',
                    'Puxe o corpo para cima até o queixo ultrapassar a barra.',
                    'Desça de forma controlada até a extensão completa dos braços.',
                ],
                'common_mistakes' => [
                    'Usar o impulso do corpo balançando em vez de força muscular.',
                    'Não completar a extensão total dos braços no ponto inicial.',
                ],
                'tips' => [
                    'Para facilitar, use elásticos de assistência ou graviton.',
                    'Ative o grande dorsal imaginando que está puxando a barra para baixo.',
                ],
            ],

            'puxada frontal na polia' => [
                'name' => 'Puxada frontal na polia', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Bíceps'],
                'description' => 'Puxada com roldana para desenvolvimento do grande dorsal.',
                'execution_steps' => [
                    'Sente-se na máquina e segure a barra com pegada pronada, mais larga que os ombros.',
                    'Mantenha o tronco levemente inclinado para trás.',
                    'Puxe a barra em direção à parte superior do peito, retraindo as escápulas.',
                    'Retorne de forma controlada à posição inicial com os braços estendidos.',
                ],
                'common_mistakes' => [
                    'Inclinar excessivamente o tronco para trás.',
                    'Puxar a barra atrás da cabeça, sobrecarregando a coluna cervical.',
                ],
                'tips' => [
                    'Leve o peito em direção à barra, não a barra ao peito.',
                    'Controle a subida para não perder a tensão muscular.',
                ],
            ],

            'remada curvada com barra' => [
                'name' => 'Remada curvada com barra', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Bíceps', 'Trapézio'],
                'description' => 'Remada com barra e tronco inclinado para desenvolvimento do dorsal e romboides.',
                'execution_steps' => [
                    'Segure a barra com pegada pronada, pés na largura dos ombros.',
                    'Incline o tronco a aproximadamente 45° mantendo as costas retas.',
                    'Puxe a barra em direção ao abdômen inferior, cotovelos próximos ao corpo.',
                    'Contraia as escápulas no ponto de maior contração e desça controlando.',
                ],
                'common_mistakes' => [
                    'Arredondar as costas durante a execução.',
                    'Usar o impulso do tronco para mover a barra.',
                ],
                'tips' => [
                    'Concentre-se em puxar pelos cotovelos, não pelas mãos.',
                    'Inicie o movimento com a retração das escápulas.',
                ],
            ],

            'remada curvada com halteres' => [
                'name' => 'Remada curvada com halteres', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Bíceps'],
                'description' => 'Remada bilateral com halteres e tronco inclinado.',
                'execution_steps' => [
                    'Segure um halter em cada mão e incline o tronco a 45°.',
                    'Deixe os halteres pendurados com os braços estendidos.',
                    'Puxe os halteres em direção ao abdômen, retraindo as escápulas.',
                    'Desça de forma controlada até a extensão total.',
                ],
                'common_mistakes' => [
                    'Arredondar as costas durante o exercício.',
                    'Usar impulso do tronco para elevar os halteres.',
                ],
                'tips' => [
                    'Permite maior amplitude que a remada com barra.',
                    'Mantenha a coluna neutra durante todo o movimento.',
                ],
            ],

            'remada unilateral com halter' => [
                'name' => 'Remada unilateral com halter', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Bíceps'],
                'description' => 'Remada unilateral apoiada no banco para isolamento do grande dorsal.',
                'execution_steps' => [
                    'Apoie o joelho e a mão do mesmo lado no banco, tronco paralelo ao chão.',
                    'Segure o halter com o braço estendido.',
                    'Puxe o halter em direção ao quadril, cotovelo próximo ao corpo.',
                    'Contraia o grande dorsal no ponto mais alto e desça controlando.',
                ],
                'common_mistakes' => [
                    'Rotar excessivamente o tronco para ganhar impulso.',
                    'Não estender completamente o braço na fase de descida.',
                ],
                'tips' => [
                    'Imagine que está colocando o cotovelo no bolso traseiro.',
                    'Controle especialmente a fase excêntrica.',
                ],
            ],

            'remada sentada na polia baixa' => [
                'name' => 'Remada sentada na polia baixa', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Bíceps'],
                'description' => 'Remada sentada no cabo para desenvolvimento do dorsal e romboides.',
                'execution_steps' => [
                    'Sente-se com os pés apoiados nas plataformas e joelhos levemente dobrados.',
                    'Segure o triângulo com as costas eretas e tronco perpendicular ao chão.',
                    'Puxe o triângulo em direção ao abdômen com cotovelos próximos ao corpo.',
                    'Contraia as escápulas no ponto final e retorne controlando.',
                ],
                'common_mistakes' => [
                    'Inclinar o tronco para frente e para trás em balanço.',
                    'Puxar apenas com os bíceps sem ativar o dorsal.',
                ],
                'tips' => [
                    'Mantenha o tronco estável durante todo o exercício.',
                    'Inicie o movimento com a retração das escápulas.',
                ],
            ],

            'levantamento terra (deadlift)' => [
                'name' => 'Levantamento terra (deadlift)', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Pernas', 'Glúteos', 'Core'],
                'description' => 'Levantamento multiarticular completo, um dos exercícios mais eficazes para força total.',
                'execution_steps' => [
                    'Posicione os pés na largura do quadril com a barra sobre o meio do pé.',
                    'Segure a barra com pegada um pouco mais larga que os joelhos.',
                    'Mantenha o peito alto, as costas retas e as escápulas retraídas.',
                    'Empurre o chão com os pés, estendendo quadril e joelhos simultaneamente.',
                    'Desça a barra pelo mesmo caminho de forma controlada.',
                ],
                'common_mistakes' => [
                    'Arredondar a região lombar durante o levantamento.',
                    'Deixar a barra se afastar do corpo durante o movimento.',
                ],
                'tips' => [
                    'Imagine que está empurrando o chão para longe, não puxando a barra para cima.',
                    'Mantenha a barra rente ao corpo durante todo o movimento.',
                ],
            ],

            'hiperextensão lombar' => [
                'name' => 'Hiperextensão lombar', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Glúteos'],
                'description' => 'Exercício para fortalecimento dos eretores espinhais e glúteos.',
                'execution_steps' => [
                    'Posicione-se no banco com os calcanhares sob os suportes.',
                    'Cruce os braços no peito ou leve as mãos atrás da cabeça.',
                    'Desça o tronco para baixo de forma controlada.',
                    'Eleve o tronco até ficar paralelo ou levemente acima da horizontal, contraindo os glúteos.',
                ],
                'common_mistakes' => [
                    'Hiperestender além do plano horizontal, comprimindo a coluna.',
                    'Usar o impulso para elevar o tronco.',
                ],
                'tips' => [
                    'Para aumentar a dificuldade, segure um peso no peito.',
                    'Foque na contração dos glúteos e eretores no topo.',
                ],
            ],

            'remada face pull' => [
                'name' => 'Remada face pull', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Deltoide posterior'],
                'description' => 'Exercício essencial para deltoides posteriores e saúde dos ombros.',
                'execution_steps' => [
                    'Ajuste a roldana na altura dos olhos e encaixe a corda.',
                    'Segure as pontas da corda com pegada neutra e dê um passo para trás.',
                    'Puxe a corda em direção ao rosto, separando as mãos ao final.',
                    'Contraia as escápulas e os deltoides posteriores no ponto final.',
                ],
                'common_mistakes' => [
                    'Puxar a corda abaixo do nível dos olhos.',
                    'Não separar as mãos no ponto final do movimento.',
                ],
                'tips' => [
                    'Exercício preventivo essencial para a saúde dos ombros.',
                    'Use cargas leves e foque na execução e rotação externa.',
                ],
            ],

            'chin-up (barra supinada)' => [
                'name' => 'Chin-up (barra supinada)', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Bíceps'],
                'description' => 'Barra fixa com pegada supinada, maior ativação de bíceps.',
                'execution_steps' => [
                    'Segure a barra com pegada supinada na largura dos ombros.',
                    'Pendure-se com os braços completamente estendidos.',
                    'Puxe o corpo para cima até o queixo ultrapassar a barra.',
                    'Desça de forma controlada até a extensão completa.',
                ],
                'common_mistakes' => [
                    'Usar impulso do corpo balançando.',
                    'Elevar os ombros durante o movimento.',
                ],
                'tips' => [
                    'Mais acessível que o pull-up pela maior ativação dos bíceps.',
                    'Controle especialmente a fase excêntrica.',
                ],
            ],

            // ── BÍCEPS ────────────────────────────────────────────────────────

            'rosca direta com barra' => [
                'name' => 'Rosca direta com barra', 'primary_muscle' => 'Bíceps',
                'secondary_muscles' => [],
                'description' => 'Exercício clássico de isolamento para o bíceps com barra.',
                'execution_steps' => [
                    'Fique em pé com a barra em mãos, pegada supinada na largura dos ombros.',
                    'Mantenha os cotovelos fixos ao lado do corpo.',
                    'Flexione os cotovelos elevando a barra em direção ao peito.',
                    'Contraia os bíceps no ponto mais alto e desça controlando.',
                ],
                'common_mistakes' => [
                    'Balançar o tronco para elevar a carga.',
                    'Mover os cotovelos para frente durante a flexão.',
                ],
                'tips' => [
                    'Mantenha os cotovelos imóveis ao lado do corpo.',
                    'Controle a fase excêntrica por 2 a 3 segundos.',
                ],
            ],

            'rosca alternada com halteres' => [
                'name' => 'Rosca alternada com halteres', 'primary_muscle' => 'Bíceps',
                'secondary_muscles' => [],
                'description' => 'Rosca alternada com supinação do pulso para máxima contração do bíceps.',
                'execution_steps' => [
                    'Fique em pé com um halter em cada mão, palmas voltadas para o corpo.',
                    'Flexione um cotovelo de cada vez elevando o halter em supinação.',
                    'Gire o pulso enquanto eleva, terminando com a palma voltada para cima.',
                    'Contraia o bíceps no topo e desça controlando, alternando os braços.',
                ],
                'common_mistakes' => [
                    'Não realizar a supinação do punho durante o movimento.',
                    'Balançar o tronco para ajudar no levantamento.',
                ],
                'tips' => [
                    'A supinação do punho maximiza a contração do bíceps.',
                    'Execute o movimento de forma controlada e alternada.',
                ],
            ],

            'rosca martelo com halteres' => [
                'name' => 'Rosca martelo com halteres', 'primary_muscle' => 'Bíceps',
                'secondary_muscles' => [],
                'description' => 'Rosca com pegada neutra para desenvolvimento do braquiorradial e bíceps.',
                'execution_steps' => [
                    'Fique em pé com um halter em cada mão, pegada neutra (polegar para cima).',
                    'Mantenha os cotovelos fixos ao lado do corpo.',
                    'Flexione os cotovelos elevando os halteres com a pegada neutra.',
                    'Contraia no ponto mais alto e desça de forma controlada.',
                ],
                'common_mistakes' => [
                    'Balançar o tronco para elevar os halteres.',
                    'Girar os pulsos durante o movimento.',
                ],
                'tips' => [
                    'Ativa fortemente o braquiorradial além do bíceps.',
                    'Ótimo para desenvolver espessura e largura do braço.',
                ],
            ],

            'rosca concentrada com halter' => [
                'name' => 'Rosca concentrada com halter', 'primary_muscle' => 'Bíceps',
                'secondary_muscles' => [],
                'description' => 'Isolamento máximo do bíceps com apoio do cotovelo na coxa.',
                'execution_steps' => [
                    'Sente-se com as pernas abertas e apoie o cotovelo na face interna da coxa.',
                    'Segure o halter com o braço estendido.',
                    'Flexione o cotovelo elevando o halter em direção ao ombro.',
                    'Contraia o bíceps no topo e desça de forma controlada.',
                ],
                'common_mistakes' => [
                    'Inclinar o tronco para ajudar no levantamento.',
                    'Não ir até a extensão completa na descida.',
                ],
                'tips' => [
                    'Excelente para desenvolver o pico do bíceps.',
                    'Foque na contração máxima no topo do movimento.',
                ],
            ],

            'rosca scott (preacher curl)' => [
                'name' => 'Rosca scott (preacher curl)', 'primary_muscle' => 'Bíceps',
                'secondary_muscles' => [],
                'description' => 'Rosca no banco Scott para isolamento total do bíceps.',
                'execution_steps' => [
                    'Sente-se no banco Scott e apoie os braços no suporte inclinado.',
                    'Segure a barra EZ ou halteres com pegada supinada.',
                    'Flexione os cotovelos elevando o peso em direção ao ombro.',
                    'Contraia os bíceps no topo e desça de forma controlada.',
                ],
                'common_mistakes' => [
                    'Deixar os braços levantarem do suporte durante o movimento.',
                    'Usar impulso para completar a repetição.',
                ],
                'tips' => [
                    'O suporte elimina qualquer compensação do tronco.',
                    'Não estenda completamente os cotovelos para manter a tensão.',
                ],
            ],

            'rosca inclinada com halteres' => [
                'name' => 'Rosca inclinada com halteres', 'primary_muscle' => 'Bíceps',
                'secondary_muscles' => [],
                'description' => 'Rosca em banco inclinado para maior amplitude e alongamento do bíceps.',
                'execution_steps' => [
                    'Ajuste o banco em 45° e deite com um halter em cada mão pendendo atrás.',
                    'Flexione os cotovelos elevando os halteres sem mover os ombros.',
                    'Contraia os bíceps no topo.',
                    'Desça de forma controlada aproveitando o alongamento.',
                ],
                'common_mistakes' => [
                    'Mover os ombros para frente ao elevar os halteres.',
                    'Usar carga excessiva comprometendo a amplitude.',
                ],
                'tips' => [
                    'A inclinação proporciona maior alongamento do bíceps.',
                    'Execute de forma lenta e controlada.',
                ],
            ],

            // ── TRÍCEPS ───────────────────────────────────────────────────────

            'tríceps pulley (barra reta)' => [
                'name' => 'Tríceps pulley (barra reta)', 'primary_muscle' => 'Tríceps',
                'secondary_muscles' => [],
                'description' => 'Extensão de tríceps no cabo com barra reta, exercício clássico de isolamento.',
                'execution_steps' => [
                    'Ajuste a roldana na posição alta e encaixe a barra reta.',
                    'Segure a barra com pegada pronada na largura dos ombros.',
                    'Mantenha os cotovelos fixos ao lado do corpo.',
                    'Empurre a barra para baixo até a extensão completa dos cotovelos.',
                    'Retorne de forma controlada até os antebraços ficarem paralelos ao chão.',
                ],
                'common_mistakes' => [
                    'Mover os cotovelos para frente durante a extensão.',
                    'Inclinar o tronco sobre a barra para ajudar.',
                ],
                'tips' => [
                    'Mantenha os cotovelos colados ao corpo durante todo o movimento.',
                    'Foque na contração dos tríceps na extensão total.',
                ],
            ],

            'tríceps corda no cabo' => [
                'name' => 'Tríceps corda no cabo', 'primary_muscle' => 'Tríceps',
                'secondary_muscles' => [],
                'description' => 'Extensão de tríceps com corda no cabo para maior amplitude de movimento.',
                'execution_steps' => [
                    'Ajuste a roldana na posição alta e encaixe a corda.',
                    'Segure as pontas da corda com pegada neutra.',
                    'Mantenha os cotovelos fixos ao lado do corpo.',
                    'Empurre a corda para baixo, separando as pontas ao final do movimento.',
                    'Retorne de forma controlada à posição inicial.',
                ],
                'common_mistakes' => [
                    'Não separar as pontas da corda no ponto final.',
                    'Mover os cotovelos durante o movimento.',
                ],
                'tips' => [
                    'Separe as mãos ao finalizar para maximizar a contração.',
                    'Ideal como finalizador de treino de tríceps.',
                ],
            ],

            'tríceps testa com barra ez' => [
                'name' => 'Tríceps testa com barra ez', 'primary_muscle' => 'Tríceps',
                'secondary_muscles' => [],
                'description' => 'Exercício de isolamento para tríceps com barra EZ, também chamado skull crusher.',
                'execution_steps' => [
                    'Deite no banco segurando a barra EZ com pegada pronada.',
                    'Posicione os braços perpendiculares ao chão, cotovelos apontados para o teto.',
                    'Flexione os cotovelos baixando a barra em direção à testa.',
                    'Estenda os cotovelos de volta à posição inicial.',
                ],
                'common_mistakes' => [
                    'Deixar os cotovelos abrirem para os lados.',
                    'Mover os cotovelos para frente ou para trás.',
                ],
                'tips' => [
                    'A barra EZ é mais ergonômica para os pulsos.',
                    'Mantenha os cotovelos apontados para o teto.',
                ],
            ],

            'tríceps francês com halter' => [
                'name' => 'Tríceps francês com halter', 'primary_muscle' => 'Tríceps',
                'secondary_muscles' => [],
                'description' => 'Extensão de tríceps sobre a cabeça, ativando especialmente a cabeça longa.',
                'execution_steps' => [
                    'Sente-se ou fique em pé segurando um halter com as duas mãos acima da cabeça.',
                    'Mantenha os cotovelos próximos à cabeça apontados para cima.',
                    'Flexione os cotovelos baixando o halter atrás da cabeça.',
                    'Estenda os cotovelos de volta à posição inicial.',
                ],
                'common_mistakes' => [
                    'Deixar os cotovelos abrirem para os lados.',
                    'Mover os ombros durante a extensão.',
                ],
                'tips' => [
                    'Ativa especialmente a porção longa do tríceps.',
                    'Execute de forma lenta e controlada.',
                ],
            ],

            'paralelas (tríceps dip)' => [
                'name' => 'Paralelas (tríceps dip)', 'primary_muscle' => 'Tríceps',
                'secondary_muscles' => ['Peito', 'Deltoide anterior'],
                'description' => 'Exercício de peso corporal nas barras paralelas com tronco ereto.',
                'execution_steps' => [
                    'Segure as barras paralelas com os braços estendidos e o tronco ereto.',
                    'Desça o corpo flexionando os cotovelos até ângulo de 90°.',
                    'Mantenha o tronco ereto para focar nos tríceps.',
                    'Empurre para cima até a extensão completa dos cotovelos.',
                ],
                'common_mistakes' => [
                    'Inclinar o tronco para frente, transferindo o esforço para o peitoral.',
                    'Descer além do ângulo seguro para os ombros.',
                ],
                'tips' => [
                    'Tronco ereto = tríceps; tronco inclinado = peitoral.',
                    'Para aumentar a dificuldade, use cinto de lastro.',
                ],
            ],

            'kickback com halter' => [
                'name' => 'Kickback com halter', 'primary_muscle' => 'Tríceps',
                'secondary_muscles' => [],
                'description' => 'Extensão de tríceps com o braço paralelo ao chão em apoio unilateral.',
                'execution_steps' => [
                    'Apoie um joelho e a mão do mesmo lado em um banco.',
                    'Segure o halter com a mão livre, cotovelo em 90°.',
                    'Eleve o cotovelo até ficar paralelo ao chão.',
                    'Estenda o cotovelo empurrando o halter para trás.',
                    'Retorne controlando ao ângulo de 90°.',
                ],
                'common_mistakes' => [
                    'Mover o ombro para ajudar na extensão.',
                    'Não manter o cotovelo paralelo ao chão.',
                ],
                'tips' => [
                    'Excelente para isolamento da cabeça lateral do tríceps.',
                    'Execute de forma lenta para sentir o trabalho do tríceps.',
                ],
            ],

            // ── OMBROS ────────────────────────────────────────────────────────

            'desenvolvimento militar com barra' => [
                'name' => 'Desenvolvimento militar com barra', 'primary_muscle' => 'Ombro',
                'secondary_muscles' => ['Tríceps'],
                'description' => 'Press com barra acima da cabeça para desenvolvimento completo dos deltoides.',
                'execution_steps' => [
                    'Fique em pé ou sente-se com a barra na altura dos ombros, pegada pronada.',
                    'Mantenha o core ativo e as costas retas.',
                    'Empurre a barra para cima até a extensão completa dos cotovelos.',
                    'Retorne de forma controlada à posição inicial.',
                ],
                'common_mistakes' => [
                    'Arquear excessivamente a lombar ao empurrar.',
                    'Usar o impulso das pernas para levantar.',
                ],
                'tips' => [
                    'Mantenha o core fortemente contraído para proteger a lombar.',
                    'O desenvolvimento em pé desafia mais a estabilidade.',
                ],
            ],

            'desenvolvimento com halteres' => [
                'name' => 'Desenvolvimento com halteres', 'primary_muscle' => 'Ombro',
                'secondary_muscles' => ['Tríceps'],
                'description' => 'Press com halteres para desenvolvimento dos deltoides com maior amplitude.',
                'execution_steps' => [
                    'Sente-se no banco com encosto, halteres na altura dos ombros com cotovelos a 90°.',
                    'Empurre os halteres para cima até a extensão quase completa.',
                    'Desça de forma controlada à posição inicial.',
                    'Mantenha o core ativado durante todo o movimento.',
                ],
                'common_mistakes' => [
                    'Arquear a lombar ao empurrar os halteres.',
                    'Deixar os cotovelos abertos demais para os lados.',
                ],
                'tips' => [
                    'Os halteres permitem maior amplitude que a barra.',
                    'Use o banco com encosto para proteger a coluna.',
                ],
            ],

            'elevação lateral com halteres' => [
                'name' => 'Elevação lateral com halteres', 'primary_muscle' => 'Ombro',
                'secondary_muscles' => [],
                'description' => 'Isolamento do deltoide médio para dar largura ao ombro.',
                'execution_steps' => [
                    'Fique em pé com um halter em cada mão ao lado do corpo.',
                    'Eleve os halteres lateralmente até a altura dos ombros com leve flexão nos cotovelos.',
                    'Controle a descida de forma lenta e controlada.',
                    'Mantenha o tronco estável sem balançar.',
                ],
                'common_mistakes' => [
                    'Usar o impulso do tronco para elevar os halteres.',
                    'Elevar os halteres acima dos ombros.',
                ],
                'tips' => [
                    'Incline levemente o halter como se derramasse água para maior ativação.',
                    'Use cargas menores e priorize a técnica.',
                ],
            ],

            'elevação frontal com halteres' => [
                'name' => 'Elevação frontal com halteres', 'primary_muscle' => 'Ombro',
                'secondary_muscles' => [],
                'description' => 'Isolamento do deltoide anterior com movimento frontal.',
                'execution_steps' => [
                    'Fique em pé com um halter em cada mão na frente do corpo.',
                    'Eleve um halter de cada vez para a frente até a altura dos ombros.',
                    'Mantenha leve flexão nos cotovelos.',
                    'Desça de forma controlada e alterne os braços.',
                ],
                'common_mistakes' => [
                    'Usar o impulso do tronco.',
                    'Elevar os halteres acima da linha dos ombros.',
                ],
                'tips' => [
                    'Pode ser executado simultaneamente ou alternado.',
                    'Use a barra para variação com pegada pronada.',
                ],
            ],

            'remada alta com barra' => [
                'name' => 'Remada alta com barra', 'primary_muscle' => 'Ombro',
                'secondary_muscles' => ['Trapézio', 'Bíceps'],
                'description' => 'Puxada vertical para ativação dos deltoides médios e trapézio.',
                'execution_steps' => [
                    'Segure a barra com pegada pronada, mãos a 20-30 cm de distância.',
                    'Puxe a barra para cima ao longo do corpo até a altura do queixo.',
                    'Mantenha os cotovelos acima das mãos durante o movimento.',
                    'Desça de forma controlada.',
                ],
                'common_mistakes' => [
                    'Usar pegada muito estreita, causando impacto no ombro.',
                    'Afastar a barra do corpo durante o movimento.',
                ],
                'tips' => [
                    'A pegada mais larga reduz o impacto nos ombros.',
                    'Puxe pelos cotovelos, não pelas mãos.',
                ],
            ],

            'pássaro com halteres (deltoide posterior)' => [
                'name' => 'Pássaro com halteres (deltoide posterior)', 'primary_muscle' => 'Ombro',
                'secondary_muscles' => ['Costas'],
                'description' => 'Exercício para deltoide posterior com tronco inclinado.',
                'execution_steps' => [
                    'Incline o tronco a 45° com os joelhos levemente dobrados.',
                    'Segure halteres com os braços pendendo, palmas voltadas uma para a outra.',
                    'Eleve os braços lateralmente até a altura dos ombros.',
                    'Contraia os deltoides posteriores e os romboides no topo.',
                    'Desça de forma controlada.',
                ],
                'common_mistakes' => [
                    'Usar o impulso do tronco para elevar os halteres.',
                    'Dobrar excessivamente os cotovelos.',
                ],
                'tips' => [
                    'Músculo frequentemente negligenciado — crucial para postura.',
                    'Combine com face pull para trabalho completo do deltoide posterior.',
                ],
            ],

            'arnold press com halteres' => [
                'name' => 'Arnold press com halteres', 'primary_muscle' => 'Ombro',
                'secondary_muscles' => ['Tríceps'],
                'description' => 'Press com rotação de pulso que ativa as três cabeças do deltoide.',
                'execution_steps' => [
                    'Sente-se com os halteres na frente do corpo, palmas voltadas para você.',
                    'Ao empurrar para cima, gire os pulsos para que as palmas fiquem para frente.',
                    'Estenda completamente os cotovelos no topo.',
                    'Ao descer, reverta a rotação das palmas voltando para você.',
                ],
                'common_mistakes' => [
                    'Não realizar a rotação completa do punho.',
                    'Arquear a lombar ao empurrar.',
                ],
                'tips' => [
                    'Execute de forma lenta para aproveitar a amplitude completa.',
                    'Ótimo para desenvolvimento completo do ombro.',
                ],
            ],

            'encolhimento de ombros' => [
                'name' => 'Encolhimento de ombros', 'primary_muscle' => 'Ombro',
                'secondary_muscles' => ['Trapézio'],
                'description' => 'Exercício para desenvolvimento do trapézio superior.',
                'execution_steps' => [
                    'Fique em pé segurando halteres ou barra ao lado do corpo.',
                    'Eleve os ombros em direção às orelhas de forma explosiva.',
                    'Segure a contração no ponto mais alto por 1 segundo.',
                    'Desça de forma controlada.',
                ],
                'common_mistakes' => [
                    'Rotar os ombros durante o movimento.',
                    'Usar impulso do corpo para elevar.',
                ],
                'tips' => [
                    'Movimento deve ser exclusivamente vertical — não circular.',
                    'Mantenha os braços estendidos durante todo o exercício.',
                ],
            ],

            // ── PERNAS ────────────────────────────────────────────────────────

            'agachamento livre com barra' => [
                'name' => 'Agachamento livre com barra', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => ['Glúteos', 'Core'],
                'description' => 'O exercício mais completo para membros inferiores, trabalhando quadríceps, glúteos e core.',
                'execution_steps' => [
                    'Posicione a barra nos trapézios e fique em pé com os pés na largura dos ombros.',
                    'Aponte os pés levemente para fora.',
                    'Desça o corpo mantendo o peito alto e os joelhos alinhados com os dedos dos pés.',
                    'Desça até as coxas ficarem paralelas ou abaixo do chão.',
                    'Empurre o chão com os pés para subir.',
                ],
                'common_mistakes' => [
                    'Deixar os joelhos colapsarem para dentro (joelho em valgo).',
                    'Elevar os calcanhares do chão.',
                    'Arredondar a região lombar na descida.',
                ],
                'tips' => [
                    'Mantenha o peito alto e o olhar levemente para frente.',
                    'Respire profundamente antes de descer e expire ao subir.',
                ],
            ],

            'leg press 45°' => [
                'name' => 'Leg press 45°', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => ['Glúteos'],
                'description' => 'Prensa para pernas em 45 graus, excelente para quadríceps e glúteos.',
                'execution_steps' => [
                    'Sente-se na máquina e posicione os pés na plataforma na largura dos ombros.',
                    'Destrave a máquina e desça a plataforma controlando os joelhos.',
                    'Desça até os joelhos atingirem aproximadamente 90°.',
                    'Empurre a plataforma de volta, mantendo as costas coladas ao banco.',
                ],
                'common_mistakes' => [
                    'Deixar os joelhos colapsarem para dentro.',
                    'Descer a plataforma até os glúteos saírem do banco.',
                ],
                'tips' => [
                    'Pés mais altos ativam mais glúteos; pés mais baixos ativam mais quadríceps.',
                    'Não trave completamente os joelhos para manter tensão muscular.',
                ],
            ],

            'extensão de joelho na máquina' => [
                'name' => 'Extensão de joelho na máquina', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => [],
                'description' => 'Isolamento dos quadríceps na cadeira extensora.',
                'execution_steps' => [
                    'Ajuste o assento e posicione os tornozelos sob os suportes.',
                    'Mantenha as costas apoiadas no banco.',
                    'Estenda os joelhos até a posição quase reta.',
                    'Contraia os quadríceps no ponto final e desça controlando.',
                ],
                'common_mistakes' => [
                    'Usar impulso para elevar o peso.',
                    'Soltar o peso de forma abrupta.',
                ],
                'tips' => [
                    'Mantenha os pés em dorsiflexão para maior ativação.',
                    'Controle especialmente a fase excêntrica.',
                ],
            ],

            'flexão de joelho (leg curl) deitado' => [
                'name' => 'Flexão de joelho (leg curl) deitado', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => [],
                'description' => 'Isolamento dos isquiotibiais na mesa flexora.',
                'execution_steps' => [
                    'Deite de bruços e posicione os tornozelos sob os suportes.',
                    'Mantenha o quadril em contato com o banco.',
                    'Flexione os joelhos puxando os calcanhares em direção aos glúteos.',
                    'Contraia os isquiotibiais no ponto final e retorne controlando.',
                ],
                'common_mistakes' => [
                    'Elevar o quadril do banco durante o movimento.',
                    'Não controlar a fase excêntrica.',
                ],
                'tips' => [
                    'Mantenha os pés em dorsiflexão para maior ativação.',
                    'Execute de forma lenta para maximizar o estímulo.',
                ],
            ],

            'stiff (levantamento terra romeno)' => [
                'name' => 'Stiff (levantamento terra romeno)', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => ['Glúteos', 'Costas'],
                'description' => 'Exercício para isquiotibiais com inclinação do tronco e joelhos semiextendidos.',
                'execution_steps' => [
                    'Fique em pé segurando a barra, pés na largura do quadril.',
                    'Incline o tronco para frente mantendo as costas retas e joelhos levemente dobrados.',
                    'Desça a barra ao longo das pernas sentindo o alongamento nos isquiotibiais.',
                    'Retorne à posição inicial contraindo os glúteos e isquiotibiais.',
                ],
                'common_mistakes' => [
                    'Arredondar a região lombar durante o movimento.',
                    'Afastar a barra do corpo durante a descida.',
                ],
                'tips' => [
                    'Mantenha a barra rente às pernas durante todo o movimento.',
                    'Empurre o quadril para trás ao descer.',
                ],
            ],

            'avanço com halteres' => [
                'name' => 'Avanço com halteres', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => ['Glúteos'],
                'description' => 'Exercício unilateral para quadríceps e glúteos com passo à frente.',
                'execution_steps' => [
                    'Fique em pé com halteres nas mãos.',
                    'Dê um passo largo para frente com um pé.',
                    'Desça o joelho traseiro em direção ao chão sem tocá-lo.',
                    'O joelho dianteiro deve ficar alinhado com o pé.',
                    'Empurre com o pé dianteiro para voltar e alterne as pernas.',
                ],
                'common_mistakes' => [
                    'Deixar o joelho dianteiro ultrapassar os dedos dos pés.',
                    'Inclinar excessivamente o tronco para frente.',
                ],
                'tips' => [
                    'Mantenha o tronco ereto durante toda a execução.',
                    'O passo deve ser largo o suficiente para manter o equilíbrio.',
                ],
            ],

            'panturrilha em pé na máquina' => [
                'name' => 'Panturrilha em pé na máquina', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => [],
                'description' => 'Exercício para o gastrocnêmio com carga na panturrilha em pé.',
                'execution_steps' => [
                    'Posicione-se com as almofadas nos ombros e a ponta dos pés na plataforma.',
                    'Desça os calcanhares abaixo da plataforma para o alongamento completo.',
                    'Empurre os calcanhares para cima contraindo as panturrilhas.',
                    'Segure a contração no topo por 1 segundo e desça controlando.',
                ],
                'common_mistakes' => [
                    'Fazer o movimento muito rápido sem controlar o alongamento.',
                    'Não descer abaixo do nível da plataforma.',
                ],
                'tips' => [
                    'O alongamento completo no ponto inferior é essencial.',
                    'Varie a posição dos pés (aberto, paralelo, fechado).',
                ],
            ],

            'agachamento búlgaro com halteres' => [
                'name' => 'Agachamento búlgaro com halteres', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => ['Glúteos'],
                'description' => 'Agachamento unilateral com o pé traseiro elevado para maior ativação.',
                'execution_steps' => [
                    'Apoie um pé atrás em um banco e o outro à frente.',
                    'Segure halteres nas mãos para resistência.',
                    'Desça o corpo flexionando o joelho da frente.',
                    'Desça até o joelho traseiro quase tocar o chão.',
                    'Empurre com o pé da frente para subir.',
                ],
                'common_mistakes' => [
                    'Deixar o joelho dianteiro ultrapassar os dedos dos pés.',
                    'Não manter equilíbrio durante a descida.',
                ],
                'tips' => [
                    'Excelente para força unilateral e mobilidade de quadril.',
                    'Comece sem carga para aprender o padrão de movimento.',
                ],
            ],

            // ── GLÚTEOS ───────────────────────────────────────────────────────

            'hip thrust com barra' => [
                'name' => 'Hip thrust com barra', 'primary_muscle' => 'Glúteos',
                'secondary_muscles' => ['Isquiotibiais'],
                'description' => 'O exercício mais eficaz para ativação e hipertrofia dos glúteos.',
                'execution_steps' => [
                    'Sente-se no chão com as costas apoiadas em um banco, barra sobre os quadris.',
                    'Posicione os pés na largura dos ombros com joelhos dobrados.',
                    'Empurre os quadris para cima contraindo os glúteos.',
                    'Suba até o tronco ficar paralelo ao chão.',
                    'Desça de forma controlada sem deixar os glúteos tocarem o chão.',
                ],
                'common_mistakes' => [
                    'Arquear excessivamente a lombar no topo do movimento.',
                    'Deixar os joelhos colapsarem para dentro.',
                ],
                'tips' => [
                    'Use um amortecedor ou toalha sobre os quadris para conforto.',
                    'Mantenha o queixo levemente abaixado para não forçar o pescoço.',
                ],
            ],

            'ponte de glúteo' => [
                'name' => 'Ponte de glúteo', 'primary_muscle' => 'Glúteos',
                'secondary_muscles' => ['Isquiotibiais'],
                'description' => 'Versão de peso corporal do hip thrust para ativação dos glúteos.',
                'execution_steps' => [
                    'Deite de costas com os joelhos dobrados e pés apoiados no chão.',
                    'Empurre os quadris para cima contraindo os glúteos.',
                    'Suba até o corpo formar uma linha reta dos ombros aos joelhos.',
                    'Desça de forma controlada sem tocar completamente o chão.',
                ],
                'common_mistakes' => [
                    'Usar a lombar em vez dos glúteos para elevar o quadril.',
                    'Não completar a contração dos glúteos no topo.',
                ],
                'tips' => [
                    'Excelente exercício de ativação para iniciantes.',
                    'Execute pausas de 2 segundos no topo para maior ativação.',
                ],
            ],

            'coice de burro (donkey kick)' => [
                'name' => 'Coice de burro (donkey kick)', 'primary_muscle' => 'Glúteos',
                'secondary_muscles' => [],
                'description' => 'Extensão de quadril em quatro apoios para isolamento do glúteo.',
                'execution_steps' => [
                    'Apoie-se em quatro apoios com as costas retas.',
                    'Eleve um joelho dobrado para trás e para cima, pressionando o calcanhar ao teto.',
                    'Contraia o glúteo no ponto mais alto.',
                    'Desça de forma controlada sem apoiar o joelho no chão.',
                ],
                'common_mistakes' => [
                    'Rotar o quadril ao elevar a perna.',
                    'Arquear excessivamente a lombar.',
                ],
                'tips' => [
                    'Mantenha o core ativado para estabilizar o tronco.',
                    'Adicione elástico no joelho para aumentar a resistência.',
                ],
            ],

            // ── ABDÔMEN ───────────────────────────────────────────────────────

            'crunch abdominal' => [
                'name' => 'Crunch abdominal', 'primary_muscle' => 'Abdômen',
                'secondary_muscles' => [],
                'description' => 'Exercício clássico de isolamento para o reto abdominal.',
                'execution_steps' => [
                    'Deite de costas com os joelhos dobrados e pés apoiados no chão.',
                    'Coloque as mãos atrás da cabeça ou cruzadas no peito.',
                    'Contraia o abdômen elevando os ombros do chão.',
                    'Eleve até o ponto de máxima contração abdominal.',
                    'Desça de forma controlada sem relaxar completamente o abdômen.',
                ],
                'common_mistakes' => [
                    'Puxar o pescoço com as mãos durante a execução.',
                    'Elevar excessivamente o tronco, ativando os flexores do quadril.',
                ],
                'tips' => [
                    'Foque em enrolar o tronco, não em sentar completamente.',
                    'Expire ao contrair e inspire ao descer.',
                ],
            ],

            'prancha frontal' => [
                'name' => 'Prancha frontal', 'primary_muscle' => 'Abdômen',
                'secondary_muscles' => ['Glúteos', 'Ombro'],
                'description' => 'Exercício isométrico de estabilização do core.',
                'execution_steps' => [
                    'Apoie os antebraços no chão com os cotovelos sob os ombros.',
                    'Estenda as pernas atrás apoiando na ponta dos pés.',
                    'Mantenha o corpo em linha reta da cabeça aos calcanhares.',
                    'Contraia o abdômen, glúteos e quadríceps durante a isometria.',
                    'Segure pelo tempo determinado respirando de forma controlada.',
                ],
                'common_mistakes' => [
                    'Deixar o quadril subir formando um triângulo.',
                    'Deixar o quadril cair causando compressão lombar.',
                ],
                'tips' => [
                    'Imagine encolher o umbigo em direção à coluna.',
                    'Progrida aumentando o tempo gradualmente.',
                ],
            ],

            'elevação de pernas' => [
                'name' => 'Elevação de pernas', 'primary_muscle' => 'Abdômen',
                'secondary_muscles' => [],
                'description' => 'Exercício para abdômen inferior com elevação dos membros inferiores.',
                'execution_steps' => [
                    'Deite de costas com os braços ao lado do corpo ou sob os glúteos.',
                    'Mantenha as pernas juntas e levemente dobradas.',
                    'Eleve as pernas até ficarem perpendiculares ao chão.',
                    'Desça de forma controlada sem tocar o chão.',
                ],
                'common_mistakes' => [
                    'Arquear a lombar ao descer as pernas.',
                    'Usar o impulso para elevar as pernas.',
                ],
                'tips' => [
                    'Prense a lombar no chão durante todo o exercício.',
                    'Faça com os joelhos dobrados como progressão inicial.',
                ],
            ],

            'bicicleta abdominal' => [
                'name' => 'Bicicleta abdominal', 'primary_muscle' => 'Abdômen',
                'secondary_muscles' => [],
                'description' => 'Exercício de rotação abdominal que ativa oblíquos e reto abdominal.',
                'execution_steps' => [
                    'Deite de costas com as mãos atrás da cabeça e pernas elevadas.',
                    'Eleve os ombros do chão e aproxime o cotovelo direito do joelho esquerdo.',
                    'Simultaneamente estenda a perna direita.',
                    'Alterne o movimento como se estivesse pedalando uma bicicleta.',
                ],
                'common_mistakes' => [
                    'Puxar o pescoço com as mãos.',
                    'Não rotar completamente o tronco em cada lado.',
                ],
                'tips' => [
                    'Execute de forma lenta para maximizar a ativação dos oblíquos.',
                    'Mantenha os cotovelos abertos durante o exercício.',
                ],
            ],

            'russian twist' => [
                'name' => 'Russian twist', 'primary_muscle' => 'Abdômen',
                'secondary_muscles' => [],
                'description' => 'Rotação de tronco para trabalho dos oblíquos.',
                'execution_steps' => [
                    'Sente-se com os joelhos dobrados e os pés levemente elevados do chão.',
                    'Incline o tronco levemente para trás mantendo as costas retas.',
                    'Gire o tronco de um lado para o outro tocando as mãos no chão.',
                    'Mantenha o abdômen contraído durante todo o movimento.',
                ],
                'common_mistakes' => [
                    'Mover apenas os braços sem rotar o tronco.',
                    'Arredondar as costas durante o exercício.',
                ],
                'tips' => [
                    'Aumente a dificuldade segurando um halter ou medicine ball.',
                    'Foque na rotação do tronco, não dos braços.',
                ],
            ],

            'abdominal oblíquo com halter' => [
                'name' => 'Abdominal oblíquo com halter', 'primary_muscle' => 'Abdômen',
                'secondary_muscles' => [],
                'description' => 'Inclinação lateral para fortalecimento dos oblíquos.',
                'execution_steps' => [
                    'Fique em pé com um halter em uma das mãos.',
                    'Incline o tronco lateralmente em direção ao halter.',
                    'Retorne à posição ereta contraindo o oblíquo oposto.',
                    'Complete as repetições e troque de lado.',
                ],
                'common_mistakes' => [
                    'Inclinar o tronco para frente durante o movimento.',
                    'Usar o impulso do quadril.',
                ],
                'tips' => [
                    'Fortaleça os oblíquos para melhor estabilidade da coluna.',
                    'Mantenha o movimento no plano frontal puro.',
                ],
            ],

            'dead bug' => [
                'name' => 'Dead bug', 'primary_muscle' => 'Abdômen',
                'secondary_muscles' => [],
                'description' => 'Exercício de estabilização do core profundo em decúbito dorsal.',
                'execution_steps' => [
                    'Deite de costas com os braços estendidos para cima e pernas em 90°.',
                    'Prense a lombar contra o chão contraindo o core.',
                    'Simultaneamente abaixe o braço direito atrás da cabeça e estenda a perna esquerda.',
                    'Retorne à posição inicial e alterne os lados.',
                ],
                'common_mistakes' => [
                    'Deixar a lombar se afastar do chão durante o movimento.',
                    'Não coordenar corretamente braço e perna opostos.',
                ],
                'tips' => [
                    'A lombar no chão é o ponto de controle principal.',
                    'Ideal para reabilitação e fortalecimento do core profundo.',
                ],
            ],

            // ── CARDIO ────────────────────────────────────────────────────────

            'corrida na esteira' => [
                'name' => 'Corrida na esteira', 'primary_muscle' => 'Cardio',
                'secondary_muscles' => ['Pernas', 'Glúteos'],
                'description' => 'Corrida em esteira para desenvolvimento cardiovascular e queima calórica.',
                'execution_steps' => [
                    'Ajuste a velocidade e a inclinação conforme o nível e objetivo.',
                    'Inicie caminhando por 3 a 5 minutos como aquecimento.',
                    'Aumente a velocidade para a corrida no ritmo desejado.',
                    'Mantenha postura ereta, olhar à frente e braços em movimento natural.',
                    'Finalize reduzindo a velocidade gradualmente para resfriamento.',
                ],
                'common_mistakes' => [
                    'Segurar nas barras laterais, reduzindo o trabalho cardiovascular.',
                    'Começar em velocidade muito alta sem aquecimento.',
                ],
                'tips' => [
                    'A inclinação de 1 a 2% simula melhor a corrida ao ar livre.',
                    'Monitore a frequência cardíaca para manter a zona alvo.',
                ],
            ],

            'bicicleta ergométrica' => [
                'name' => 'Bicicleta ergométrica', 'primary_muscle' => 'Cardio',
                'secondary_muscles' => ['Pernas'],
                'description' => 'Exercício cardiovascular de baixo impacto na bicicleta estacionária.',
                'execution_steps' => [
                    'Ajuste o selim na altura correta com leve flexão do joelho na extensão.',
                    'Ajuste a resistência conforme o nível desejado.',
                    'Pedale de forma contínua e rítmica mantendo boa postura.',
                    'Mantenha o tronco levemente inclinado e cotovelos suavemente dobrados.',
                ],
                'common_mistakes' => [
                    'Ajustar o selim muito baixo, sobrecarregando os joelhos.',
                    'Pedalar apenas com os dedos em vez de todo o pé.',
                ],
                'tips' => [
                    'Baixo impacto nas articulações — ideal para recuperação.',
                    'Varie entre ritmo constante e intervalos de alta intensidade.',
                ],
            ],

            'elíptico' => [
                'name' => 'Elíptico', 'primary_muscle' => 'Cardio',
                'secondary_muscles' => ['Pernas', 'Ombro'],
                'description' => 'Exercício cardiovascular de impacto zero que combina membros superiores e inferiores.',
                'execution_steps' => [
                    'Suba no elíptico e segure as barras móveis.',
                    'Ajuste a resistência e inclinação conforme o nível.',
                    'Inicie o movimento elíptico com as pernas sincronizando com os braços.',
                    'Mantenha postura ereta sem apoiar o peso nas barras.',
                ],
                'common_mistakes' => [
                    'Apoiar o peso nas barras em vez de usar as pernas.',
                    'Não sincronizar o movimento de braços e pernas.',
                ],
                'tips' => [
                    'Pedalar no sentido reverso ativa grupos musculares diferentes.',
                    'Mantenha o core ativado para melhor aproveitamento.',
                ],
            ],

            'corda de pular' => [
                'name' => 'Corda de pular', 'primary_muscle' => 'Cardio',
                'secondary_muscles' => ['Pernas', 'Ombro'],
                'description' => 'Exercício cardiovascular clássico de alta intensidade e coordenação.',
                'execution_steps' => [
                    'Segure as alças da corda com as mãos na altura do quadril.',
                    'Gire a corda com os pulsos em movimento circular.',
                    'Salte sobre a corda com ambos os pés simultaneamente.',
                    'Mantenha os joelhos levemente dobrados ao pousar.',
                ],
                'common_mistakes' => [
                    'Usar os ombros em vez dos pulsos para girar a corda.',
                    'Saltar muito alto, desperdiçando energia.',
                ],
                'tips' => [
                    'Comece com séries de 30 segundos e aumente progressivamente.',
                    'Varie com pulos alternados e em velocidade.',
                ],
            ],

            'remo ergométrico' => [
                'name' => 'Remo ergométrico', 'primary_muscle' => 'Cardio',
                'secondary_muscles' => ['Costas', 'Pernas'],
                'description' => 'Exercício cardiovascular completo que trabalha 86% da musculatura corporal.',
                'execution_steps' => [
                    'Sente-se no remo ergométrico e prenda os pés nas plataformas.',
                    'Segure o guidão com os braços estendidos e o tronco levemente inclinado à frente.',
                    'Empurre com as pernas estendendo-as, depois recline o tronco e puxe o guidão para o abdômen.',
                    'Retorne estendendo os braços, inclinando o tronco e flexionando os joelhos.',
                ],
                'common_mistakes' => [
                    'Puxar com os braços antes de estender as pernas.',
                    'Arredondar as costas durante o movimento.',
                ],
                'tips' => [
                    'A sequência correta é: pernas → tronco → braços.',
                    'Mantenha um ritmo constante e controlado.',
                ],
            ],

            'escada rolante' => [
                'name' => 'Escada rolante', 'primary_muscle' => 'Cardio',
                'secondary_muscles' => ['Glúteos', 'Pernas'],
                'description' => 'Cardio de baixo impacto com forte ativação de glúteos e pernas.',
                'execution_steps' => [
                    'Suba na escada rolante e ajuste a velocidade conforme o nível.',
                    'Fique com a postura ereta, sem se apoiar nas barras.',
                    'Suba os degraus de forma contínua e cadenciada.',
                    'Mantenha o olhar à frente e o core ativado.',
                ],
                'common_mistakes' => [
                    'Apoiar-se nas barras laterais para reduzir o esforço.',
                    'Dar passos muito pequenos, reduzindo a ativação de glúteos.',
                ],
                'tips' => [
                    'Pular degraus aumenta a ativação dos glúteos.',
                    'Mantenha a postura ereta para maior eficiência.',
                ],
            ],

            'caminhada inclinada' => [
                'name' => 'Caminhada inclinada', 'primary_muscle' => 'Cardio',
                'secondary_muscles' => ['Glúteos', 'Pernas'],
                'description' => 'Caminhada em esteira com inclinação elevada para queima calórica e glúteos.',
                'execution_steps' => [
                    'Configure a esteira com inclinação entre 10 e 15% e velocidade de caminhada.',
                    'Fique com a postura ereta sem se apoiar nas barras.',
                    'Caminhe de forma contínua mantendo passadas regulares.',
                    'Mantenha os braços em movimento natural.',
                ],
                'common_mistakes' => [
                    'Apoiar-se nas barras laterais, anulando o benefício da inclinação.',
                    'Usar velocidade muito alta que force uma corrida.',
                ],
                'tips' => [
                    'Popularizada como "12-3-30": 12% inclinação, 5 km/h, 30 minutos.',
                    'Excelente opção de cardio de baixo impacto com alto gasto calórico.',
                ],
            ],

            'burpee (hiit)' => [
                'name' => 'Burpee (HIIT)', 'primary_muscle' => 'Cardio',
                'secondary_muscles' => ['Peito', 'Pernas', 'Ombro'],
                'description' => 'Exercício de alta intensidade que combina agachamento, prancha, flexão e salto.',
                'execution_steps' => [
                    'Fique em pé com os pés na largura dos ombros.',
                    'Desça as mãos ao chão e salte os pés para trás em posição de prancha.',
                    'Execute uma flexão de braços (opcional).',
                    'Salte os pés de volta para próximo das mãos.',
                    'Salte para cima com os braços acima da cabeça.',
                ],
                'common_mistakes' => [
                    'Não manter a posição de prancha ao estender as pernas.',
                    'Pousar com os joelhos travados nos saltos.',
                ],
                'tips' => [
                    'Execute em intervalos: 20-40s de trabalho e 10-20s de descanso.',
                    'Adapte removendo o salto ou a flexão para reduzir a intensidade.',
                ],
            ],

            'puxada neutra na polia' => [
                'name' => 'Puxada neutra na polia', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Bíceps'],
                'description' => 'Puxada com pegada neutra para desenvolvimento do dorsal com menor estresse nos pulsos.',
                'execution_steps' => [
                    'Sente-se na máquina e segure o triângulo com pegada neutra.',
                    'Mantenha o tronco levemente inclinado para trás.',
                    'Puxe o triângulo em direção ao peito inferior, cotovelos próximos ao corpo.',
                    'Contraia o grande dorsal e retorne controlando.',
                ],
                'common_mistakes' => [
                    'Inclinar excessivamente o tronco para trás ao puxar.',
                    'Usar apenas a força dos bíceps sem ativar o dorsal.',
                ],
                'tips' => [
                    'A pegada neutra reduz o estresse nos pulsos e cotovelos.',
                    'Foque em puxar pelos cotovelos para baixo e para trás.',
                ],
            ],

            'remada cavalinho (t-bar)' => [
                'name' => 'Remada cavalinho (T-bar)', 'primary_muscle' => 'Costas',
                'secondary_muscles' => ['Bíceps', 'Trapézio'],
                'description' => 'Remada em T-bar para desenvolvimento do dorsal e espessura das costas.',
                'execution_steps' => [
                    'Posicione-se sobre a barra em T com os pés na largura dos ombros.',
                    'Incline o tronco a cerca de 45° mantendo as costas retas.',
                    'Puxe a barra em direção ao peito, contraindo as escápulas.',
                    'Segure a contração por 1 segundo no ponto mais alto e desça controlando.',
                ],
                'common_mistakes' => [
                    'Arredondar a região lombar durante o exercício.',
                    'Não contrair as escápulas no ponto de maior ativação.',
                ],
                'tips' => [
                    'Mantenha o abdômen contraído para proteger a coluna.',
                    'Use straps para melhorar a pegada em cargas pesadas.',
                ],
            ],

            'panturrilha sentado na máquina' => [
                'name' => 'Panturrilha sentado na máquina', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => [],
                'description' => 'Exercício para o sóleo com os joelhos dobrados, complementar à panturrilha em pé.',
                'execution_steps' => [
                    'Sente-se com as almofadas sobre os joelhos.',
                    'Posicione as pontas dos pés na plataforma.',
                    'Desça os calcanhares para o alongamento completo.',
                    'Empurre os calcanhares para cima contraindo as panturrilhas e segure no topo.',
                ],
                'common_mistakes' => [
                    'Não completar o alongamento na fase inferior.',
                    'Executar de forma muito rápida.',
                ],
                'tips' => [
                    'Foca mais no sóleo que a panturrilha em pé.',
                    'Combine as duas variações para desenvolvimento completo.',
                ],
            ],

            'agachamento sumô com barra' => [
                'name' => 'Agachamento sumô com barra', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => ['Glúteos', 'Adutores'],
                'description' => 'Agachamento com stance largo para maior ativação de adutores e glúteos.',
                'execution_steps' => [
                    'Posicione os pés mais largos que os ombros com os dedos apontados para fora.',
                    'Posicione a barra nos trapézios.',
                    'Desça o corpo mantendo o peito alto e joelhos alinhados com os dedos dos pés.',
                    'Desça até as coxas ficarem paralelas ao chão.',
                    'Empurre o chão para subir contraindo adutores e glúteos.',
                ],
                'common_mistakes' => [
                    'Não manter os joelhos alinhados com os dedos dos pés.',
                    'Levantar os calcanhares durante a descida.',
                ],
                'tips' => [
                    'Ativa mais os adutores e glúteos que o agachamento convencional.',
                    'Ajuste a abertura dos pés conforme sua mobilidade.',
                ],
            ],

            'agachamento frontal com barra' => [
                'name' => 'Agachamento frontal com barra', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => ['Glúteos', 'Core'],
                'description' => 'Agachamento com barra posicionada na frente para maior ativação dos quadríceps.',
                'execution_steps' => [
                    'Segure a barra na parte frontal dos ombros com cotovelos apontados para frente.',
                    'Fique em pé com os pés na largura dos ombros.',
                    'Desça mantendo o tronco muito ereto.',
                    'Desça até as coxas ficarem paralelas ou abaixo do chão.',
                    'Empurre de volta mantendo os cotovelos elevados.',
                ],
                'common_mistakes' => [
                    'Deixar os cotovelos caírem, perdendo o controle da barra.',
                    'Inclinar o tronco excessivamente para frente.',
                ],
                'tips' => [
                    'Requer mobilidade de tornozelo e ombros.',
                    'Comece com barra vazia para aprender o padrão.',
                ],
            ],

            'agachamento hack na máquina' => [
                'name' => 'Agachamento hack na máquina', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => ['Glúteos'],
                'description' => 'Agachamento na máquina hack com estabilização das costas.',
                'execution_steps' => [
                    'Posicione-se com as costas apoiadas e os pés na plataforma.',
                    'Destrave a máquina e flexione os joelhos descendo.',
                    'Desça até os joelhos atingirem aproximadamente 90°.',
                    'Empurre a plataforma de volta mantendo as costas no suporte.',
                ],
                'common_mistakes' => [
                    'Deixar os joelhos colapsarem para dentro.',
                    'Não manter as costas em contato com o suporte.',
                ],
                'tips' => [
                    'Pés mais à frente ativa mais glúteos; mais embaixo ativa mais quadríceps.',
                    'Ótima alternativa para quem tem dificuldade com o agachamento livre.',
                ],
            ],

            'step-up no banco' => [
                'name' => 'Step-up no banco', 'primary_muscle' => 'Pernas',
                'secondary_muscles' => ['Glúteos'],
                'description' => 'Exercício funcional unilateral com subida em banco.',
                'execution_steps' => [
                    'Fique em pé diante de um banco com halteres nas mãos.',
                    'Suba com um pé no banco e empurre o corpo com aquela perna.',
                    'Traga o outro pé para cima do banco.',
                    'Desça de forma controlada com o pé que subiu por último.',
                ],
                'common_mistakes' => [
                    'Usar o pé do chão para impulsionar em vez da perna no banco.',
                    'Deixar o joelho do lado que sobe colapsar para dentro.',
                ],
                'tips' => [
                    'Excelente para força e equilíbrio unilateral.',
                    'O banco deve ter altura suficiente para desafiar o quadril.',
                ],
            ],

        ];
    }
}
