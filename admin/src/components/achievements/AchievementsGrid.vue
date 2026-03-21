<template>
  <div>

    <!-- Loading skeleton -->
    <div v-if="loading" class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
      <div v-for="i in 6" :key="i" class="card p-5 animate-pulse">
        <div class="flex items-start gap-3 mb-4">
          <div class="w-11 h-11 rounded-xl bg-slate-100 flex-shrink-0" />
          <div class="flex-1 space-y-2 pt-1">
            <div class="h-3 bg-slate-100 rounded w-16" />
          </div>
        </div>
        <div class="space-y-2 mb-4">
          <div class="h-4 bg-slate-100 rounded w-40" />
          <div class="h-3 bg-slate-100 rounded w-full" />
          <div class="h-3 bg-slate-100 rounded w-3/4" />
        </div>
        <div class="border-t border-slate-100 pt-3 grid grid-cols-3 gap-2">
          <div v-for="j in 3" :key="j" class="flex flex-col items-center gap-1">
            <div class="h-2 bg-slate-100 rounded w-10" />
            <div class="h-4 bg-slate-100 rounded w-8" />
          </div>
        </div>
      </div>
    </div>

    <!-- Empty state -->
    <div v-else-if="achievements.length === 0" class="card p-16 text-center">
      <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
        <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700 mb-1">
        {{ search ? 'Nenhuma conquista encontrada' : 'Nenhuma conquista cadastrada' }}
      </p>
      <p class="text-xs text-slate-400">
        {{ search ? `Nenhum resultado para "${search}"` : 'As conquistas são configuradas via seeder.' }}
      </p>
    </div>

    <!-- Grid -->
    <div v-else class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
      <AchievementCard
        v-for="a in achievements"
        :key="a.id"
        :achievement="a"
        @edit="$emit('edit', $event)"
        @delete="$emit('delete', $event)"
      />
    </div>

  </div>
</template>

<script setup>
import AchievementCard from './AchievementCard.vue'

defineProps({
  achievements: { type: Array,   required: true },
  loading:      { type: Boolean, default: false },
  search:       { type: String,  default: '' },
})
defineEmits(['edit', 'delete'])
</script>
