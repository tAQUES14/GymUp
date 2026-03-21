<template>
  <tr
    class="group border-b border-slate-100 transition-colors duration-100 cursor-pointer"
    :class="isFinished ? 'bg-slate-50/40 hover:bg-slate-50' : 'hover:bg-slate-50/70'"
    @click="$emit('view', challenge.id)"
  >

    <!-- Nome + descrição -->
    <td class="px-5 py-4">
      <div class="flex items-center gap-3">
        <!-- Icon with status ring for active -->
        <div class="relative flex-shrink-0">
          <div class="w-9 h-9 rounded-xl flex items-center justify-center"
               :class="[typeIconBg, isFinished ? 'opacity-50' : '']">
            <svg v-if="challenge.type === 'competitive'" class="w-4 h-4" :class="typeIconColor"
                 fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 18.75h-9m9 0a3 3 0 013 3h-15a3 3 0 013-3m9 0v-3.375c0-.621-.503-1.125-1.125-1.125h-.871M7.5 18.75v-3.375c0-.621.504-1.125 1.125-1.125h.872m5.007 0H9.497m5.007 0a7.454 7.454 0 01-.982-3.172M9.497 14.25a7.454 7.454 0 00.981-3.172M5.25 4.236c-.982.143-1.954.317-2.916.52A6.003 6.003 0 007.73 9.728M5.25 4.236V4.5c0 2.108.966 3.99 2.48 5.228M5.25 4.236V2.721C7.456 2.41 9.71 2.25 12 2.25c2.291 0 4.545.16 6.75.47v1.516M7.73 9.728a6.726 6.726 0 002.748 1.35m8.272-6.842V4.5c0 2.108-.966 3.99-2.48 5.228m2.48-5.492a46.32 46.32 0 012.916.52 6.003 6.003 0 01-5.395 4.972m0 0a6.726 6.726 0 01-2.749 1.35m0 0a6.772 6.772 0 01-3.044 0" />
            </svg>
            <svg v-else class="w-4 h-4" :class="typeIconColor"
                 fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
            </svg>
          </div>
          <!-- Pulsing dot for active -->
          <span v-if="statusKey === 'active'"
            class="absolute -top-0.5 -right-0.5 flex h-3 w-3">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
            <span class="relative inline-flex rounded-full h-3 w-3 bg-emerald-500" />
          </span>
        </div>

        <div class="min-w-0">
          <p class="text-sm font-semibold leading-tight truncate"
             :class="isFinished ? 'text-slate-500' : 'text-slate-800'">
            {{ challenge.name }}
          </p>
          <p v-if="challenge.description"
             class="text-[11px] text-slate-400 truncate leading-tight mt-0.5 max-w-[200px]">
            {{ challenge.description }}
          </p>
        </div>
      </div>
    </td>

    <!-- Tipo -->
    <td class="px-5 py-4 hidden sm:table-cell">
      <span class="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold"
            :class="[typeBadgeClass, isFinished ? 'opacity-60' : '']">
        {{ challenge.type === 'competitive' ? 'Competitivo' : 'Simples' }}
      </span>
    </td>

    <!-- Status — coluna de destaque -->
    <td class="px-5 py-4">
      <div class="flex flex-col gap-0.5">
        <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold w-fit"
              :class="statusBadgeClass">
          <span class="w-1.5 h-1.5 rounded-full flex-shrink-0" :class="statusDotClass" />
          {{ statusLabel }}
        </span>
        <span v-if="statusSub" class="text-[10px] text-slate-400 pl-1">{{ statusSub }}</span>
      </div>
    </td>

    <!-- Período -->
    <td class="px-5 py-4 hidden md:table-cell">
      <div class="text-xs leading-relaxed" :class="isFinished ? 'text-slate-400' : 'text-slate-500'">
        <div>{{ formatDate(challenge.starts_at) }}</div>
        <div class="flex items-center gap-1">
          <span class="text-slate-300">→</span>
          <span>{{ formatDate(challenge.ends_at) }}</span>
        </div>
      </div>
    </td>

    <!-- Participantes -->
    <td class="px-5 py-4 hidden md:table-cell">
      <span
        class="inline-flex items-center justify-center min-w-[2rem] h-6 px-2 rounded-full text-xs font-semibold"
        :class="(challenge.participants_count ?? 0) > 0
          ? (isFinished ? 'bg-slate-100 text-slate-500' : 'bg-brand-50 text-brand-700')
          : 'bg-slate-100 text-slate-400'"
      >
        {{ challenge.participants_count ?? 0 }}
      </span>
    </td>

    <!-- Ações -->
    <td class="px-5 py-4 text-right" @click.stop>
      <div class="flex items-center justify-end gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity duration-150">
        <button
          @click="$emit('view', challenge.id)"
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
          v-if="canEdit"
          @click="$emit('edit', challenge)"
          class="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs font-semibold text-slate-600
                 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors"
        >
          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
          </svg>
          Editar
        </button>
        <button
          v-if="canDelete"
          @click="$emit('delete', challenge)"
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

const props = defineProps({ challenge: { type: Object, required: true } })
defineEmits(['view', 'edit', 'delete'])

// ── Derived status ────────────────────────────────────────────────
const statusKey = computed(() => {
  if (props.challenge.status === 'finished') return 'finished'
  const now   = new Date()
  const start = new Date(props.challenge.starts_at)
  const end   = new Date(props.challenge.ends_at)
  if (now < start) return 'scheduled'
  if (now > end)   return 'expired'   // active on backend but past end date
  return 'active'
})

const isFinished = computed(() => ['finished', 'expired'].includes(statusKey.value))

const statusLabel = computed(() => ({
  active:    'Ativo',
  scheduled: 'Agendado',
  finished:  'Finalizado',
  expired:   'Encerrado',
})[statusKey.value])

const statusSub = computed(() => {
  const now = new Date()
  if (statusKey.value === 'active') {
    const end  = new Date(props.challenge.ends_at)
    const days = Math.ceil((end - now) / 864e5)
    return days > 1 ? `${days} dias restantes` : days === 1 ? 'Último dia' : null
  }
  if (statusKey.value === 'scheduled') {
    const start = new Date(props.challenge.starts_at)
    const days  = Math.ceil((start - now) / 864e5)
    return `Inicia em ${days} dia${days !== 1 ? 's' : ''}`
  }
  return null
})

const statusBadgeClass = computed(() => ({
  active:    'bg-emerald-100 text-emerald-700',
  scheduled: 'bg-blue-50 text-blue-700',
  finished:  'bg-slate-100 text-slate-500',
  expired:   'bg-slate-100 text-slate-500',
})[statusKey.value])

const statusDotClass = computed(() => ({
  active:    'bg-emerald-500',
  scheduled: 'bg-blue-400',
  finished:  'bg-slate-400',
  expired:   'bg-slate-400',
})[statusKey.value])

// ── Type styles ───────────────────────────────────────────────────
const typeIconBg    = computed(() => props.challenge.type === 'competitive' ? 'bg-violet-100' : 'bg-amber-100')
const typeIconColor = computed(() => props.challenge.type === 'competitive' ? 'text-violet-600' : 'text-amber-600')
const typeBadgeClass = computed(() => props.challenge.type === 'competitive'
  ? 'bg-violet-50 text-violet-700'
  : 'bg-amber-50 text-amber-700')

// ── Permissions ───────────────────────────────────────────────────
const canEdit   = computed(() => new Date(props.challenge.starts_at) > new Date())
const canDelete = computed(() => new Date(props.challenge.starts_at) > new Date())

function formatDate(iso) {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' })
}
</script>
