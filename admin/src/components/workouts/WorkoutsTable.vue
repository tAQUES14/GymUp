<template>
  <div class="card overflow-hidden">
    <table class="w-full text-left border-collapse">

      <thead>
        <tr class="border-b border-slate-100 bg-slate-50/60">
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Nome</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Nível</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden sm:table-cell">Duração</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden md:table-cell">Exercícios</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden md:table-cell">Atribuídos</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden lg:table-cell">Criado por</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider text-right">Ações</th>
        </tr>
      </thead>

      <tbody>

        <!-- Loading skeleton -->
        <template v-if="loading">
          <tr v-for="n in 5" :key="n" class="border-b border-slate-100 animate-pulse">
            <td class="px-5 py-3.5">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-lg bg-slate-100 flex-shrink-0" />
                <div class="space-y-1.5">
                  <div class="h-3 bg-slate-100 rounded w-40" />
                  <div class="h-2.5 bg-slate-100 rounded w-28" />
                </div>
              </div>
            </td>
            <td class="px-5 py-3.5"><div class="h-5 bg-slate-100 rounded-full w-20" /></td>
            <td class="px-5 py-3.5 hidden sm:table-cell"><div class="h-3 bg-slate-100 rounded w-14" /></td>
            <td class="px-5 py-3.5 hidden md:table-cell"><div class="h-5 bg-slate-100 rounded-full w-8" /></td>
            <td class="px-5 py-3.5 hidden md:table-cell"><div class="h-5 bg-slate-100 rounded-full w-8" /></td>
            <td class="px-5 py-3.5 hidden lg:table-cell"><div class="h-3 bg-slate-100 rounded w-24" /></td>
            <td class="px-5 py-3.5" />
          </tr>
        </template>

        <!-- Rows -->
        <template v-else-if="workouts.length">
          <WorkoutRow
            v-for="workout in workouts"
            :key="workout.id"
            :workout="workout"
            @view="$emit('view', $event)"
            @edit="$emit('edit', $event)"
            @delete="$emit('delete', $event)"
          />
        </template>

        <!-- Empty state -->
        <tr v-else>
          <td colspan="7" class="px-5 py-16 text-center">
            <div class="flex flex-col items-center gap-3">
              <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center">
                <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                  <path stroke-linecap="round" stroke-linejoin="round"
                    d="M6.429 9.75L2.25 12l4.179 2.25m0-4.5l5.571 3 5.571-3m-11.142 0L2.25 7.5 12 2.25l9.75 5.25-4.179 2.25m0 0L21.75 12l-4.179 2.25m0 0l4.179 2.25L12 21.75 2.25 16.5l4.179-2.25m11.142 0l-5.571 3-5.571-3" />
                </svg>
              </div>
              <div>
                <p class="text-sm font-semibold text-slate-700">
                  {{ search ? 'Nenhum treino encontrado' : 'Nenhum treino cadastrado' }}
                </p>
                <p class="text-xs text-slate-400 mt-0.5">
                  {{ search ? `Sem resultados para "${search}"` : 'Clique em "Criar treino" para começar.' }}
                </p>
              </div>
            </div>
          </td>
        </tr>

      </tbody>
    </table>
  </div>
</template>

<script setup>
import WorkoutRow from './WorkoutRow.vue'

defineProps({
  workouts: { type: Array,   default: () => [] },
  loading:  { type: Boolean, default: false },
  search:   { type: String,  default: '' },
})

defineEmits(['view', 'edit', 'delete'])
</script>
