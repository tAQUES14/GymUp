<template>
  <div>

    <!-- Page header -->
    <div class="flex items-start gap-3 mb-8">
      <RouterLink to="/exercises"
        class="p-1.5 mt-0.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors flex-shrink-0">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
        </svg>
      </RouterLink>
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Mapeamento de GIFs</h1>
        <p class="text-slate-500 text-sm mt-1">Vincule GIFs animados aos exercícios do catálogo.</p>
      </div>
    </div>

    <!-- Stats -->
    <div v-if="!loading && !error" class="grid grid-cols-3 gap-4 mb-6">
      <div class="card p-4 text-center">
        <p class="text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Sem GIF</p>
        <p class="text-3xl font-bold text-red-500">{{ stats.missing }}</p>
      </div>
      <div class="card p-4 text-center">
        <p class="text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Auto-vinculado</p>
        <p class="text-3xl font-bold text-amber-500">{{ stats.auto }}</p>
      </div>
      <div class="card p-4 text-center">
        <p class="text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Confirmado</p>
        <p class="text-3xl font-bold text-emerald-500">{{ stats.manual }}</p>
      </div>
    </div>

    <!-- Error -->
    <div v-if="error" class="card p-8 text-center mb-6">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar exercícios</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadData" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else>

      <!-- Filters -->
      <div class="flex flex-wrap items-center gap-3 mb-5">
        <div class="relative flex-1 min-w-[200px] max-w-sm">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"
            fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input v-model="search" type="text" placeholder="Buscar exercício…"
            class="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg bg-white
                   focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent
                   placeholder-slate-400 transition" />
          <button v-if="search" @click="search = ''"
            class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div class="flex gap-1.5 flex-wrap">
          <button v-for="f in statusFilters" :key="f.value"
            @click="statusFilter = statusFilter === f.value ? '' : f.value"
            :class="[
              'px-3 py-1.5 text-xs font-semibold rounded-full border transition-colors',
              statusFilter === f.value ? f.activeClass : 'bg-white border-slate-200 text-slate-600 hover:border-slate-300',
            ]">
            {{ f.label }}
            <span class="ml-1 opacity-70">{{ stats[f.value] }}</span>
          </button>
        </div>
      </div>

      <!-- Table -->
      <div class="card overflow-hidden">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-slate-100">
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider">Exercício</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider">Status</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden lg:table-cell">GIF atual</th>
              <th class="px-5 py-3.5"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="4" class="px-5 py-10 text-center">
                <div class="flex items-center justify-center gap-2 text-slate-400">
                  <svg class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                  </svg>
                  <span class="text-sm">Carregando…</span>
                </div>
              </td>
            </tr>
            <tr v-else-if="filteredExercises.length === 0">
              <td colspan="4" class="px-5 py-10 text-center text-sm text-slate-400">
                Nenhum exercício encontrado.
              </td>
            </tr>
            <tr v-for="ex in filteredExercises" :key="ex.id"
              class="border-b border-slate-50 hover:bg-slate-50/60 transition-colors">

              <!-- Name + muscle group -->
              <td class="px-5 py-4">
                <p class="font-semibold text-slate-900">{{ ex.name }}</p>
                <p class="text-xs text-slate-500 mt-0.5">{{ ex.muscle_group }}</p>
              </td>

              <!-- Status badge -->
              <td class="px-5 py-4">
                <span v-if="ex.status === 'missing'"
                  class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold
                         bg-red-50 text-red-700 border border-red-200">
                  Sem GIF
                </span>
                <span v-else-if="ex.status === 'auto'"
                  class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold
                         bg-amber-50 text-amber-700 border border-amber-200">
                  Auto
                  <span class="opacity-70">{{ ex.gif_confidence }}%</span>
                </span>
                <span v-else
                  class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold
                         bg-emerald-50 text-emerald-700 border border-emerald-200">
                  <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                  </svg>
                  Confirmado
                </span>
              </td>

              <!-- GIF preview -->
              <td class="px-5 py-3 hidden lg:table-cell">
                <div v-if="ex.gif_url" class="flex items-center gap-3">
                  <img :src="ex.gif_url" :alt="ex.name"
                    class="w-16 h-12 object-contain rounded-lg border border-slate-200 bg-slate-50 flex-shrink-0" />
                  <span class="text-[11px] text-slate-400 font-mono truncate max-w-[180px]">{{ ex.gif_file }}</span>
                </div>
                <span v-else class="text-xs text-slate-300">—</span>
              </td>

              <!-- Actions -->
              <td class="px-5 py-4">
                <div class="flex items-center justify-end gap-2">
                  <button @click="linkTarget = ex"
                    class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold
                           bg-brand-600 text-white rounded-lg hover:bg-brand-700 transition-colors shadow-sm">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round"
                        d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244" />
                    </svg>
                    {{ ex.gif_file ? 'Trocar' : 'Vincular' }}
                  </button>
                  <button v-if="ex.gif_file" @click="clearGif(ex)" :disabled="clearingId === ex.id"
                    class="p-1.5 rounded-md text-slate-400 hover:text-red-500 hover:bg-red-50
                           transition-colors disabled:opacity-40"
                    title="Remover GIF">
                    <svg v-if="clearingId === ex.id" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                    </svg>
                    <svg v-else class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

    </template>

    <!-- ── Link GIF Modal (via reusable component) ───────────────────── -->
    <GifSelectModal
      v-if="linkTarget"
      :exercise="linkTarget"
      @linked="onGifLinked"
      @close="linkTarget = null" />

    <!-- ── Success toast ─────────────────────────────────────────────────── -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-200" enter-from-class="opacity-0 translate-y-2"
        enter-to-class="opacity-100 translate-y-0" leave-active-class="transition duration-150"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="toast"
          class="fixed bottom-6 left-1/2 -translate-x-1/2 z-[80] px-4 py-2.5 bg-slate-900 text-white
                 text-sm font-medium rounded-xl shadow-xl flex items-center gap-2 pointer-events-none">
          <svg class="w-4 h-4 text-emerald-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
          </svg>
          {{ toast }}
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import api from '../services/api.js'
import GifSelectModal from '../components/exercises/GifSelectModal.vue'

// ── Data ──────────────────────────────────────────────────────────────────────

const exercises = ref([])
const loading   = ref(true)
const error     = ref('')

// ── Filters ───────────────────────────────────────────────────────────────────

const search       = ref('')
const statusFilter = ref('')

const statusFilters = [
  { value: 'missing', label: 'Sem GIF',        activeClass: 'bg-red-100 border-red-300 text-red-700' },
  { value: 'auto',    label: 'Auto-vinculado',  activeClass: 'bg-amber-100 border-amber-300 text-amber-700' },
  { value: 'manual',  label: 'Confirmado',      activeClass: 'bg-emerald-100 border-emerald-300 text-emerald-700' },
]

// ── Modal state ───────────────────────────────────────────────────────────────

const linkTarget = ref(null)
const clearingId = ref(null)
const toast      = ref('')

// ── Computed ──────────────────────────────────────────────────────────────────

const stats = computed(() => ({
  missing: exercises.value.filter((e) => e.status === 'missing').length,
  auto:    exercises.value.filter((e) => e.status === 'auto').length,
  manual:  exercises.value.filter((e) => e.status === 'manual').length,
}))

const filteredExercises = computed(() => {
  let result = exercises.value
  const q = search.value.trim().toLowerCase()
  if (q) result = result.filter((e) =>
    e.name.toLowerCase().includes(q) || e.muscle_group.toLowerCase().includes(q)
  )
  if (statusFilter.value) result = result.filter((e) => e.status === statusFilter.value)
  return result
})

// ── API calls ─────────────────────────────────────────────────────────────────

async function loadData() {
  loading.value = true
  error.value   = ''
  try {
    const { data } = await api.get('/admin/exercises/gif-mapping')
    exercises.value = data.exercises ?? []
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar os exercícios.'
  } finally {
    loading.value = false
  }
}

// ── Modal helpers ─────────────────────────────────────────────────────────────

function onGifLinked(exerciseData) {
  updateLocalExercise(exerciseData.id, {
    gif_file:       exerciseData.gif_file,
    gif_url:        exerciseData.gif_url,
    gif_confidence: exerciseData.gif_confidence,
    gif_is_auto:    exerciseData.gif_is_auto,
    status:         'manual',
  })
  linkTarget.value = null
  showToast('GIF vinculado com sucesso!')
}

async function clearGif(ex) {
  clearingId.value = ex.id
  try {
    await api.post(`/admin/exercises/${ex.id}/link-gif`, { gif_file: null })
    updateLocalExercise(ex.id, {
      gif_file:       null,
      gif_url:        null,
      gif_confidence: null,
      gif_is_auto:    false,
      status:         'missing',
    })
    showToast('GIF removido.')
  } catch {
    // silencioso
  } finally {
    clearingId.value = null
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────────

function updateLocalExercise(id, patch) {
  const idx = exercises.value.findIndex((e) => e.id === id)
  if (idx !== -1) exercises.value[idx] = { ...exercises.value[idx], ...patch }
}

function showToast(msg) {
  toast.value = msg
  setTimeout(() => { toast.value = '' }, 3000)
}

// ── Init ──────────────────────────────────────────────────────────────────────

onMounted(loadData)
</script>
