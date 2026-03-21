<template>
  <div class="card p-5 flex flex-col gap-4 hover:shadow-md transition-shadow group">

    <!-- Header: icon + badge de métrica + ações -->
    <div class="flex items-start justify-between gap-3">
      <div class="w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0"
           :class="iconBg">
        <!-- Fitness / Treinos -->
        <svg v-if="achievement.icon === 'fitness'"
             class="w-6 h-6" :class="iconColor"
             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z" />
        </svg>
        <!-- Streak / Raio -->
        <svg v-else-if="achievement.icon === 'streak'"
             class="w-6 h-6" :class="iconColor"
             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
        </svg>
        <!-- Fallback: estrela -->
        <svg v-else class="w-6 h-6" :class="iconColor"
             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
        </svg>
      </div>

      <!-- Métrica badge + ações (visíveis no hover) -->
      <div class="flex items-center gap-2">
        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold"
              :class="metricBadge">
          {{ metricLabel }}
        </span>

        <!-- Action buttons -->
        <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
          <button @click.stop="$emit('edit', achievement)"
            title="Editar"
            class="w-6 h-6 rounded-md flex items-center justify-center text-slate-400
                   hover:text-brand-600 hover:bg-brand-50 transition-colors">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
            </svg>
          </button>
          <button @click.stop="$emit('delete', achievement)"
            title="Excluir"
            class="w-6 h-6 rounded-md flex items-center justify-center text-slate-400
                   hover:text-red-500 hover:bg-red-50 transition-colors">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- Título + descrição -->
    <div class="flex-1">
      <p class="text-sm font-semibold text-slate-900 leading-snug">{{ achievement.title }}</p>
      <p class="text-xs text-slate-500 mt-0.5 leading-relaxed">{{ achievement.description }}</p>
    </div>

    <!-- Footer: meta + pontos + desbloqueados -->
    <div class="border-t border-slate-100 pt-3 grid grid-cols-3 gap-2 text-center">
      <div>
        <p class="text-[10px] text-slate-400 mb-0.5">Meta</p>
        <p class="text-sm font-bold text-slate-800">{{ achievement.target_value }}</p>
      </div>
      <div>
        <p class="text-[10px] text-slate-400 mb-0.5">Pontos</p>
        <p class="text-sm font-bold text-amber-600">+{{ achievement.points_reward }}</p>
      </div>
      <div>
        <p class="text-[10px] text-slate-400 mb-0.5">Alunos</p>
        <p class="text-sm font-bold text-brand-600">{{ achievement.unlocked_count }}</p>
      </div>
    </div>

  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  achievement: { type: Object, required: true },
})
defineEmits(['edit', 'delete'])

const isStreak  = computed(() => props.achievement.metric === 'streak_days')
const isFitness = computed(() => props.achievement.metric === 'workouts_total')

const iconBg = computed(() => isStreak.value ? 'bg-amber-50' : 'bg-brand-50')
const iconColor = computed(() => isStreak.value ? 'text-amber-500' : 'text-brand-600')

const metricLabel = computed(() => {
  const map = {
    workouts_total: 'Treinos',
    streak_days:    'Streak',
  }
  return map[props.achievement.metric] ?? props.achievement.metric
})

const metricBadge = computed(() =>
  isStreak.value
    ? 'bg-amber-50 text-amber-700 border border-amber-100'
    : 'bg-brand-50 text-brand-700 border border-brand-100'
)
</script>
