<template>
  <div>

    <!-- Breadcrumb -->
    <button @click="$router.push('/chains')"
      class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors mb-5">
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
      </svg>
      Redes
    </button>

    <!-- Loading -->
    <div v-if="loading" class="space-y-5 animate-pulse">
      <div class="card px-6 py-5">
        <div class="flex items-center gap-4">
          <div class="w-14 h-14 rounded-xl bg-slate-100 flex-shrink-0" />
          <div class="flex-1 space-y-2">
            <div class="h-5 w-48 bg-slate-100 rounded" />
            <div class="h-3.5 w-32 bg-slate-100 rounded" />
          </div>
        </div>
      </div>
      <div class="card p-5">
        <div class="h-4 w-32 bg-slate-100 rounded mb-4" />
        <div v-for="n in 3" :key="n" class="h-12 bg-slate-50 rounded-lg mb-2" />
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar rede</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else-if="chain">

      <!-- ── HEADER CARD ──────────────────────────────────────────────────── -->
      <div class="card px-6 py-5 mb-5">
        <div class="flex flex-col sm:flex-row sm:items-center gap-5">
          <div class="flex items-center gap-4 flex-1 min-w-0">
            <div class="w-14 h-14 rounded-2xl flex items-center justify-center text-xl font-bold flex-shrink-0 shadow-md"
                 :style="chain.logo_url ? '' : 'background-color: #2563EB'"
                 :class="chain.logo_url ? 'bg-slate-100 overflow-hidden' : 'text-white'">
              <img v-if="chain.logo_url" :src="chain.logo_url" :alt="chain.name" class="w-full h-full object-cover" />
              <span v-else>{{ chain.name[0] }}</span>
            </div>
            <div class="min-w-0">
              <h1 class="text-xl font-bold text-slate-900 leading-tight">{{ chain.name }}</h1>
              <code class="text-xs text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded mt-1 inline-block">{{ chain.slug }}</code>
              <div class="flex items-center gap-2 mt-2">
                <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-brand-50 text-brand-700">
                  {{ chain.gyms_count }} filial{{ chain.gyms_count !== 1 ? 'is' : '' }}
                </span>
              </div>
            </div>
          </div>
          <div class="flex items-center gap-2 flex-shrink-0">
            <button @click="$router.push(`/chains/${chain.id}/edit`)"
              class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-semibold text-slate-600
                     border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
              </svg>
              Editar
            </button>
          </div>
        </div>
      </div>

      <!-- ── FILIAIS ──────────────────────────────────────────────────────── -->
      <div class="card overflow-hidden">
        <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
          <h2 class="text-sm font-semibold text-slate-800">Filiais vinculadas</h2>
          <button @click="linkModalOpen = true"
            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-brand-600
                   border border-brand-200 rounded-lg hover:bg-brand-50 transition-colors">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Vincular academia
          </button>
        </div>

        <!-- Empty gyms -->
        <div v-if="chain.gyms.length === 0" class="px-5 py-10 text-center">
          <p class="text-sm text-slate-500">Nenhuma filial vinculada ainda.</p>
          <p class="text-xs text-slate-400 mt-1">Clique em "+ Vincular academia" para adicionar.</p>
        </div>

        <!-- Gyms list -->
        <ul v-else>
          <li v-for="gym in chain.gyms" :key="gym.id"
              class="flex items-center gap-4 px-5 py-3.5 border-b border-slate-100 last:border-0
                     hover:bg-slate-50/60 transition-colors group">
            <div class="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0">
              <svg class="w-4 h-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21" />
              </svg>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-semibold text-slate-800">{{ gym.name }}</p>
              <p class="text-xs text-slate-400 mt-0.5">{{ gym.students_count }} aluno{{ gym.students_count !== 1 ? 's' : '' }}</p>
            </div>
            <button @click="confirmUnlink(gym)"
              class="px-3 py-1.5 text-xs font-semibold text-red-500 border border-red-200 rounded-lg
                     hover:bg-red-50 transition-colors">
              Desvincular
            </button>
          </li>
        </ul>
      </div>

    </template>

    <!-- ── LINK MODAL ──────────────────────────────────────────────────────── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="linkModalOpen"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md">

            <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
              <h2 class="text-base font-bold text-slate-900">Vincular academia</h2>
              <button @click="closeLinkModal"
                class="p-1 text-slate-400 hover:text-slate-600 rounded transition-colors">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div class="p-5">
              <p class="text-xs text-slate-500 mb-3">Selecione uma academia independente para vincular a esta rede.</p>

              <div class="relative mb-3">
                <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                </svg>
                <input v-model="gymSearch" type="text" placeholder="Buscar academia..."
                  class="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg
                         focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400" />
              </div>

              <div class="max-h-60 overflow-y-auto -mx-5 px-5">
                <div v-if="loadingGyms" class="py-6 text-center">
                  <div class="w-5 h-5 border-2 border-brand-600 border-t-transparent rounded-full animate-spin mx-auto" />
                </div>
                <p v-else-if="independentGyms.length === 0" class="py-6 text-center text-sm text-slate-400">
                  Nenhuma academia independente encontrada.
                </p>
                <ul v-else class="space-y-1">
                  <li v-for="gym in independentGyms" :key="gym.id">
                    <button @click="doLink(gym)"
                      class="w-full text-left flex items-center gap-3 px-3 py-2.5 rounded-lg
                             hover:bg-slate-50 transition-colors text-sm font-medium text-slate-700">
                      <div class="w-7 h-7 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0">
                        <span class="text-slate-500 text-[11px] font-bold">{{ gym.name[0] }}</span>
                      </div>
                      {{ gym.name }}
                    </button>
                  </li>
                </ul>
              </div>

              <p v-if="linkError" class="text-xs text-red-500 mt-3">{{ linkError }}</p>
            </div>

          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ── UNLINK CONFIRM ──────────────────────────────────────────────────── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="unlinkTarget"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6">
            <h2 class="text-base font-bold text-slate-900 mb-1">Desvincular filial</h2>
            <p class="text-sm text-slate-500 mb-5">
              Deseja desvincular <strong>{{ unlinkTarget.name }}</strong> desta rede?
              A academia ficará independente.
            </p>
            <div class="flex justify-end gap-2">
              <button @click="unlinkTarget = null"
                class="px-4 py-2 text-sm font-semibold text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                Cancelar
              </button>
              <button @click="doUnlink" :disabled="unlinking"
                class="px-4 py-2 text-sm font-semibold text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors disabled:opacity-60">
                {{ unlinking ? 'Desvinculando…' : 'Desvincular' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import api from '../services/api.js'

const route = useRoute()
const id    = route.params.id

const chain   = ref(null)
const loading = ref(true)
const error   = ref(null)

// Link modal
const linkModalOpen    = ref(false)
const independentGyms  = ref([])
const loadingGyms      = ref(false)
const gymSearch        = ref('')
const linkError        = ref(null)
let gymSearchTimer     = null

// Unlink
const unlinkTarget = ref(null)
const unlinking    = ref(false)

onMounted(load)

async function load() {
  loading.value = true
  error.value   = null
  try {
    const { data } = await api.get(`/super/chains/${id}`)
    chain.value = data
  } catch {
    error.value = 'Erro ao carregar rede.'
  } finally {
    loading.value = false
  }
}

// ── Link modal ──────────────────────────────────────────────────────────────

watch(gymSearch, () => {
  clearTimeout(gymSearchTimer)
  gymSearchTimer = setTimeout(fetchIndependentGyms, 350)
})

async function openLinkModal() {
  linkModalOpen.value = true
  await fetchIndependentGyms()
}

watch(linkModalOpen, (val) => { if (val) fetchIndependentGyms() })

async function fetchIndependentGyms() {
  loadingGyms.value = true
  linkError.value   = null
  try {
    const params = gymSearch.value.trim() ? `?search=${encodeURIComponent(gymSearch.value.trim())}` : ''
    const { data } = await api.get(`/super/gyms/independent${params}`)
    independentGyms.value = data.gyms
  } catch {
    linkError.value = 'Erro ao buscar academias.'
  } finally {
    loadingGyms.value = false
  }
}

function closeLinkModal() {
  linkModalOpen.value = false
  gymSearch.value     = ''
  linkError.value     = null
}

async function doLink(gym) {
  linkError.value = null
  try {
    await api.post(`/super/chains/${id}/gyms`, { gym_id: gym.id })
    closeLinkModal()
    await load()
  } catch (e) {
    linkError.value = e.response?.data?.message ?? 'Erro ao vincular academia.'
  }
}

// ── Unlink ───────────────────────────────────────────────────────────────────

function confirmUnlink(gym) {
  unlinkTarget.value = gym
}

async function doUnlink() {
  if (!unlinkTarget.value) return
  unlinking.value = true
  try {
    await api.delete(`/super/chains/${id}/gyms/${unlinkTarget.value.id}`)
    unlinkTarget.value = null
    await load()
  } catch {
    unlinkTarget.value = null
  } finally {
    unlinking.value = false
  }
}
</script>

<style scoped>
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s ease; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
</style>
