<template>
  <RouterLink
    :to="to"
    class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-all duration-150 group"
    :class="isActive
      ? 'bg-brand-600/15 text-brand-400'
      : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'"
  >
    <span
      class="w-5 h-5 flex-shrink-0"
      :class="isActive ? 'text-brand-400' : 'text-slate-500 group-hover:text-slate-300'"
      v-html="icon"
    />
    <span>{{ label }}</span>
    <span
      v-if="badge"
      class="ml-auto text-[10px] font-bold px-1.5 py-0.5 rounded-full"
      :class="isActive ? 'bg-brand-600/30 text-brand-300' : 'bg-slate-700 text-slate-400'"
    >{{ badge }}</span>
  </RouterLink>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, RouterLink } from 'vue-router'

const props = defineProps({
  to: { type: String, required: true },
  label: { type: String, required: true },
  icon: { type: String, default: '' },
  badge: { type: [String, Number], default: null },
})

const route    = useRoute()
const isActive = computed(() => route.path === props.to || route.path.startsWith(props.to + '/'))
</script>
