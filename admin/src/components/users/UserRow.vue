<template>
  <tr
    class="group border-b border-slate-100 hover:bg-slate-50/70 transition-colors duration-100 cursor-default"
  >

    <!-- Nome + Avatar -->
    <td class="px-5 py-3.5">
      <div class="flex items-center gap-3">
        <div
          class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0 select-none overflow-hidden"
          :class="avatarColor"
        >
          <img v-if="avatarUrl" :src="avatarUrl" :alt="user.name" class="w-full h-full object-cover" @error="avatarFailed = true" />
          <template v-else>{{ initials }}</template>
        </div>
        <div class="min-w-0">
          <div class="flex items-center gap-1.5">
            <p class="text-sm font-semibold text-slate-800 truncate leading-tight">{{ user.name }}</p>
            <span v-if="user.is_visitor"
              class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold bg-slate-100 text-slate-500 shrink-0"
              :title="user.home_gym_name ? `Filial: ${user.home_gym_name}` : 'Visitante de outra filial'"
            >Visitante</span>
          </div>
          <p class="text-[11px] text-slate-400 truncate leading-tight mt-0.5">
            {{ user.is_visitor && user.home_gym_name ? user.home_gym_name : user.email }}
          </p>
        </div>
      </div>
    </td>

    <!-- Email (hidden on small) -->
    <td class="px-5 py-3.5 hidden lg:table-cell">
      <span class="text-sm text-slate-500">{{ user.email }}</span>
    </td>

    <!-- Treinos -->
    <td class="px-5 py-3.5">
      <div class="flex items-center gap-1.5">
        <span
          class="inline-flex items-center justify-center min-w-[2rem] h-6 px-2 rounded-full text-xs font-semibold"
          :class="user.workouts_total > 0
            ? 'bg-brand-50 text-brand-700'
            : 'bg-slate-100 text-slate-400'"
        >
          {{ user.workouts_total }}
        </span>
      </div>
    </td>

    <!-- Última atividade -->
    <td class="px-5 py-3.5 hidden sm:table-cell">
      <span class="text-sm text-slate-500">{{ lastActivityLabel }}</span>
    </td>

    <!-- Status -->
    <td class="px-5 py-3.5">
      <span
        class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold"
        :class="statusClass"
      >
        <span class="w-1.5 h-1.5 rounded-full" :class="dotClass" />
        {{ statusLabel }}
      </span>
    </td>

    <!-- Ações -->
    <td class="px-5 py-3.5 text-right">
      <button
        @click="$emit('view', user.id)"
        class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-brand-600
               border border-brand-200 rounded-lg hover:bg-brand-50 active:bg-brand-100
               transition-colors duration-150 opacity-0 group-hover:opacity-100"
      >
        Ver aluno
        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
        </svg>
      </button>
    </td>

  </tr>
</template>

<script setup>
import { computed, ref } from 'vue'

const props = defineProps({
  user: { type: Object, required: true },
})

defineEmits(['view'])

const avatarFailed = ref(false)
const avatarUrl = computed(() => avatarFailed.value ? '' : (props.user.avatar_url ?? ''))

// ── Avatar ────────────────────────────────────────────────────────────────────

const AVATAR_COLORS = [
  'bg-blue-500', 'bg-violet-500', 'bg-emerald-500',
  'bg-amber-500', 'bg-rose-500',  'bg-cyan-500',
  'bg-indigo-500','bg-teal-500',
]

const initials = computed(() => {
  const parts = props.user.name?.trim().split(/\s+/) ?? []
  if (parts.length >= 2) return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
  return (parts[0]?.[0] ?? '?').toUpperCase()
})

const avatarColor = computed(() => {
  const code = [...(props.user.name ?? 'A')].reduce((acc, c) => acc + c.charCodeAt(0), 0)
  return AVATAR_COLORS[code % AVATAR_COLORS.length]
})

// ── Status ────────────────────────────────────────────────────────────────────

const STATUS = {
  active:   { label: 'Ativo',   class: 'bg-emerald-50 text-emerald-700', dot: 'bg-emerald-500' },
  inactive: { label: 'Inativo', class: 'bg-slate-100  text-slate-500',   dot: 'bg-slate-400' },
  new:      { label: 'Novo',    class: 'bg-brand-50   text-brand-700',   dot: 'bg-brand-500' },
}

const statusClass = computed(() => STATUS[props.user.status]?.class ?? STATUS.new.class)
const dotClass    = computed(() => STATUS[props.user.status]?.dot   ?? STATUS.new.dot)
const statusLabel = computed(() => STATUS[props.user.status]?.label ?? 'Novo')

// ── Last activity ─────────────────────────────────────────────────────────────

const lastActivityLabel = computed(() => {
  if (!props.user.last_activity) return '—'

  const date     = new Date(props.user.last_activity + 'T00:00:00')
  const today    = new Date()
  today.setHours(0, 0, 0, 0)
  const diffMs   = today.getTime() - date.getTime()
  const diffDays = Math.round(diffMs / 86400000)

  if (diffDays === 0) return 'Hoje'
  if (diffDays === 1) return 'Ontem'
  if (diffDays < 7)  return `${diffDays} dias atrás`
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} sem. atrás`
  return date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: '2-digit' })
})
</script>
