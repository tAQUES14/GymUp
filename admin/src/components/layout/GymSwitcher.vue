<template>
  <div v-if="show" class="relative" ref="wrapperRef">

    <!-- ── Trigger ────────────────────────────────────────────────────────── -->
    <button
      @click="toggleOpen"
      :disabled="switching"
      aria-haspopup="listbox"
      :aria-expanded="open"
      class="flex items-center gap-2 h-8 px-3 rounded-lg text-sm font-medium
             border border-slate-200 bg-slate-50 hover:bg-slate-100
             text-slate-700 transition-colors select-none disabled:opacity-60"
    >
      <!-- Building icon -->
      <svg class="w-4 h-4 text-slate-500 shrink-0" fill="none" viewBox="0 0 24 24"
           stroke="currentColor" stroke-width="1.8">
        <path stroke-linecap="round" stroke-linejoin="round"
              d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Z" />
      </svg>

      <span class="hidden sm:block max-w-[9rem] truncate">
        {{ activeGym?.name ?? '—' }}
      </span>

      <!-- Spinner during switch -->
      <svg v-if="switching" class="w-3.5 h-3.5 animate-spin text-brand-600 shrink-0"
           fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" />
        <path class="opacity-75" fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
      </svg>
      <!-- Chevron when idle -->
      <svg v-else
           class="w-3.5 h-3.5 text-slate-400 shrink-0 transition-transform duration-200"
           :class="{ 'rotate-180': open }"
           fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <!-- ── Dropdown ────────────────────────────────────────────────────────── -->
    <Transition name="gymswitch-drop">
      <div
        v-if="open"
        role="listbox"
        class="absolute right-0 top-full mt-2 w-72 bg-white rounded-xl
               border border-slate-100 shadow-xl z-50 overflow-hidden"
      >
        <div class="px-3.5 py-2.5 bg-slate-50/80 border-b border-slate-100">
          <p class="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
            Suas filiais
          </p>
        </div>

        <ul class="py-1.5" role="group">
          <li v-for="gym in gyms" :key="gym.id" role="option" :aria-selected="gym.is_active">
            <button
              @click="handleSwitch(gym)"
              :disabled="gym.is_active || switching"
              class="w-full flex items-center gap-3 px-3.5 py-2.5 text-left
                     transition-colors hover:bg-slate-50 disabled:cursor-default"
              :class="gym.is_active ? 'bg-brand-50/50' : ''"
            >
              <!-- Gym avatar -->
              <div class="w-8 h-8 rounded-lg flex items-center justify-center shrink-0 transition-colors"
                   :class="gym.is_active ? 'bg-brand-100' : 'bg-slate-100'">
                <svg class="w-4 h-4 transition-colors"
                     :class="gym.is_active ? 'text-brand-600' : 'text-slate-400'"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                  <path stroke-linecap="round" stroke-linejoin="round"
                        d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21m-3.75 3.75h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Zm0 3h.008v.008h-.008v-.008Z" />
                </svg>
              </div>

              <!-- Name + label -->
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium truncate transition-colors"
                   :class="gym.is_active ? 'text-brand-700' : 'text-slate-700'">
                  {{ gym.name }}
                </p>
                <p v-if="gym.is_primary" class="text-[11px] text-slate-400 leading-none mt-0.5">
                  Principal
                </p>
              </div>

              <!-- Active badge -->
              <span
                v-if="gym.is_active"
                class="shrink-0 text-[11px] font-semibold px-2 py-0.5 rounded-full
                       bg-brand-100 text-brand-700 leading-none"
              >
                Ativo
              </span>
            </button>
          </li>
        </ul>
      </div>
    </Transition>

    <!-- ── Toast (portado para body) ──────────────────────────────────────── -->
    <Teleport to="body">
      <Transition name="gymswitch-toast">
        <div
          v-if="toast"
          class="fixed bottom-5 right-5 z-[200] flex items-center gap-2.5
                 px-4 py-3 rounded-xl shadow-xl text-sm font-medium"
          :class="toast.type === 'success' ? 'bg-emerald-600 text-white' : 'bg-red-600 text-white'"
        >
          <!-- Success checkmark -->
          <svg v-if="toast.type === 'success'" class="w-4 h-4 shrink-0"
               fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
          </svg>
          <!-- Error X -->
          <svg v-else class="w-4 h-4 shrink-0"
               fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
          {{ toast.message }}
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'
import { useAuthStore } from '../../stores/auth.js'
import api from '../../services/api.js'

const auth       = useAuthStore()
const gyms       = ref([])
const open       = ref(false)
const switching  = ref(false)
const toast      = ref(null)
const wrapperRef = ref(null)

const activeGym = computed(() => gyms.value.find(g => g.is_active))

// Visível apenas para trainer com mais de uma filial vinculada
const show = computed(() => auth.isTrainer && gyms.value.length > 1)

// ── Lifecycle ────────────────────────────────────────────────────────────────

onMounted(async () => {
  if (!auth.isTrainer) return

  try {
    const { data } = await api.get('/trainer/gyms')
    gyms.value = data.gyms ?? []
  } catch {
    // silencioso: se falhar, o componente simplesmente não renderiza
  }

  document.addEventListener('click', handleOutsideClick)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleOutsideClick)
})

// ── Handlers ─────────────────────────────────────────────────────────────────

function handleOutsideClick(e) {
  if (wrapperRef.value && !wrapperRef.value.contains(e.target)) {
    open.value = false
  }
}

function toggleOpen() {
  if (!switching.value) open.value = !open.value
}

async function handleSwitch(gym) {
  if (gym.is_active || switching.value) return

  open.value      = false
  switching.value = true

  try {
    await api.post('/trainer/switch-gym', { gym_id: gym.id })
    // Atualiza dados do usuário no store antes de recarregar
    await auth.refreshMe()
    showToast(`Filial alterada para ${gym.name}`, 'success')
    // Pequena pausa para o toast ser visível antes do reload
    setTimeout(() => window.location.reload(), 900)
  } catch (err) {
    const msg = err.response?.data?.message ?? 'Erro ao trocar de filial.'
    showToast(msg, 'error')
    switching.value = false
  }
}

function showToast(message, type = 'success') {
  toast.value = { message, type }
  setTimeout(() => { toast.value = null }, 3500)
}
</script>

<style scoped>
/* Dropdown slide-down */
.gymswitch-drop-enter-active,
.gymswitch-drop-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.gymswitch-drop-enter-from,
.gymswitch-drop-leave-to {
  opacity: 0;
  transform: translateY(-6px) scale(0.98);
}

/* Toast slide-up */
.gymswitch-toast-enter-active,
.gymswitch-toast-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}
.gymswitch-toast-enter-from,
.gymswitch-toast-leave-to {
  opacity: 0;
  transform: translateY(8px);
}
</style>
