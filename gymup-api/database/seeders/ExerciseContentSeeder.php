<?php

namespace Database\Seeders;

use App\Models\Exercise;
use Illuminate\Database\Seeder;

/**
 * Populates description, primary_muscle, secondary_muscles,
 * execution_steps, common_mistakes and tips for every exercise.
 *
 * Safe to re-run: uses whereIn('name', ...) + update() so duplicates
 * (same name, multiple IDs) all receive the same correct content.
 */
class ExerciseContentSeeder extends Seeder
{
    public function run(): void
    {
        foreach ($this->data() as $entry) {
            $names = (array) $entry['name'];

            Exercise::whereIn('name', $names)->update([
                'description'       => $entry['description'],
                'primary_muscle'    => $entry['primary_muscle'],
                'secondary_muscles' => json_encode($entry['secondary_muscles']),
                'execution_steps'   => json_encode($entry['execution_steps']),
                'common_mistakes'   => json_encode($entry['common_mistakes']),
                'tips'              => json_encode($entry['tips']),
            ]);
        }

        $this->command->info('ExerciseContentSeeder: conteúdo aplicado com sucesso.');
    }

    // ── Data ──────────────────────────────────────────────────────────────────

    private function data(): array
    {
        return [

            // ── ABDÔMEN ───────────────────────────────────────────────────────

            [
                'name'             => 'Prancha',
                'description'      => 'Exercício isométrico que fortalece todo o núcleo do corpo, incluindo abdômen, lombar e glúteos. Excelente para estabilidade e postura.',
                'primary_muscle'   => 'Abdômen',
                'secondary_muscles'=> ['Lombar', 'Glúteos', 'Ombros'],
                'execution_steps'  => [
                    'Apoie os antebraços no chão com os cotovelos diretamente abaixo dos ombros.',
                    'Estenda as pernas para trás, apoiando-se nas pontas dos pés.',
                    'Mantenha o corpo em linha reta da cabeça aos calcanhares.',
                    'Contraia o abdômen e os glúteos durante todo o exercício.',
                    'Respire de forma controlada e sustente a posição pelo tempo determinado.',
                ],
                'common_mistakes'  => [
                    'Levantar ou afundar o quadril, quebrando a linha reta do corpo.',
                    'Segurar a respiração durante o exercício.',
                    'Deixar os ombros subirem em direção às orelhas.',
                ],
                'tips'             => [
                    'Imagine que está tentando juntar os cotovelos e os pés para ativar melhor o core.',
                    'Progrida aumentando o tempo gradualmente: 20s → 30s → 45s → 60s.',
                ],
            ],

            [
                'name'             => 'Abdominal Bicicleta',
                'description'      => 'Variação do abdominal que combina rotação e elevação alternada das pernas, ativando intensamente o reto abdominal e os oblíquos.',
                'primary_muscle'   => 'Abdômen',
                'secondary_muscles'=> ['Oblíquos', 'Quadríceps', 'Hip flexors'],
                'execution_steps'  => [
                    'Deite de costas e leve as mãos atrás da cabeça, sem entrelaçar os dedos.',
                    'Eleve as pernas a 45° e flexione os joelhos alternadamente como se pedalasse.',
                    'Ao trazer o joelho direito ao peito, gire o tronco levando o cotovelo esquerdo em sua direção.',
                    'Alterne o lado de forma fluida, mantendo o ritmo controlado.',
                    'Mantenha a lombar pressionada contra o chão durante todo o movimento.',
                ],
                'common_mistakes'  => [
                    'Puxar o pescoço com as mãos, causando tensão cervical.',
                    'Fazer o movimento rápido demais, perdendo a contração muscular.',
                    'Deixar os pés tocar o chão entre as repetições.',
                ],
                'tips'             => [
                    'Foque em sentir a contração oblíqua a cada rotação, não apenas em mexer os cotovelos.',
                    'Mantenha a região lombar pressionada no chão para proteger a coluna.',
                ],
            ],

            [
                'name'             => 'Russian Twist',
                'description'      => 'Exercício de rotação do tronco que trabalha intensamente os oblíquos e o reto abdominal, com ou sem carga adicional.',
                'primary_muscle'   => 'Oblíquos',
                'secondary_muscles'=> ['Abdômen', 'Lombar', 'Hip flexors'],
                'execution_steps'  => [
                    'Sente no chão com os joelhos dobrados e os pés ligeiramente elevados ou apoiados.',
                    'Incline o tronco aproximadamente 45° em relação ao chão.',
                    'Una as mãos à frente do peito (ou segure um peso/disco).',
                    'Gire o tronco para um lado levando as mãos próximo ao quadril.',
                    'Retorne ao centro e repita para o outro lado contando uma repetição completa.',
                ],
                'common_mistakes'  => [
                    'Girar apenas os braços sem rotacionar o tronco.',
                    'Arquear excessivamente a lombar durante o exercício.',
                    'Usar carga excessiva comprometendo a amplitude do movimento.',
                ],
                'tips'             => [
                    'Para aumentar a dificuldade, eleve os pés do chão durante todo o exercício.',
                    'Mantenha o queixo afastado do peito para proteger a cervical.',
                ],
            ],

            [
                'name'             => 'Elevação de Pernas',
                'description'      => 'Exercício que isola a porção inferior do reto abdominal e os flexores do quadril, realizado deitado ou suspenso.',
                'primary_muscle'   => 'Abdômen inferior',
                'secondary_muscles'=> ['Hip flexors', 'Quadríceps'],
                'execution_steps'  => [
                    'Deite de costas com os braços ao longo do corpo ou agarrando um suporte atrás da cabeça.',
                    'Mantenha as pernas estendidas ou levemente flexionadas nos joelhos.',
                    'Contraia o abdômen e eleve as pernas até formarem 90° com o chão.',
                    'Desça as pernas de forma controlada sem deixá-las tocar o chão.',
                    'Repita o movimento mantendo a lombar pressionada contra o solo.',
                ],
                'common_mistakes'  => [
                    'Deixar a lombar se arquear no momento de descer as pernas.',
                    'Usar o balanço do corpo em vez da contração abdominal para subir as pernas.',
                    'Prender a respiração durante a execução.',
                ],
                'tips'             => [
                    'Para facilitar, dobre levemente os joelhos; para dificultar, mantenha as pernas totalmente estendidas.',
                    'Expire ao subir as pernas e inspire ao descê-las de forma controlada.',
                ],
            ],

            [
                'name'             => 'Abdominal Oblíquo',
                'description'      => 'Exercício que isola os músculos oblíquos por meio de flexão lateral do tronco, melhorando a definição e a estabilidade do core.',
                'primary_muscle'   => 'Oblíquos',
                'secondary_muscles'=> ['Abdômen', 'Lombar'],
                'execution_steps'  => [
                    'Deite de costas com os joelhos dobrados e os pés apoiados no chão.',
                    'Leve as mãos atrás da cabeça sem entrelaçar os dedos.',
                    'Contraia o abdômen e eleve o ombro direito em direção ao joelho esquerdo, girando o tronco.',
                    'Retorne ao centro de forma controlada e repita para o lado oposto.',
                    'Alterne os lados ao longo das repetições.',
                ],
                'common_mistakes'  => [
                    'Puxar a cabeça com as mãos ao invés de contrair os oblíquos.',
                    'Realizar a rotação apenas com os braços, sem engajar o core.',
                    'Subir o tronco muito alto, transformando em abdominal completo.',
                ],
                'tips'             => [
                    'Pense em levar o ombro ao joelho, não o cotovelo.',
                    'Segure a contração por 1-2 segundos no ponto máximo para maior ativação.',
                ],
            ],

            // ── CORE ──────────────────────────────────────────────────────────

            [
                'name'             => 'Abdominal',
                'description'      => 'Exercício clássico de flexão do tronco que fortalece o reto abdominal, base de qualquer programa de condicionamento físico.',
                'primary_muscle'   => 'Reto abdominal',
                'secondary_muscles'=> ['Oblíquos', 'Hip flexors'],
                'execution_steps'  => [
                    'Deite de costas com os joelhos dobrados, pés apoiados no chão na largura do quadril.',
                    'Leve as mãos atrás da cabeça ou cruze no peito.',
                    'Contraia o abdômen e eleve o tronco em direção aos joelhos, mantendo a lombar próxima ao chão.',
                    'Suba até sentir a contração máxima (não precisa sentar completamente).',
                    'Desça de forma lenta e controlada sem relaxar o abdômen.',
                ],
                'common_mistakes'  => [
                    'Puxar o pescoço com as mãos, causando lesão cervical.',
                    'Usar impulso e balanço ao invés de contrair o abdômen.',
                    'Executar a amplitude completa sem controlar o movimento de descida.',
                ],
                'tips'             => [
                    'Expire ao subir e inspire ao descer para melhorar a contração.',
                    'Para aumentar a dificuldade, segure um peso no peito ou realize em superfície inclinada.',
                ],
            ],

            // ── BÍCEPS ────────────────────────────────────────────────────────

            [
                'name'             => 'Rosca Direta',
                'description'      => 'Exercício fundamental para hipertrofia dos bíceps, realizado com barra reta ou W, que permite carga elevada e grande amplitude de movimento.',
                'primary_muscle'   => 'Bíceps braquial',
                'secondary_muscles'=> ['Braquial', 'Braquiorradial', 'Antebraço'],
                'execution_steps'  => [
                    'Fique em pé com a barra nas mãos em pegada supinada (palmas para cima), na largura dos ombros.',
                    'Mantenha os cotovelos fixos ao lado do tronco durante todo o exercício.',
                    'Contraia os bíceps e flexione os cotovelos, elevando a barra em arco até próximo ao peito.',
                    'Segure por 1 segundo no ponto de máxima contração.',
                    'Desça a barra de forma lenta e controlada até a extensão quase completa dos braços.',
                ],
                'common_mistakes'  => [
                    'Balançar o tronco para trás para ajudar a subir a carga, tirando o foco dos bíceps.',
                    'Não completar a extensão na descida, reduzindo a amplitude do exercício.',
                    'Mover os cotovelos para frente durante a subida.',
                ],
                'tips'             => [
                    'Apoie as costas na parede para eliminar o balanço do tronco e isolar melhor os bíceps.',
                    'A fase excêntrica (descida) deve durar pelo menos 2-3 segundos para máximo estímulo.',
                ],
            ],

            [
                'name'             => 'Rosca Alternada com Halteres',
                'description'      => 'Variação unilateral da rosca que permite maior amplitude de movimento e supinação do punho, aumentando o pico de contração dos bíceps.',
                'primary_muscle'   => 'Bíceps braquial',
                'secondary_muscles'=> ['Braquial', 'Braquiorradial', 'Antebraço'],
                'execution_steps'  => [
                    'Fique em pé ou sente em um banco com um halter em cada mão, palmas voltadas para o corpo.',
                    'Mantendo o cotovelo fixo, comece a rosca girando o punho (supinação) ao longo do movimento.',
                    'Eleve o halter até próximo ao ombro com a palma voltada para cima no topo.',
                    'Segure brevemente no topo e desça de forma controlada.',
                    'Alterne os braços a cada repetição.',
                ],
                'common_mistakes'  => [
                    'Não realizar a supinação do punho, reduzindo a ativação dos bíceps.',
                    'Balançar o tronco ou elevar o cotovelo para ganhar impulso.',
                    'Fazer as repetições rápidas demais sem controlar a fase excêntrica.',
                ],
                'tips'             => [
                    'A supinação (giro do punho) no início do movimento é o que diferencia este exercício de outros.',
                    'Realizar sentado elimina a tendência de balançar o corpo.',
                ],
            ],

            [
                'name'             => 'Rosca Martelo',
                'description'      => 'Rosca com pegada neutra (palmas voltadas uma para outra) que trabalha bíceps, braquial e braquiorradial de forma equilibrada.',
                'primary_muscle'   => 'Braquiorradial',
                'secondary_muscles'=> ['Bíceps braquial', 'Braquial', 'Antebraço'],
                'execution_steps'  => [
                    'Fique em pé com um halter em cada mão e a pegada neutra (palmas uma para a outra).',
                    'Mantenha os cotovelos fixos ao lado do corpo.',
                    'Flexione um cotovelo de cada vez (alternado) ou ambos simultaneamente.',
                    'Suba o halter mantendo a pegada neutra até o ponto de máxima contração.',
                    'Desça de forma controlada e repita.',
                ],
                'common_mistakes'  => [
                    'Girar o punho durante o movimento, transformando em rosca alternada.',
                    'Balançar o corpo para ganhar impulso na subida.',
                    'Afastar os cotovelos do corpo durante a execução.',
                ],
                'tips'             => [
                    'A rosca martelo é mais segura para os pulsos que a rosca direta em alguns casos.',
                    'Pode ser realizada sentado para maior isolamento e estabilidade.',
                ],
            ],

            [
                'name'             => 'Rosca Concentrada',
                'description'      => 'Exercício de alto isolamento dos bíceps realizado apoiando o cotovelo na parte interna da coxa, permitindo máximo pico de contração.',
                'primary_muscle'   => 'Bíceps braquial',
                'secondary_muscles'=> ['Braquial'],
                'execution_steps'  => [
                    'Sente no banco inclinando ligeiramente o tronco à frente.',
                    'Apoie o cotovelo direito na face interna da coxa direita com o halter na mão.',
                    'Mantenha a mão livre apoiada no joelho para estabilidade.',
                    'Flexione o cotovelo levando o halter ao ombro, supinando levemente o punho no topo.',
                    'Desça de forma lenta e controlada sem deixar o cotovelo sair do apoio.',
                ],
                'common_mistakes'  => [
                    'Elevar o cotovelo do apoio durante a subida.',
                    'Não completar a extensão total do braço na descida.',
                    'Usar carga excessiva que compromete a técnica de isolamento.',
                ],
                'tips'             => [
                    'Segure a contração máxima por 1-2 segundos a cada repetição para maior ativação.',
                    'Use carga moderada — este exercício é de isolamento, não de força máxima.',
                ],
            ],

            [
                'name'             => 'Rosca Scott',
                'description'      => 'Rosca realizada no banco Scott (preacher bench) que elimina compensações do tronco e isola completamente os bíceps, especialmente a cabeça longa.',
                'primary_muscle'   => 'Bíceps braquial',
                'secondary_muscles'=> ['Braquial', 'Braquiorradial'],
                'execution_steps'  => [
                    'Ajuste o banco Scott para que a parte superior dos braços fique completamente apoiada.',
                    'Pegue a barra em pegada supinada (palmas para cima) na largura dos ombros.',
                    'Partindo da extensão quase completa, flexione os cotovelos elevando a barra.',
                    'Suba até próximo ao queixo sem perder o apoio dos tríceps no banco.',
                    'Desça de forma lenta e controlada até a quase extensão completa.',
                ],
                'common_mistakes'  => [
                    'Soltar o peso rapidamente na fase excêntrica, perdendo o estímulo muscular.',
                    'Levantar os braços do banco para conseguir subir a carga.',
                    'Ir até a extensão completa (pode causar lesão na articulação do cotovelo).',
                ],
                'tips'             => [
                    'A fase excêntrica (descida) é tão importante quanto a concêntrica — faça devagar.',
                    'O banco Scott elimina o balanço, então use carga compatível com o isolamento real.',
                ],
            ],

            // ── CARDIO ────────────────────────────────────────────────────────

            [
                'name'             => 'Esteira',
                'description'      => 'Exercício cardiovascular realizado em esteira ergométrica, ideal para queima de calorias, melhora da resistência cardiovascular e controle do peso.',
                'primary_muscle'   => 'Quadríceps',
                'secondary_muscles'=> ['Glúteos', 'Isquiotibiais', 'Panturrilha', 'Core'],
                'execution_steps'  => [
                    'Suba na esteira e ajuste a velocidade inicial em um ritmo leve de aquecimento (4-5 km/h).',
                    'Mantenha o corpo ereto com os ombros relaxados e o olhar à frente.',
                    'Aumente a velocidade progressivamente conforme o aquecimento progredir.',
                    'Balanceie os braços naturalmente acompanhando o ritmo das pernas.',
                    'Ao finalizar, reduza gradualmente a velocidade para um resfriamento adequado.',
                ],
                'common_mistakes'  => [
                    'Segurar nas barras laterais, o que reduz a queima calórica e compromete a postura.',
                    'Dar passadas muito curtas ou muito longas — mantenha uma cadência natural.',
                    'Começar em velocidade alta sem aquecimento prévio.',
                ],
                'tips'             => [
                    'Varie a inclinação (0-5%) para aumentar a intensidade sem aumentar o impacto nas articulações.',
                    'Use a zona alvo de frequência cardíaca (60-80% da FCmax) para melhor desempenho aeróbico.',
                ],
            ],

            [
                'name'             => 'Bike Ergométrica',
                'description'      => 'Exercício cardiovascular de baixo impacto em bicicleta ergométrica, excelente para saúde cardiovascular, queima calórica e recuperação ativa.',
                'primary_muscle'   => 'Quadríceps',
                'secondary_muscles'=> ['Isquiotibiais', 'Glúteos', 'Panturrilha'],
                'execution_steps'  => [
                    'Ajuste o banco para que o joelho fique levemente dobrado no ponto mais baixo do pedal.',
                    'Sente com a coluna ereta e as mãos relaxadas no guidão.',
                    'Pedale em ritmo constante, mantendo uma cadência de 60-80 RPM.',
                    'Aumente a resistência progressivamente para elevar a intensidade.',
                    'Mantenha a respiração rítmica durante toda a sessão.',
                ],
                'common_mistakes'  => [
                    'Ajustar o banco muito baixo, causando estresse excessivo no joelho.',
                    'Pedalear apenas com as pontas dos pés em vez de usar todo o pé.',
                    'Curvar excessivamente a coluna sobre o guidão.',
                ],
                'tips'             => [
                    'O ajuste correto do banco é fundamental: joelho levemente dobrado no ponto mais baixo.',
                    'Ideal para quem tem problemas nas articulações — impacto quase zero.',
                ],
            ],

            [
                'name'             => 'Corda',
                'description'      => 'Exercício cardiovascular de alta intensidade com corda de pular, que melhora coordenação, agilidade, resistência e queima grande quantidade de calorias.',
                'primary_muscle'   => 'Panturrilha',
                'secondary_muscles'=> ['Quadríceps', 'Ombros', 'Core', 'Antebraço'],
                'execution_steps'  => [
                    'Segure as alças da corda com as mãos na altura do quadril, cotovelos próximos ao corpo.',
                    'Fique em pé com os pés juntos ou ligeiramente afastados.',
                    'Gire a corda com os pulsos e salte com ambos os pés simultaneamente.',
                    'Aterrisse suavemente nas pontas dos pés, amortecendo o impacto com os joelhos levemente dobrados.',
                    'Mantenha o ritmo constante e a postura ereta durante a sessão.',
                ],
                'common_mistakes'  => [
                    'Saltar muito alto — o salto deve ser mínimo, apenas o suficiente para a corda passar.',
                    'Girar a corda com os braços inteiros em vez dos pulsos.',
                    'Não amortizar a aterrissagem, sobrecarregando joelhos e tornozelos.',
                ],
                'tips'             => [
                    'Comece com séries de 30 segundos e descanse 30 segundos; aumente progressivamente.',
                    'Varie o estilo: pés alternados, joelhos altos, duplo giro — para maior desafio.',
                ],
            ],

            [
                'name'             => 'Corrida Leve',
                'description'      => 'Corrida em ritmo moderado (5-7 km/h) que desenvolve resistência aeróbica, melhora a saúde cardiovascular e serve como base para treinos mais intensos.',
                'primary_muscle'   => 'Quadríceps',
                'secondary_muscles'=> ['Isquiotibiais', 'Glúteos', 'Panturrilha', 'Core'],
                'execution_steps'  => [
                    'Inicie com 5 minutos de caminhada para aquecimento articular.',
                    'Aumente o ritmo para uma corrida leve onde ainda consiga conversar.',
                    'Mantenha a postura ereta, ombros relaxados e braços em 90°.',
                    'Pise com o meio do pé (não o calcanhar) para menor impacto.',
                    'Finalize com 5 minutos de caminhada para desaceleração gradual.',
                ],
                'common_mistakes'  => [
                    'Correr com ritmo muito alto no início, levando à fadiga precoce.',
                    'Passadas muito longas — prefira passadas curtas e frequentes.',
                    'Ignorar o aquecimento e o resfriamento ao redor da corrida.',
                ],
                'tips'             => [
                    'O ritmo correto é conversacional: se não consegue falar, está correndo rápido demais.',
                    'Hidrate-se antes, durante (a cada 15 min) e após a corrida.',
                ],
            ],

            [
                'name'             => 'Elíptico',
                'description'      => 'Equipamento cardiovascular de baixíssimo impacto que simula a corrida preservando as articulações, ideal para reabilitação e condicionamento.',
                'primary_muscle'   => 'Quadríceps',
                'secondary_muscles'=> ['Glúteos', 'Isquiotibiais', 'Panturrilha', 'Ombros', 'Core'],
                'execution_steps'  => [
                    'Posicione os pés nas plataformas e segure as barras móveis.',
                    'Inicie o movimento em ritmo leve, coordenando braços e pernas.',
                    'Mantenha o corpo ereto, sem inclinar excessivamente para frente.',
                    'Pedale para frente para focar em glúteos e para trás para focar em isquiotibiais.',
                    'Aumente a resistência progressivamente para elevar a intensidade.',
                ],
                'common_mistakes'  => [
                    'Apoiar todo o peso do corpo nas barras, reduzindo o esforço das pernas.',
                    'Não engajar os braços — use-os ativamente para trabalhar a parte superior do corpo.',
                    'Passos muito curtos que reduzem a amplitude do movimento.',
                ],
                'tips'             => [
                    'Soltar as barras fixas e usar apenas as móveis aumenta a queima calórica.',
                    'O elíptico é ideal para quem tem problemas nos joelhos, tornozelos ou quadril.',
                ],
            ],

            [
                'name'             => 'Escada Rolante',
                'description'      => 'Exercício cardiovascular em máquina de escadas que trabalha intensamente glúteos, quadríceps e sistema cardiovascular com baixo impacto.',
                'primary_muscle'   => 'Glúteos',
                'secondary_muscles'=> ['Quadríceps', 'Isquiotibiais', 'Panturrilha', 'Core'],
                'execution_steps'  => [
                    'Suba na máquina e ajuste a velocidade inicial baixa para aquecimento.',
                    'Fique ereto, segurando levemente nos corrimãos apenas para equilíbrio.',
                    'Dê passos completos e firmes, pisando com todo o pé na plataforma.',
                    'Mantenha o ritmo constante e aumente a velocidade progressivamente.',
                    'Ao finalizar, reduza a velocidade gradualmente.',
                ],
                'common_mistakes'  => [
                    'Apoiar grande parte do peso do corpo nos corrimãos, reduzindo o esforço.',
                    'Dar passos curtos apenas com a ponta dos pés.',
                    'Inclinar excessivamente o tronco para frente.',
                ],
                'tips'             => [
                    'Para focar mais em glúteos, dê passos mais largos e incline levemente o tronco para frente.',
                    'Segure o mínimo possível nos corrimãos para maximizar o gasto calórico.',
                ],
            ],

            [
                'name'             => 'Caminhada Inclinada',
                'description'      => 'Caminhada em esteira com inclinação elevada (8-15%), que aumenta o gasto calórico e trabalha glúteos e panturrilha sem o impacto da corrida.',
                'primary_muscle'   => 'Glúteos',
                'secondary_muscles'=> ['Isquiotibiais', 'Panturrilha', 'Core'],
                'execution_steps'  => [
                    'Configure a inclinação entre 8% e 15% e a velocidade entre 4 e 6 km/h.',
                    'Mantenha o corpo ereto, sem se apoiar nas barras laterais.',
                    'Dê passadas completas, apoiando o calcanhar primeiro.',
                    'Balance os braços naturalmente, podendo adicioná-los ao movimento para maior gasto calórico.',
                    'Mantenha a sessão por 20-40 minutos em ritmo sustentável.',
                ],
                'common_mistakes'  => [
                    'Segurar fortemente nas barras laterais, anulando os benefícios da inclinação.',
                    'Velocidade muito alta para a inclinação usada, comprometendo a postura.',
                    'Não manter a coluna ereta durante toda a sessão.',
                ],
                'tips'             => [
                    'A caminhada inclinada queima de 50 a 100% mais calorias que caminhar plano.',
                    'Conhecida como "12-3-30": 12% inclinação, 5 km/h, 30 minutos.',
                ],
            ],

            [
                'name'             => 'Remo Ergométrico',
                'description'      => 'Exercício cardiovascular completo no remo ergométrico que trabalha aproximadamente 86% dos músculos do corpo, combinando força e resistência.',
                'primary_muscle'   => 'Costas',
                'secondary_muscles'=> ['Quadríceps', 'Glúteos', 'Core', 'Bíceps', 'Ombros'],
                'execution_steps'  => [
                    'Sente na máquina, prendendo os pés nas fixações com os joelhos dobrados.',
                    'Segure o punho com as duas mãos em pegada pronada.',
                    'Fase 1 (empurrar): estenda as pernas mantendo os braços estendidos.',
                    'Fase 2 (puxar): incline o tronco para trás e puxe o punho até o abdômen.',
                    'Retorne em ordem inversa: braços à frente → inclinar o tronco → dobrar os joelhos.',
                ],
                'common_mistakes'  => [
                    'Puxar com os braços antes de empurrar com as pernas — as pernas geram 60% da força.',
                    'Arredondar a coluna durante a fase de remada.',
                    'Ritmo muito alto que compromete a técnica — priorize a forma.',
                ],
                'tips'             => [
                    'Sequência correta: PERNAS → CORE → BRAÇOS na ida; BRAÇOS → CORE → PERNAS na volta.',
                    'Frequência ideal para iniciantes: 18-22 remadas por minuto (spm).',
                ],
            ],

            // ── COSTAS ────────────────────────────────────────────────────────

            [
                'name'             => 'Barra Fixa',
                'description'      => 'Exercício fundamental de puxada com o peso corporal, excelente para desenvolver largura e espessura das costas, além de força nos bíceps.',
                'primary_muscle'   => 'Latíssimo do dorso',
                'secondary_muscles'=> ['Romboides', 'Bíceps', 'Trapézio inferior', 'Core'],
                'execution_steps'  => [
                    'Segure a barra com pegada pronada (palmas para frente) levemente mais larga que os ombros.',
                    'Parta com os braços completamente estendidos e o corpo levemente pendulado.',
                    'Contraia as escápulas e puxe o corpo para cima levando o queixo acima da barra.',
                    'Concentre-se em puxar com as costas, não apenas com os braços.',
                    'Desça de forma lenta e controlada até a extensão completa dos braços.',
                ],
                'common_mistakes'  => [
                    'Usar impulso do corpo (kipping) em vez de força muscular pura.',
                    'Não completar a descida — amplitude completa é fundamental.',
                    'Tensionar o pescoço tentando levar o queixo acima da barra.',
                ],
                'tips'             => [
                    'Se não consegue fazer, use faixa elástica de assistência ou máquina graviton.',
                    'Pegada supinada (palmas para você) é mais fácil e ativa mais os bíceps.',
                ],
            ],

            [
                'name'             => ['Puxada na Frente', 'Puxada Unilateral'],
                'description'      => 'Exercício de puxada na polia alta que desenvolve largura das costas, simula o movimento da barra fixa com carga regulável.',
                'primary_muscle'   => 'Latíssimo do dorso',
                'secondary_muscles'=> ['Romboides', 'Bíceps', 'Trapézio inferior', 'Core'],
                'execution_steps'  => [
                    'Sente na máquina e ajuste o apoio de coxas para fixar o corpo.',
                    'Segure a barra com pegada pronada, levemente mais larga que os ombros.',
                    'Com o tronco levemente inclinado para trás, puxe a barra até a clavícula.',
                    'Conduza os cotovelos para baixo e para trás, comprimindo as escápulas.',
                    'Retorne de forma controlada à posição inicial com extensão completa dos braços.',
                ],
                'common_mistakes'  => [
                    'Puxar a barra por trás da cabeça, sobrecarregando a cervical.',
                    'Usar carga muito alta e balançar o tronco para compensar.',
                    'Não completar a extensão dos cotovelos no retorno.',
                ],
                'tips'             => [
                    'Imagine que está tentando colocar os cotovelos nos bolsos de trás da calça.',
                    'Aperte as escápulas no ponto de máxima contração para maior ativação do dorsal.',
                ],
            ],

            [
                'name'             => 'Remada Curvada com Barra',
                'description'      => 'Exercício composto de empuxo horizontal que desenvolve espessura e força das costas, trabalhando intensamente o trapézio médio e romboides.',
                'primary_muscle'   => 'Trapézio médio',
                'secondary_muscles'=> ['Latíssimo do dorso', 'Romboides', 'Bíceps', 'Eretores da espinha'],
                'execution_steps'  => [
                    'Fique em pé com a barra no chão ou em suporte, pegada pronada levemente mais larga que os ombros.',
                    'Incline o tronco entre 45° e paralelo ao chão, joelhos levemente dobrados.',
                    'Contraia o core para proteger a lombar durante todo o exercício.',
                    'Puxe a barra em direção ao abdômen inferior conduzindo os cotovelos para cima e para trás.',
                    'Comprima as escápulas no topo e desça de forma controlada.',
                ],
                'common_mistakes'  => [
                    'Arredondar a lombar — a coluna deve permanecer neutra durante todo o movimento.',
                    'Puxar com os bíceps em vez de iniciar o movimento com as escápulas.',
                    'Levantar o tronco durante a puxada, transformando em um meio levantamento terra.',
                ],
                'tips'             => [
                    'Mantenha os ombros retraídos durante toda a série para proteger a articulação.',
                    'Olhe para o chão levemente à frente, mantendo a cervical em posição neutra.',
                ],
            ],

            [
                'name'             => 'Remada com Halteres',
                'description'      => 'Variação bilateral da remada com halteres que permite maior amplitude de movimento e trabalha os músculos das costas de forma equilibrada.',
                'primary_muscle'   => 'Latíssimo do dorso',
                'secondary_muscles'=> ['Romboides', 'Bíceps', 'Trapézio médio'],
                'execution_steps'  => [
                    'Fique em pé com um halter em cada mão e incline o tronco a 45°.',
                    'Mantenha a coluna neutra e o core contraído.',
                    'Puxe ambos os halteres simultaneamente em direção ao quadril.',
                    'Conduza os cotovelos para cima e para trás, comprimindo as escápulas.',
                    'Desça os halteres de forma lenta e controlada.',
                ],
                'common_mistakes'  => [
                    'Arredondar a lombar durante a execução.',
                    'Usar impulso do corpo para subir os halteres.',
                    'Não comprimir as escápulas no ponto máximo da puxada.',
                ],
                'tips'             => [
                    'Mantenha uma curvatura natural (leve hiperlordose) na lombar durante toda a série.',
                    'Concentre-se em puxar com os cotovelos, não com as mãos.',
                ],
            ],

            [
                'name'             => 'Remada Unilateral',
                'description'      => 'Remada com um braço de cada vez com apoio no banco, que permite maior isolamento dos músculos das costas e maior amplitude de movimento.',
                'primary_muscle'   => 'Latíssimo do dorso',
                'secondary_muscles'=> ['Romboides', 'Bíceps', 'Trapézio médio', 'Core'],
                'execution_steps'  => [
                    'Apoie o joelho e a mão do lado de apoio no banco, com o tronco paralelo ao chão.',
                    'Segure o halter com a mão livre e braço completamente estendido.',
                    'Puxe o halter em direção ao quadril, conduzindo o cotovelo para cima.',
                    'Comprima a escápula no ponto máximo e segure por 1 segundo.',
                    'Desça de forma controlada até a extensão completa do braço.',
                ],
                'common_mistakes'  => [
                    'Girar o tronco para ajudar a puxar (compensação rotacional).',
                    'Puxar o halter muito para a frente em vez de em direção ao quadril.',
                    'Não controlar a descida (fase excêntrica).',
                ],
                'tips'             => [
                    'Quanto mais paralelo ao chão o tronco, maior o trabalho no dorsal.',
                    'Deixe o ombro "cair" na extensão para maximizar o alongamento do dorsal.',
                ],
            ],

            [
                'name'             => 'Remada Alta no Cabo',
                'description'      => 'Exercício de remada na polia alta que trabalha as fibras superiores do trapézio e romboides, melhorando a postura e a força da parte superior das costas.',
                'primary_muscle'   => 'Trapézio superior',
                'secondary_muscles'=> ['Romboides', 'Latíssimo do dorso', 'Bíceps', 'Deltóide posterior'],
                'execution_steps'  => [
                    'Ajuste a polia na altura mais alta e conecte uma barra reta ou corda.',
                    'Fique em pé ou sente à frente da polia e segure o acessório.',
                    'Puxe em direção ao rosto/pescoço, conduzindo os cotovelos para cima e para fora.',
                    'Comprima as escápulas no ponto máximo da contração.',
                    'Retorne de forma controlada à posição inicial.',
                ],
                'common_mistakes'  => [
                    'Puxar com os braços em vez de iniciar com a retração das escápulas.',
                    'Inclinar excessivamente o tronco para trás.',
                    'Não completar a amplitude — os cotovelos devem ultrapassar a altura dos ombros.',
                ],
                'tips'             => [
                    'Manter os cotovelos acima dos pulsos durante toda a puxada melhora o engajamento do trapézio.',
                    'Ideal para complementar exercícios de puxada vertical como a barra fixa.',
                ],
            ],

            // ── OMBROS ────────────────────────────────────────────────────────

            [
                'name'             => 'Press Militar com Barra',
                'description'      => 'Exercício composto de empurrada vertical considerado o principal para desenvolvimento dos deltóides, especialmente a porção anterior e medial.',
                'primary_muscle'   => 'Deltóide anterior',
                'secondary_muscles'=> ['Deltóide medial', 'Tríceps', 'Trapézio', 'Core'],
                'execution_steps'  => [
                    'Fique em pé com a barra na altura dos ombros, pegada pronada levemente mais larga que os ombros.',
                    'Contraia o core e mantenha a lombar em posição neutra (sem arquear excessivamente).',
                    'Empurre a barra verticalmente acima da cabeça até a extensão quase completa dos braços.',
                    'Ao passar pelo rosto, leve a cabeça levemente para trás; ao ultrapassar, leve para frente.',
                    'Desça a barra de forma controlada até a posição inicial na altura dos ombros.',
                ],
                'common_mistakes'  => [
                    'Arquear excessivamente a lombar para compensar a falta de mobilidade.',
                    'Empurrar a barra levemente para frente em vez de verticalmente.',
                    'Não ativar o core, sobrecarregando a coluna lombar.',
                ],
                'tips'             => [
                    'Realize sentado em banco com encosto para maior isolamento e segurança lombar.',
                    'Fortaleça a mobilidade do ombro e tornozelo para melhorar a técnica.',
                ],
            ],

            [
                'name'             => 'Desenvolvimento com Halteres',
                'description'      => 'Variação do desenvolvimento com halteres que oferece maior liberdade de movimento e trabalho unilateral, reduzindo desequilíbrios entre os lados.',
                'primary_muscle'   => 'Deltóide anterior',
                'secondary_muscles'=> ['Deltóide medial', 'Tríceps', 'Trapézio superior'],
                'execution_steps'  => [
                    'Sente em banco com encosto regulado a 90° segurando um halter em cada mão.',
                    'Posicione os halteres na altura dos ombros com os cotovelos dobrados e as palmas voltadas para frente.',
                    'Empurre os halteres para cima e levemente para dentro, sem bater no topo.',
                    'Mantenha o core contraído e as costas apoiadas no banco durante todo o exercício.',
                    'Desça de forma controlada até a posição inicial.',
                ],
                'common_mistakes'  => [
                    'Arquear a lombar e afastar as costas do banco para empurrar mais carga.',
                    'Juntar os halteres acima da cabeça, impactando as articulações.',
                    'Descida muito rápida sem controle da fase excêntrica.',
                ],
                'tips'             => [
                    'Girando os pulsos do início ao fim (pegada neutra → pronada), aumenta a ativação do deltóide medial.',
                    'Use amplitude completa: suba até quase tocar os halteres e desça até os ombros.',
                ],
            ],

            [
                'name'             => 'Elevação Lateral',
                'description'      => 'Exercício de isolamento para o deltóide medial que contribui para a largura visual dos ombros e uma aparência mais ombros mais largos.',
                'primary_muscle'   => 'Deltóide medial',
                'secondary_muscles'=> ['Trapézio superior', 'Deltóide anterior', 'Supra-espinhoso'],
                'execution_steps'  => [
                    'Fique em pé com os pés na largura dos ombros, segurando um halter em cada mão ao lado do corpo.',
                    'Incline levemente o tronco para frente (10-15°) e dobre ligeiramente os cotovelos.',
                    'Eleve os braços lateralmente até a altura dos ombros, com os cotovelos ligeiramente acima dos pulsos.',
                    'Segure por 1 segundo no topo e desça de forma lenta e controlada.',
                    'Mantenha o movimento controlado, sem usar impulso.',
                ],
                'common_mistakes'  => [
                    'Balançar o tronco para ganhar impulso — use carga compatível com a técnica.',
                    'Elevar os braços acima da linha dos ombros, sobrecarregando o trapézio.',
                    'Girar o punho de forma que o dedão fique para cima — incline o halter ligeiramente para frente.',
                ],
                'tips'             => [
                    'Imagine que está despejando um copo d\'água: o dedão levemente abaixo no topo.',
                    'Carga moderada com execução perfeita é superior a carga alta com balanço.',
                ],
            ],

            [
                'name'             => ['Elevação Lateral no Cabo', 'Elevação Lateral Sentado'],
                'description'      => 'Variação da elevação lateral no cabo ou sentado que mantém tensão constante no deltóide medial ao longo de toda a amplitude do movimento.',
                'primary_muscle'   => 'Deltóide medial',
                'secondary_muscles'=> ['Trapézio superior', 'Supra-espinhoso'],
                'execution_steps'  => [
                    'Posicione a polia na altura mais baixa e prenda o cabo na mão oposta ao lado da polia.',
                    'Fique em pé lateralmente à polia, segurando o cabo pelo lado oposto do corpo.',
                    'Eleve o braço lateralmente até a altura do ombro mantendo o cotovelo levemente dobrado.',
                    'Controle a descida de forma lenta e controle a tensão do cabo.',
                    'Complete as repetições e repita para o outro lado.',
                ],
                'common_mistakes'  => [
                    'Elevar o braço muito além da linha do ombro.',
                    'Usar impulso ou inclinar o tronco para ajudar na elevação.',
                    'Relaxar no ponto inicial sem manter a tensão no cabo.',
                ],
                'tips'             => [
                    'O cabo é superior aos halteres por manter tensão constante no deltóide.',
                    'A versão sentado elimina completamente o impulso corporal.',
                ],
            ],

            [
                'name'             => 'Elevação Frontal',
                'description'      => 'Exercício de isolamento que trabalha a porção anterior do deltóide, realizado com halteres, barra ou cabo.',
                'primary_muscle'   => 'Deltóide anterior',
                'secondary_muscles'=> ['Deltóide medial', 'Peitoral superior', 'Trapézio'],
                'execution_steps'  => [
                    'Fique em pé com um halter em cada mão, palmas voltadas para o corpo.',
                    'Mantenha os joelhos levemente dobrados e o core contraído.',
                    'Eleve um braço de cada vez (alternado) ou ambos juntos à frente do corpo.',
                    'Suba até a altura dos ombros (paralelo ao chão) ou levemente acima.',
                    'Desça de forma controlada sem deixar o halter balançar.',
                ],
                'common_mistakes'  => [
                    'Balançar o tronco para ajudar a elevar os halteres.',
                    'Subir além de 30° acima da linha dos ombros, transferindo o estresse para o trapézio.',
                    'Usar carga muito alta comprometendo a técnica.',
                ],
                'tips'             => [
                    'O deltóide anterior geralmente já recebe muito trabalho nos supinos — use carga moderada.',
                    'A pegada pronada (palmas para baixo) ativa mais o deltóide anterior.',
                ],
            ],

            [
                'name'             => 'Encolhimento',
                'description'      => 'Exercício específico para o trapézio superior que consiste em elevar os ombros em direção às orelhas com carga, podendo ser feito com barra ou halteres.',
                'primary_muscle'   => 'Trapézio superior',
                'secondary_muscles'=> ['Levantador da escápula', 'Romboides'],
                'execution_steps'  => [
                    'Fique em pé segurando halteres ou barra na frente do corpo, braços estendidos.',
                    'Mantenha os joelhos levemente dobrados e o core ativado.',
                    'Eleve os ombros diretamente para cima em direção às orelhas (sem girar).',
                    'Segure no topo por 1-2 segundos comprimindo o trapézio.',
                    'Desça os ombros de forma controlada até a posição inicial.',
                ],
                'common_mistakes'  => [
                    'Girar os ombros (movimento circular) — suba e desça em linha reta.',
                    'Dobrar os cotovelos durante o exercício.',
                    'Usar carga excessiva que limita a amplitude e a compressão muscular.',
                ],
                'tips'             => [
                    'Segure a contração por 2 segundos no topo para máxima ativação do trapézio.',
                    'Mantenha a cabeça centralizada e não incline o pescoço durante o exercício.',
                ],
            ],

            // ── PEITO ─────────────────────────────────────────────────────────

            [
                'name'             => 'Supino Reto',
                'description'      => 'Exercício composto fundamental para desenvolvimento do peitoral maior, especialmente a porção esternocostal, com alto potencial de carga.',
                'primary_muscle'   => 'Peitoral maior',
                'secondary_muscles'=> ['Deltóide anterior', 'Tríceps', 'Serrátil anterior'],
                'execution_steps'  => [
                    'Deite no banco plano com os pés apoiados no chão, costas em posição neutra.',
                    'Segure a barra com pegada pronada levemente mais larga que os ombros.',
                    'Destrave a barra e posicione acima do peito com os braços estendidos.',
                    'Desça a barra de forma controlada até tocar levemente o peitoral na altura dos mamilos.',
                    'Empurre a barra de volta para cima em movimento explosivo até a extensão dos braços.',
                ],
                'common_mistakes'  => [
                    'Arquear excessivamente a lombar para aumentar a carga.',
                    'Quicar a barra no peito para ganhar impulso.',
                    'Fechar os cotovelos ao corpo (muito pronados) ou abri-los demais (90°).',
                ],
                'tips'             => [
                    'Cotovelos a 45-75° do tronco é o ângulo ideal para segurança do ombro.',
                    'Aperte a barra firmemente e imagine que está tentando "dobrar" o banco para ativar mais o peitoral.',
                ],
            ],

            [
                'name'             => 'Supino Reto com Halteres',
                'description'      => 'Variação do supino com halteres que permite maior amplitude de movimento, trabalho unilateral e maior ativação estabilizadora das articulações.',
                'primary_muscle'   => 'Peitoral maior',
                'secondary_muscles'=> ['Deltóide anterior', 'Tríceps', 'Serrátil anterior'],
                'execution_steps'  => [
                    'Deite no banco com um halter em cada mão na altura do peito, cotovelos dobrados a 90°.',
                    'Empurre os halteres para cima e levemente para dentro, sem bater no topo.',
                    'Mantenha os pés apoiados no chão e as costas com leve arqueamento natural.',
                    'Desça os halteres até sentir um alongamento confortável no peitoral.',
                    'Suba de forma explosiva sem bater os halteres no topo.',
                ],
                'common_mistakes'  => [
                    'Deixar os halteres caírem muito para o lado, sobrecarregando a articulação do ombro.',
                    'Não controlar a descida, deixando os halteres cair rapidamente.',
                    'Usar carga tão pesada que compromete a amplitude de movimento.',
                ],
                'tips'             => [
                    'A maior amplitude possível nos halteres é a principal vantagem sobre a barra.',
                    'Mantenha os pulsos neutros (sem dobrar) durante toda a execução.',
                ],
            ],

            [
                'name'             => 'Supino Inclinado com Halteres',
                'description'      => 'Supino com banco inclinado (30-45°) que enfatiza a porção superior do peitoral e contribui para um visual mais completo e definido do peito.',
                'primary_muscle'   => 'Peitoral superior',
                'secondary_muscles'=> ['Deltóide anterior', 'Tríceps'],
                'execution_steps'  => [
                    'Ajuste o banco entre 30° e 45° — inclinações maiores transferem o trabalho para os ombros.',
                    'Sente com os pés apoiados no chão e as costas totalmente apoiadas no banco.',
                    'Segure os halteres na altura do peitoral superior com cotovelos a 45-60° do tronco.',
                    'Empurre os halteres para cima convergindo levemente ao topo.',
                    'Desça de forma controlada até sentir o alongamento no peitoral superior.',
                ],
                'common_mistakes'  => [
                    'Inclinar o banco acima de 45°, transformando o exercício em um desenvolvimento de ombros.',
                    'Afastar as costas do banco durante a execução.',
                    'Posicionar os cotovelos perpendiculares ao tronco (a 90°), sobrecarregando o ombro.',
                ],
                'tips'             => [
                    'A inclinação de 30° é a mais eficaz para o peitoral superior sem transferir excessivamente para os ombros.',
                    'Concentre-se em "espreme" o peitoral superior ao empurrar os halteres.',
                ],
            ],

            [
                'name'             => 'Supino Declinado',
                'description'      => 'Supino com banco declinado que trabalha a porção inferior do peitoral e permite maior carga que o supino plano na maioria dos praticantes.',
                'primary_muscle'   => 'Peitoral inferior',
                'secondary_muscles'=> ['Deltóide anterior', 'Tríceps', 'Serrátil anterior'],
                'execution_steps'  => [
                    'Prenda os pés nos apoios do banco declinado e deite com o corpo inclinado.',
                    'Segure a barra na largura do supino plano ou levemente mais fechada.',
                    'Destrave e posicione a barra acima do peitoral inferior (altura do plexo).',
                    'Desça a barra de forma controlada até tocar levemente o baixo peito.',
                    'Empurre de volta para cima até a extensão dos cotovelos.',
                ],
                'common_mistakes'  => [
                    'Deixar a cabeça ficar congestionada — não é recomendado para hipertensos.',
                    'Descer a barra para o peitoral superior em vez do inferior.',
                    'Quicar a barra no peito para usar impulso.',
                ],
                'tips'             => [
                    'O supino declinado é geralmente mais seguro para os ombros que o plano.',
                    'A declinação entre 15° e 30° já é suficiente para ativação máxima do peitoral inferior.',
                ],
            ],

            [
                'name'             => 'Supino Reto na Maquina',
                'description'      => 'Versão guiada do supino na máquina chest press, mais segura para iniciantes e ideal para isolamento sem necessidade de spotter.',
                'primary_muscle'   => 'Peitoral maior',
                'secondary_muscles'=> ['Deltóide anterior', 'Tríceps'],
                'execution_steps'  => [
                    'Ajuste o banco e os punhos na altura do peito médio.',
                    'Sente com as costas totalmente apoiadas no encosto e os pés no chão.',
                    'Segure os punhos com pegada pronada e cotovelos a 45-60° do tronco.',
                    'Empurre à frente até a extensão quase completa dos braços.',
                    'Retorne de forma controlada sem deixar as placas encostar ao final.',
                ],
                'common_mistakes'  => [
                    'Arredondar os ombros para frente durante a execução.',
                    'Deixar as placas baterem no final de cada repetição.',
                    'Empurrar os punhos divergindo (para os lados) em vez de para frente.',
                ],
                'tips'             => [
                    'Máquinas guiadas são ideais para isolamento e aprendizado do padrão de movimento.',
                    'Ajuste a amplitude para não ultrapassar o ponto confortável do ombro.',
                ],
            ],

            [
                'name'             => 'Crucifixo com Halteres',
                'description'      => 'Exercício de isolamento do peitoral que simula o movimento de "abraçar uma árvore", proporcionando grande amplitude e alongamento do peitoral.',
                'primary_muscle'   => 'Peitoral maior',
                'secondary_muscles'=> ['Deltóide anterior', 'Bíceps (estabilização)'],
                'execution_steps'  => [
                    'Deite no banco plano com um halter em cada mão, braços estendidos acima do peito.',
                    'Gire os punhos para a posição neutra (palmas uma para a outra).',
                    'Com os cotovelos levemente dobrados e fixos, abra os braços lateralmente.',
                    'Desça até sentir um bom alongamento no peitoral (não além do confortável).',
                    'Contraia o peitoral e feche os braços de volta à posição inicial, como se abraçasse.',
                ],
                'common_mistakes'  => [
                    'Dobrar excessivamente os cotovelos, transformando em supino com halteres.',
                    'Descer os halteres abaixo da linha do banco, causando estresse excessivo no ombro.',
                    'Usar carga excessiva que compromete a amplitude e a forma.',
                ],
                'tips'             => [
                    'É um exercício de isolamento — use carga moderada e priorize a sensação de "esticar" e "apertar" o peitoral.',
                    'Os cotovelos devem permanecer em ângulo fixo durante todo o movimento.',
                ],
            ],

            [
                'name'             => 'Crossover no Cabo',
                'description'      => 'Exercício de isolamento do peitoral nas polias cruzadas que mantém tensão constante e permite diferentes ângulos de trabalho conforme a posição das polias.',
                'primary_muscle'   => 'Peitoral maior',
                'secondary_muscles'=> ['Deltóide anterior', 'Serrátil anterior'],
                'execution_steps'  => [
                    'Ajuste as polias na altura dos ombros (ou acima para peitoral inferior).',
                    'Segure um cabo em cada mão, avance um passo à frente e incline levemente o tronco.',
                    'Com os cotovelos levemente dobrados, traga os cabos em arco para frente.',
                    'Cruze as mãos no centro, comprimindo o peitoral ao máximo.',
                    'Abra os braços de forma controlada mantendo a tensão nos cabos.',
                ],
                'common_mistakes'  => [
                    'Endireitar os cotovelos durante o movimento, ativando mais o tríceps.',
                    'Usar impulso do tronco em vez de contrair o peitoral.',
                    'Não cruzar as mãos no centro, perdendo o pico de contração.',
                ],
                'tips'             => [
                    'Cruze as mãos alternando qual fica por cima a cada repetição para trabalho simétrico.',
                    'Polia alta trabalha peitoral inferior; polia baixa trabalha peitoral superior.',
                ],
            ],

            [
                'name'             => 'Flexão de Braços',
                'description'      => 'Exercício básico de empurrada com peso corporal que trabalha peitoral, tríceps e deltóide anterior, podendo ser realizado em qualquer lugar.',
                'primary_muscle'   => 'Peitoral maior',
                'secondary_muscles'=> ['Tríceps', 'Deltóide anterior', 'Core', 'Serrátil anterior'],
                'execution_steps'  => [
                    'Apoie as mãos no chão levemente mais largas que os ombros, com os dedos apontados para frente.',
                    'Estenda as pernas para trás apoiando-se nas pontas dos pés, formando linha reta.',
                    'Contraia o core e os glúteos mantendo o corpo alinhado.',
                    'Dobre os cotovelos descendo o peito em direção ao chão sem tocar.',
                    'Empurre de volta à posição inicial através da extensão dos cotovelos.',
                ],
                'common_mistakes'  => [
                    'Afundar o quadril no chão ou levantá-lo excessivamente.',
                    'Não completar a amplitude — desça até o peito quase tocar o chão.',
                    'Deixar os cotovelos abrirem demais a 90°, sobrecarregando o ombro.',
                ],
                'tips'             => [
                    'Para facilitar: apoie os joelhos no chão. Para dificultar: eleve os pés em um banco.',
                    'Ampliar a pegada ativa mais o peitoral; fechar ativa mais o tríceps.',
                ],
            ],

            // ── PERNAS ────────────────────────────────────────────────────────

            [
                'name'             => 'Agachamento Livre',
                'description'      => 'Considerado o "rei dos exercícios", o agachamento livre com barra trabalha praticamente todos os músculos do corpo, com ênfase em quadríceps e glúteos.',
                'primary_muscle'   => 'Quadríceps',
                'secondary_muscles'=> ['Glúteos', 'Isquiotibiais', 'Core', 'Eretores da espinha', 'Panturrilha'],
                'execution_steps'  => [
                    'Posicione a barra nas costas (abaixo dos trapézios) e fique em pé com os pés na largura dos ombros.',
                    'Aponte os pés levemente para fora (15-30°) e mantenha o olhar à frente.',
                    'Inspire, contraia o core e inicie a descida empurrando os joelhos para fora no eixo dos pés.',
                    'Desça até os quadris ficarem paralelos ou abaixo dos joelhos (squat completo).',
                    'Empurre o chão com os pés e suba de forma explosiva, expirando na subida.',
                ],
                'common_mistakes'  => [
                    'Joelhos caindo para dentro (valgismo) — empurre os joelhos para fora durante todo o movimento.',
                    'Inclinar excessivamente o tronco para frente (indica falta de mobilidade de tornozelo/quadril).',
                    'Levantar os calcanhares do chão — trabalhe a mobilidade do tornozelo.',
                ],
                'tips'             => [
                    'Use cinto apenas em cargas máximas — em treinos normais, trabalhe a força do core.',
                    'Mobilidade de tornozelo, quadril e torácica são pré-requisitos para boa execução.',
                ],
            ],

            [
                'name'             => 'Leg Press',
                'description'      => 'Exercício guiado para membros inferiores que permite carga elevada com baixo risco para a lombar, sendo excelente para hipertrofia de quadríceps e glúteos.',
                'primary_muscle'   => 'Quadríceps',
                'secondary_muscles'=> ['Glúteos', 'Isquiotibiais', 'Panturrilha (estabilização)'],
                'execution_steps'  => [
                    'Sente na máquina com as costas e glúteos totalmente apoiados no banco.',
                    'Posicione os pés na plataforma na largura dos ombros, dedos levemente apontados para fora.',
                    'Destrave a segurança e dobre os joelhos descendo a plataforma de forma controlada.',
                    'Desça até os joelhos formarem ângulo de 90° (ou quadris abaixo dos joelhos).',
                    'Empurre a plataforma de volta sem travar completamente os joelhos no topo.',
                ],
                'common_mistakes'  => [
                    'Deixar o glúteo levantar do banco no ponto mais baixo (risco de lesão lombar).',
                    'Travar os joelhos na extensão completa, sobrecarregando a articulação.',
                    'Posicionar os pés muito baixos na plataforma, aumentando o estresse no joelho.',
                ],
                'tips'             => [
                    'Pés mais altos ativam mais glúteos e isquiotibiais; pés mais baixos ativam mais quadríceps.',
                    'Pés afastados (sumo) aumentam a ativação interna do quadríceps e adutores.',
                ],
            ],

            [
                'name'             => 'Agachamento Búlgaro',
                'description'      => 'Agachamento unilateral com o pé traseiro elevado que oferece grande ativação de glúteo e quadríceps, além de melhorar o equilíbrio e corrigir desequilíbrios.',
                'primary_muscle'   => 'Quadríceps',
                'secondary_muscles'=> ['Glúteos', 'Isquiotibiais', 'Core', 'Panturrilha'],
                'execution_steps'  => [
                    'Apoie o dorso do pé traseiro em um banco ou step atrás de você.',
                    'Posicione o pé da frente a um passo à frente para que o joelho não passe do pé ao descer.',
                    'Com os halteres nas mãos ao longo do corpo, mantenha o tronco ereto.',
                    'Desça o joelho traseiro em direção ao chão dobrando ambos os joelhos.',
                    'Empurre o calcanhar da perna da frente para subir de volta à posição inicial.',
                ],
                'common_mistakes'  => [
                    'Pé da frente muito próximo do banco, fazendo o joelho ultrapassar muito o pé.',
                    'Inclinar o tronco excessivamente para frente durante a descida.',
                    'Não manter a estabilidade na perna de apoio durante todo o movimento.',
                ],
                'tips'             => [
                    'Comece sem carga para aprender o equilíbrio antes de adicionar halteres.',
                    'Quanto mais inclinado o tronco para frente, mais glúteo; mais ereto, mais quadríceps.',
                ],
            ],

            [
                'name'             => 'Avanço com Halteres',
                'description'      => 'Exercício unilateral dinâmico que trabalha quadríceps, glúteos e equilíbrio, podendo ser realizado estacionário ou em deslocamento.',
                'primary_muscle'   => 'Quadríceps',
                'secondary_muscles'=> ['Glúteos', 'Isquiotibiais', 'Core', 'Panturrilha'],
                'execution_steps'  => [
                    'Fique em pé com um halter em cada mão ao lado do corpo.',
                    'Dê um passo à frente com uma perna, descendo o joelho traseiro em direção ao chão.',
                    'Certifique-se de que o joelho da frente não ultrapasse a ponta do pé.',
                    'O torso deve permanecer ereto durante toda a execução.',
                    'Empurre o calcanhar do pé da frente para retornar à posição inicial e alterne as pernas.',
                ],
                'common_mistakes'  => [
                    'Joelho da frente ultrapassando o pé, aumentando o estresse patelar.',
                    'Inclinar o tronco para frente durante a descida.',
                    'Dar um passo muito curto que não permite o joelho traseiro descer adequadamente.',
                ],
                'tips'             => [
                    'Olhe para um ponto fixo à frente para ajudar na manutenção do equilíbrio.',
                    'Para focar em glúteos, dê um passo mais longo; para quadríceps, passo mais curto.',
                ],
            ],

            [
                'name'             => 'Cadeira Extensora',
                'description'      => 'Exercício de isolamento dos quadríceps na máquina, ideal para finalizar o treino de pernas ou reabilitar o joelho com controle de carga preciso.',
                'primary_muscle'   => 'Quadríceps',
                'secondary_muscles'=> [],
                'execution_steps'  => [
                    'Ajuste a máquina para que o encosto apoie completamente a coxa e o rolo fique no terço inferior da perna.',
                    'Sente com as costas totalmente apoiadas e segure as alças laterais.',
                    'Estenda os joelhos levantando o rolo até a quase extensão completa das pernas.',
                    'Segure por 1 segundo no topo comprimindo os quadríceps.',
                    'Desça de forma lenta e controlada sem deixar o peso cair.',
                ],
                'common_mistakes'  => [
                    'Usar impulso do tronco para ajudar a levantar a carga.',
                    'Não completar a extensão, reduzindo a ativação do quadríceps.',
                    'Posicionar o rolo acima do tornozelo, gerando estresse desnecessário no joelho.',
                ],
                'tips'             => [
                    'Faça pausas no topo (2 segundos) para maximizar a ativação do quadríceps.',
                    'Use cargas moderadas com alta amplitude — é um exercício de isolamento, não de força.',
                ],
            ],

            [
                'name'             => 'Mesa Flexora',
                'description'      => 'Exercício de isolamento dos isquiotibiais na máquina, executado em posição deitada ou sentada, fundamental para equilíbrio muscular de membros inferiores.',
                'primary_muscle'   => 'Isquiotibiais',
                'secondary_muscles'=> ['Glúteos', 'Panturrilha'],
                'execution_steps'  => [
                    'Ajuste a máquina para que o rolo fique no terço inferior da perna, acima do calcanhar.',
                    'Deite de bruços com os joelhos na borda da máquina e as coxas totalmente apoiadas.',
                    'Flexione os joelhos trazendo o rolo em direção aos glúteos o máximo possível.',
                    'Segure por 1 segundo na contração máxima.',
                    'Desça de forma lenta e controlada sem deixar o peso cair.',
                ],
                'common_mistakes'  => [
                    'Levantar o quadril para conseguir maior amplitude (indica excesso de carga).',
                    'Usar impulso ou balanço para mover o rolo.',
                    'Não controlar a fase excêntrica (descida) do movimento.',
                ],
                'tips'             => [
                    'Apontar os dedos do pé ligeiramente aumenta a ativação dos isquiotibiais.',
                    'É importante para prevenir desequilíbrios musculares entre quadríceps e isquiotibiais.',
                ],
            ],

            [
                'name'             => 'Stiff com Barra',
                'description'      => 'Levantamento terra romeno focado no alongamento e contração dos isquiotibiais, um dos melhores exercícios para desenvolvimento da cadeia posterior.',
                'primary_muscle'   => 'Isquiotibiais',
                'secondary_muscles'=> ['Glúteos', 'Eretores da espinha', 'Core'],
                'execution_steps'  => [
                    'Segure a barra com pegada pronada na largura dos ombros, em pé com os pés juntos ou levemente afastados.',
                    'Com os joelhos levemente dobrados e fixos, incline o tronco para frente empurrando o quadril para trás.',
                    'Desça a barra ao longo das pernas mantendo-a próxima ao corpo.',
                    'Vá até sentir um bom alongamento nos isquiotibiais (geralmente até a canela ou abaixo dos joelhos).',
                    'Contraia os glúteos e isquiotibiais para retornar à posição inicial.',
                ],
                'common_mistakes'  => [
                    'Arredondar a lombar durante a descida — a coluna deve permanecer neutra.',
                    'Dobrar excessivamente os joelhos, transformando em levantamento terra convencional.',
                    'Deixar a barra se afastar do corpo, aumentando o estresse na lombar.',
                ],
                'tips'             => [
                    'Pense em "empurrar o quadril para trás" em vez de "dobrar o tronco para frente".',
                    'Amplitude ideal: até onde conseguir manter a coluna neutra — não force além disso.',
                ],
            ],

            [
                'name'             => 'Panturrilha em Pé',
                'description'      => 'Exercício de isolamento para as panturrilhas em posição ortostática, trabalhando principalmente o gastrocnêmio e o sóleo.',
                'primary_muscle'   => 'Gastrocnêmio',
                'secondary_muscles'=> ['Sóleo', 'Tibial posterior'],
                'execution_steps'  => [
                    'Posicione a ponta dos pés em uma plataforma elevada (degrau ou step), calcanhares no ar.',
                    'Segure em um suporte para equilíbrio ou use máquina específica.',
                    'Desça os calcanhares abaixo do nível da plataforma para um bom alongamento.',
                    'Suba na ponta dos pés o máximo possível, comprimindo as panturrilhas.',
                    'Segure 1-2 segundos no topo e desça de forma controlada.',
                ],
                'common_mistakes'  => [
                    'Não realizar amplitude completa — tanto a descida (alongamento) quanto a subida (contração).',
                    'Usar impulso e balançar o corpo para compensar carga excessiva.',
                    'Fazer o movimento muito rápido sem controlar a fase excêntrica.',
                ],
                'tips'             => [
                    'Pés paralelos ativam igualmente toda a panturrilha; pés para fora ativam mais a cabeça medial.',
                    'As panturrilhas são resistentes — use séries com mais repetições (15-25) e amplitude completa.',
                ],
            ],

            // ── TRÍCEPS ───────────────────────────────────────────────────────

            [
                'name'             => 'Tríceps Corda',
                'description'      => 'Exercício de isolamento do tríceps na polia com acessório de corda, que permite abertura no final do movimento aumentando o pico de contração.',
                'primary_muscle'   => 'Tríceps braquial',
                'secondary_muscles'=> ['Antebraço'],
                'execution_steps'  => [
                    'Ajuste a polia alta e conecte o acessório de corda.',
                    'Fique de frente para a polia com os cotovelos dobrados a 90°, fixos ao lado do corpo.',
                    'Puxe a corda para baixo estendendo os cotovelos.',
                    'No ponto final, afaste as pontas da corda ligeiramente para os lados para maior contração.',
                    'Retorne de forma controlada à posição inicial sem deixar os cotovelos saírem do lugar.',
                ],
                'common_mistakes'  => [
                    'Mover os cotovelos para frente durante a extensão, usando os ombros para compensar.',
                    'Inclinar o tronco para frente para ajudar a puxar mais carga.',
                    'Não abrir a corda no final, perdendo o pico de contração.',
                ],
                'tips'             => [
                    'Cotovelos fixos ao lado do corpo são a chave para isolamento máximo do tríceps.',
                    'A abertura das pontas da corda no final aumenta significativamente a ativação.',
                ],
            ],

            [
                'name'             => 'Tríceps Francês com Barra',
                'description'      => 'Exercício de isolamento do tríceps realizado acima da cabeça, que trabalha especialmente a cabeça longa do tríceps em posição de grande alongamento.',
                'primary_muscle'   => 'Tríceps braquial',
                'secondary_muscles'=> ['Cotovelo (estabilização)'],
                'execution_steps'  => [
                    'Fique em pé ou sente com a barra Ez (W) segurada acima da cabeça, braços estendidos.',
                    'Mantenha os cotovelos apontados para cima e próximos à cabeça.',
                    'Dobre os cotovelos descendo a barra atrás da cabeça de forma controlada.',
                    'Desça até sentir um bom alongamento no tríceps.',
                    'Estenda os cotovelos de volta à posição inicial sem mover os braços superiores.',
                ],
                'common_mistakes'  => [
                    'Deixar os cotovelos abrirem para os lados durante o movimento.',
                    'Mover os braços superiores junto com o antebraço, perdendo o isolamento.',
                    'Usar impulso ou balanço do tronco para ajudar na extensão.',
                ],
                'tips'             => [
                    'A posição acima da cabeça é mais eficaz para a cabeça longa do tríceps.',
                    'Barra Ez (W) é mais confortável para os pulsos que a barra reta.',
                ],
            ],

            [
                'name'             => 'Extensão de Tríceps com Haltere',
                'description'      => 'Variação unilateral do tríceps francês com halter, que permite trabalho independente de cada braço e correção de desequilíbrios.',
                'primary_muscle'   => 'Tríceps braquial',
                'secondary_muscles'=> [],
                'execution_steps'  => [
                    'Fique em pé ou sente segurando um halter com ambas as mãos acima da cabeça.',
                    'Mantenha o braço estendido com o halter acima da cabeça.',
                    'Dobre o cotovelo descendo o halter atrás da cabeça, mantendo o braço superior imóvel.',
                    'Estenda o cotovelo de volta à posição inicial.',
                    'Complete as repetições e troque o lado.',
                ],
                'common_mistakes'  => [
                    'Deixar o cotovelo abrir para o lado durante a flexão.',
                    'Mover o ombro junto com o antebraço.',
                    'Não controlar a descida do halter (fase excêntrica).',
                ],
                'tips'             => [
                    'Use a mão contrária para estabilizar o cotovelo durante o exercício.',
                    'Amplitude completa na descida maximiza o trabalho na cabeça longa do tríceps.',
                ],
            ],

            [
                'name'             => 'Tríceps Coice',
                'description'      => 'Exercício de isolamento que trabalha as cabeças laterais e mediais do tríceps com o tronco inclinado e o cotovelo elevado.',
                'primary_muscle'   => 'Tríceps braquial',
                'secondary_muscles'=> [],
                'execution_steps'  => [
                    'Incline o tronco a 45° apoiando uma mão e um joelho no banco.',
                    'Segure um halter com a outra mão e eleve o cotovelo à altura do tronco.',
                    'Com o cotovelo fixo, estenda o antebraço para trás até a extensão completa.',
                    'Segure 1 segundo no final da extensão para máxima contração.',
                    'Retorne de forma controlada e repita.',
                ],
                'common_mistakes'  => [
                    'Deixar o cotovelo cair durante a extensão, perdendo o isolamento.',
                    'Usar impulso do tronco para ajudar a estender o braço.',
                    'Não atingir a extensão completa do cotovelo.',
                ],
                'tips'             => [
                    'O cotovelo deve permanecer na mesma altura o tempo todo — só o antebraço se move.',
                    'Use carga leve a moderada para manter a técnica perfeita.',
                ],
            ],

            [
                'name'             => 'Fundos (Dips)',
                'description'      => 'Exercício composto com peso corporal nas barras paralelas que trabalha tríceps, peitoral inferior e deltóide anterior com alta intensidade.',
                'primary_muscle'   => 'Tríceps braquial',
                'secondary_muscles'=> ['Peitoral inferior', 'Deltóide anterior', 'Core'],
                'execution_steps'  => [
                    'Segure as barras paralelas com as mãos e suba mantendo os braços estendidos.',
                    'Incline o tronco levemente para frente para equilibrar melhor o trabalho entre tríceps e peitoral.',
                    'Dobre os cotovelos descendo o corpo de forma controlada.',
                    'Desça até os braços formarem ângulo de 90° (ou levemente abaixo).',
                    'Empurre de volta à posição inicial através da extensão dos cotovelos.',
                ],
                'common_mistakes'  => [
                    'Descer além de 90° sem preparo adequado, sobrecarregando a articulação do ombro.',
                    'Inclinar excessivamente o tronco para frente, transferindo o trabalho para o peitoral.',
                    'Manter os ombros elevados — mantenha-os baixos e estabilizados.',
                ],
                'tips'             => [
                    'Tronco mais ereto = mais tríceps; tronco mais inclinado = mais peitoral.',
                    'Use elástico de assistência ou graviton se não conseguir com o peso corporal.',
                ],
            ],

            [
                'name'             => 'Skull Crusher',
                'description'      => 'Exercício de isolamento do tríceps conhecido como "esmaga crânio", realizado deitado com a barra descendo em direção à testa.',
                'primary_muscle'   => 'Tríceps braquial',
                'secondary_muscles'=> ['Antebraço'],
                'execution_steps'  => [
                    'Deite no banco com a barra Ez (W) segurada acima do peito com braços estendidos.',
                    'Os braços devem estar levemente inclinados em direção ao rosto (não perpendiculares ao banco).',
                    'Dobre os cotovelos descendo a barra em direção à testa ou levemente atrás dela.',
                    'Mantenha os cotovelos fixos, apontando para o teto.',
                    'Estenda os cotovelos de volta à posição inicial de forma controlada.',
                ],
                'common_mistakes'  => [
                    'Deixar os cotovelos abrirem para os lados durante a flexão.',
                    'Descer a barra diretamente sobre o rosto — mantenha levemente atrás da testa.',
                    'Usar carga excessiva que compromete o controle do movimento.',
                ],
                'tips'             => [
                    'A barra Ez é preferível para reduzir o estresse nos pulsos e cotovelos.',
                    'Usar pegada mais estreita que a largura dos ombros isola melhor o tríceps.',
                ],
            ],

        ];
    }
}
