<template>
  <tr class="group border-b border-slate-100 hover:bg-slate-50/70 transition-colors duration-100 cursor-pointer"
      @click="$emit('view', workout.id)"
  >

    <!-- Nome + descrição -->
    <td class="px-5 py-3.5">
      <div class="flex items-center gap-3">
        <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0" :class="iconBg">
          <svg class="w-4 h-4" :class="iconColor" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M6.429 9.75L2.25 12l4.179 2.25m0-4.5l5.571 3 5.571-3m-11.142 0L2.25 7.5 12 2.25l9.75 5.25-4.179 2.25m0 0L21.75 12l-4.179 2.25m0 0l4.179 2.25L12 21.75 2.25 16.5l4.179-2.25m11.142 0l-5.571 3-5.571-3" />
          </svg>
        </div>
        <div class="min-w-0">
          <p class="text-sm font-semibold text-slate-800 truncate leading-tight">{{ workout.name }}</p>
          <p v-if="workout.description" class="text-[11px] text-slate-400 truncate leading-tight mt-0.5 max-w-[220px]">
            {{ workout.description }}
          </p>
        </div>
      </div>
    </td>

    <!-- Nível -->
    <td class="px-5 py-3.5">
      <span class="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold" :class="levelClass">
        {{ levelLabel }}
      </span>
    </td>

    <!-- Duração -->
    <td class="px-5 py-3.5 hidden sm:table-cell">
      <div v-if="workout.duration" class="flex items-center gap-1 text-sm text-slate-500">
        <svg class="w-3.5 h-3.5 text-slate-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        {{ workout.duration }} min
      </div>
      <span v-else class="text-slate-300 text-sm">—</span>
    </td>

    <!-- Exercícios -->
    <td class="px-5 py-3.5 hidden md:table-cell">
      <span
        class="inline-flex items-center justify-center min-w-[2rem] h-6 px-2 rounded-full text-xs font-semibold"
        :class="workout.exercises_count > 0 ? 'bg-brand-50 text-brand-700' : 'bg-slate-100 text-slate-400'"
      >
        {{ workout.exercises_count ?? 0 }}
      </span>
    </td>

    <!-- Atribuídos -->
    <td class="px-5 py-3.5 hidden md:table-cell">
      <div class="flex items-center gap-1.5">
        <span
          class="inline-flex items-center justify-center min-w-[2rem] h-6 px-2 rounded-full text-xs font-semibold"
          :class="(workout.assigned_count ?? 0) > 0 ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-400'"
        >
          {{ workout.assigned_count ?? 0 }}
        </span>
        <span v-if="(workout.assigned_count ?? 0) > 0" class="text-[11px] text-slate-400">
          aluno{{ workout.assigned_count !== 1 ? 's' : '' }}
        </span>
      </div>
    </td>

    <!-- Criado por -->
    <td class="px-5 py-3.5 hidden lg:table-cell">
      <template v-if="workout.is_generated">
        <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-violet-50 text-violet-700 rounded-full text-[11px] font-semibold">
          <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
          </svg>
          IA GymUp
        </span>
      </template>
      <span v-else class="text-sm text-slate-500 truncate max-w-[120px]">{{ workout.created_by }}</span>
    </td>

    <!-- Ações -->
    <td class="px-5 py-3.5 text-right" @click.stop>
      <div class="flex items-center justify-end gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity duration-150">
        <button
          @click="$emit('view', workout.id)"
          class="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold text-brand-600
                 border border-brand-200 rounded-lg hover:bg-brand-50 transition-colors"
        >
          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          Ver
        </button>
        <button
          @click="$emit('edit', workout)"
          class="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold text-slate-600
                 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors"
        >
          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
          </svg>
          Editar
        </button>
        <button
          @click="$emit('delete', workout)"
          class="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold text-red-600
                 border border-red-200 rounded-lg hover:bg-red-50 transition-colors"
        >
          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
          </svg>
          Excluir
        </button>
      </div>
    </td>

  </tr>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({ workout: { type: Object, required: true } })
defineEmits(['view', 'edit', 'delete'])

const LEVEL_MAP = {
  beginner:        { label: 'Iniciante',     class: 'bg-emerald-50 text-emerald-700' },
  intermediate:    { label: 'Intermediário', class: 'bg-amber-50   text-amber-700'   },
  advanced:        { label: 'Avançado',      class: 'bg-rose-50    text-rose-700'    },
  'iniciante':     { label: 'Iniciante',     class: 'bg-emerald-50 text-emerald-700' },
  'intermediário': { label: 'Intermediário', class: 'bg-amber-50   text-amber-700'   },
  'avançado':      { label: 'Avançado',      class: 'bg-rose-50    text-rose-700'    },
}

const levelKey   = computed(() => props.workout.level?.toLowerCase() ?? '')
const levelLabel = computed(() => LEVEL_MAP[levelKey.value]?.label ?? (props.workout.level ?? '—'))
const levelClass = computed(() => LEVEL_MAP[levelKey.value]?.class ?? 'bg-slate-100 text-slate-500')

const iconBg = computed(() => {
  const m = { beginner: 'bg-emerald-50', iniciante: 'bg-emerald-50', intermediate: 'bg-amber-50', 'intermediário': 'bg-amber-50', advanced: 'bg-rose-50', 'avançado': 'bg-rose-50' }
  return m[levelKey.value] ?? 'bg-brand-50'
})
const iconColor = computed(() => {
  const m = { beginner: 'text-emerald-600', iniciante: 'text-emerald-600', intermediate: 'text-amber-600', 'intermediário': 'text-amber-600', advanced: 'text-rose-600', 'avançado': 'text-rose-600' }
  return m[levelKey.value] ?? 'text-brand-600'
})
</script>
