<template>
  <div class="card overflow-hidden">
    <table class="w-full text-left">
      <thead>
        <tr class="border-b border-slate-100 bg-slate-50/60">
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Nome</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide hidden sm:table-cell">Tipo</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Status</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide hidden md:table-cell">Período</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide hidden md:table-cell">Participantes</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right">Ações</th>
        </tr>
      </thead>
      <tbody>

        <!-- Loading skeleton -->
        <template v-if="loading">
          <tr v-for="i in 3" :key="i" class="border-b border-slate-100">
            <td v-for="j in 6" :key="j" class="px-5 py-3.5">
              <div class="h-4 bg-slate-100 rounded animate-pulse" :class="j === 1 ? 'w-40' : 'w-20'" />
            </td>
          </tr>
        </template>

        <!-- Empty state -->
        <tr v-else-if="challenges.length === 0">
          <td colspan="6" class="px-5 py-16 text-center">
            <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
              <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 18.75h-9m9 0a3 3 0 013 3h-15a3 3 0 013-3m9 0v-3.375c0-.621-.503-1.125-1.125-1.125h-.871M7.5 18.75v-3.375c0-.621.504-1.125 1.125-1.125h.872m5.007 0H9.497m5.007 0a7.454 7.454 0 01-.982-3.172M9.497 14.25a7.454 7.454 0 00.981-3.172M5.25 4.236c-.982.143-1.954.317-2.916.52A6.003 6.003 0 007.73 9.728M5.25 4.236V4.5c0 2.108.966 3.99 2.48 5.228M5.25 4.236V2.721C7.456 2.41 9.71 2.25 12 2.25c2.291 0 4.545.16 6.75.47v1.516M7.73 9.728a6.726 6.726 0 002.748 1.35m8.272-6.842V4.5c0 2.108-.966 3.99-2.48 5.228m2.48-5.492a46.32 46.32 0 012.916.52 6.003 6.003 0 01-5.395 4.972m0 0a6.726 6.726 0 01-2.749 1.35m0 0a6.772 6.772 0 01-3.044 0" />
              </svg>
            </div>
            <p class="text-sm font-semibold text-slate-700 mb-1">
              {{ search ? 'Nenhum desafio encontrado' : 'Nenhum desafio criado' }}
            </p>
            <p class="text-xs text-slate-400">
              {{ search ? `Nenhum resultado para "${search}"` : 'Crie o primeiro desafio da academia.' }}
            </p>
          </td>
        </tr>

        <!-- Rows -->
        <ChallengeRow
          v-for="c in challenges"
          :key="c.id"
          :challenge="c"
          @view="$emit('view', $event)"
          @edit="$emit('edit', $event)"
          @delete="$emit('delete', $event)"
        />

      </tbody>
    </table>
  </div>
</template>

<script setup>
import ChallengeRow from './ChallengeRow.vue'

defineProps({
  challenges: { type: Array,   required: true },
  loading:    { type: Boolean,  default: false },
  search:     { type: String,   default: '' },
})
defineEmits(['view', 'edit', 'delete'])
</script>
