<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCustomWorkoutRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'                    => 'required|string|max:255',
            'description'             => 'nullable|string',
            'level'                   => 'nullable|string|max:50',
            'duration'                => 'nullable|integer|min:1',
            'is_generated'            => 'boolean',
            'exercises'               => 'required|array|min:1',
            'exercises.*.exercise_id' => 'required|integer|exists:exercises,id',
            'exercises.*.sets'        => 'required|integer|min:1',
            'exercises.*.reps'        => 'required|integer|min:1',
            'exercises.*.rest'        => 'nullable|integer|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'name.required'                    => 'O nome do treino é obrigatório.',
            'exercises.required'               => 'Informe ao menos um exercício.',
            'exercises.min'                    => 'Informe ao menos um exercício.',
            'exercises.*.exercise_id.required' => 'O ID do exercício é obrigatório.',
            'exercises.*.exercise_id.exists'   => 'Exercício não encontrado.',
            'exercises.*.sets.required'        => 'O número de séries é obrigatório.',
            'exercises.*.reps.required'        => 'O número de repetições é obrigatório.',
        ];
    }
}
