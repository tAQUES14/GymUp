<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GymOpenDay;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Gerencia os dias de funcionamento da academia.
 *
 * Se nenhum registro for cadastrado para a academia, o sistema considera
 * que ela está aberta todos os dias (comportamento padrão).
 *
 * Nomes dos dias: 0=Domingo, 1=Segunda, 2=Terça, 3=Quarta,
 *                  4=Quinta,  5=Sexta,   6=Sábado
 */
class AdminGymScheduleController extends Controller
{
    private const DAY_NAMES = [
        0 => 'Domingo',
        1 => 'Segunda',
        2 => 'Terça',
        3 => 'Quarta',
        4 => 'Quinta',
        5 => 'Sexta',
        6 => 'Sábado',
    ];

    /**
     * GET /api/admin/gym-schedule
     *
     * Retorna os 7 dias da semana com status de abertura.
     */
    public function index(Request $request): JsonResponse
    {
        $gymId   = $request->user()->gym_id;
        $records = GymOpenDay::where('gym_id', $gymId)->get()->keyBy('day_of_week');

        $days = [];
        for ($dow = 0; $dow <= 6; $dow++) {
            $record  = $records->get($dow);
            $days[] = [
                'day_of_week' => $dow,
                'name'        => self::DAY_NAMES[$dow],
                'is_open'     => $record ? $record->is_open : true, // default: aberto
            ];
        }

        return response()->json(['schedule' => $days]);
    }

    /**
     * PUT /api/admin/gym-schedule
     *
     * Atualiza o horário de funcionamento da academia.
     * Body: { days: [{day_of_week: 0-6, is_open: bool}] }
     */
    public function update(Request $request): JsonResponse
    {
        $request->validate([
            'days'                => 'required|array|min:1|max:7',
            'days.*.day_of_week'  => 'required|integer|min:0|max:6',
            'days.*.is_open'      => 'required|boolean',
        ]);

        $gymId = $request->user()->gym_id;

        foreach ($request->input('days') as $day) {
            GymOpenDay::updateOrCreate(
                ['gym_id' => $gymId, 'day_of_week' => $day['day_of_week']],
                ['is_open' => $day['is_open']]
            );
        }

        return $this->index($request);
    }
}
