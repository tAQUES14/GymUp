<template>
  <div>

    <!-- Page header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <div class="flex items-center gap-3">
          <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Conquistas</h1>
          <span
            v-if="!loading && !error"
            class="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs
                   font-semibold bg-brand-50 text-brand-700 border border-brand-100"
          >
            {{ allAchievements.length }}
          </span>
        </div>
        <p class="text-slate-500 text-sm mt-1">Conquistas desbloqueáveis pelos alunos da academia.</p>
      </div>
      <button @click="openCreate"
        class="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white text-sm
               font-semibold rounded-lg hover:bg-brand-700 transition-colors shadow-sm
               shadow-brand-600/20 flex-shrink-0">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Nova conquista
      </button>
    </div>

    <!-- Error state -->
    <div v-if="error" class="card p-8 text-center mb-6">
      <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mb-3">
        <svg class="w-6 h-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar conquistas</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadAchievements" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else>

      <!-- Stats strip -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">

        <!-- Total -->
        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Total</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ allAchievements.length }}</template>
            </p>
          </div>
        </div>

        <!-- De treinos -->
        <div class="card px-4 py-3.5 flex items-center gap-3 cursor-pointer hover:shadow-md transition-shadow"
             @click="metricFilter = metricFilter === 'workouts_total' ? 'all' : 'workouts_total'">
          <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 transition-colors"
               :class="metricFilter === 'workouts_total' ? 'bg-brand-100' : 'bg-brand-50'">
            <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Treinos</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ workoutsCount }}</template>
            </p>
          </div>
        </div>

        <!-- De streak -->
        <div class="card px-4 py-3.5 flex items-center gap-3 cursor-pointer hover:shadow-md transition-shadow"
             @click="metricFilter = metricFilter === 'streak_days' ? 'all' : 'streak_days'">
          <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 transition-colors"
               :class="metricFilter === 'streak_days' ? 'bg-amber-100' : 'bg-amber-50'">
            <svg class="w-4 h-4 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Streak</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ streakCount }}</template>
            </p>
          </div>
        </div>

      </div>

      <!-- Filters + Search -->
      <div class="flex flex-col sm:flex-row sm:items-center gap-3 mb-6">

        <!-- Metric filter pills -->
        <div class="flex items-center gap-1.5 bg-slate-100 p-1 rounded-lg flex-shrink-0">
          <button v-for="f in metricFilters" :key="f.value"
            @click="metricFilter = f.value"
            class="px-3 py-1 text-xs font-semibold rounded-md transition-all"
            :class="metricFilter === f.value
              ? 'bg-white text-slate-900 shadow-sm'
              : 'text-slate-500 hover:text-slate-700'"
          >
            {{ f.label }}
            <span v-if="f.count !== undefined" class="ml-1 text-[10px] opacity-60">{{ f.count }}</span>
          </button>
        </div>

        <!-- Search -->
        <div class="relative flex-1 max-w-sm">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"
            fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input v-model="search" type="text" placeholder="Buscar por título…"
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

        <span v-if="search" class="text-xs text-slate-500 flex-shrink-0">
          {{ displayed.length }} resultado{{ displayed.length !== 1 ? 's' : '' }}
        </span>

      </div>

      <!-- Grid -->
      <AchievementsGrid
        :achievements="displayed"
        :loading="loading"
        :search="search"
        @edit="openEdit"
        @delete="askDelete"
      />

    </template>

    <!-- Create / Edit Modal -->
    <AchievementModal
      v-model="modalOpen"
      :achievement-to-edit="achievementToEdit"
      @saved="onSaved"
    />

    <!-- Delete confirmation -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="deleteTarget" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="cancelDelete" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-sm">
            <div class="flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mx-auto mb-4">
              <svg class="w-6 h-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
              </svg>
            </div>
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Excluir conquista</h3>
            <p class="text-sm text-slate-500 text-center mb-5">
              Tem certeza que deseja excluir
              <strong class="text-slate-700">"{{ deleteTarget.title }}"</strong>?
            </p>
            <p v-if="deleteError" class="text-xs text-red-500 text-center mb-3">{{ deleteError }}</p>
            <div class="flex items-center gap-3">
              <button @click="cancelDelete" class="flex-1 btn-secondary">Cancelar</button>
              <button @click="confirmDelete" :disabled="deleting"
                class="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 bg-red-600
                       text-white text-sm font-semibold rounded-lg hover:bg-red-700 transition-colors
                       disabled:opacity-60 disabled:cursor-not-allowed">
                <svg v-if="deleting" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
                {{ deleting ? 'Excluindo…' : 'Sim, excluir' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '../services/api.js'
import AchievementsGrid  from '../components/achievements/AchievementsGrid.vue'
import AchievementModal  from '../components/achievements/AchievementModal.vue'

const allAchievements  = ref([])
const loading          = ref(true)
const error            = ref('')
const search           = ref('')
const metricFilter     = ref('all')
const modalOpen        = ref(false)
const achievementToEdit = ref(null)
const deleteTarget     = ref(null)
const deleting         = ref(false)
const deleteError      = ref('')

const workoutsCount = computed(() =>
  allAchievements.value.filter((a) => a.metric === 'workouts_total').length
)
const streakCount = computed(() =>
  allAchievements.value.filter((a) => a.metric === 'streak_days').length
)

const metricFilters = computed(() => [
  { value: 'all',            label: 'Todas',   count: allAchievements.value.length },
  { value: 'workouts_total', label: 'Treinos', count: workoutsCount.value },
  { value: 'streak_days',    label: 'Streak',  count: streakCount.value },
])

const displayed = computed(() => {
  let list = allAchievements.value

  if (metricFilter.value !== 'all') {
    list = list.filter((a) => a.metric === metricFilter.value)
  }

  const q = search.value.trim().toLowerCase()
  if (q) list = list.filter((a) =>
    a.title.toLowerCase().includes(q) ||
    a.description.toLowerCase().includes(q)
  )

  return list
})

async function loadAchievements() {
  loading.value = true
  error.value   = ''
  try {
    const { data } = await api.get('/admin/achievements')
    allAchievements.value = data.achievements ?? []
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar as conquistas.'
  } finally {
    loading.value = false
  }
}

function openCreate() { achievementToEdit.value = null; modalOpen.value = true }
function openEdit(a)  { achievementToEdit.value = a;    modalOpen.value = true }
function onSaved()    { loadAchievements() }

function askDelete(a)   { deleteError.value = ''; deleteTarget.value = a }
function cancelDelete() { if (!deleting.value) deleteTarget.value = null }

async function confirmDelete() {
  if (!deleteTarget.value) return
  deleting.value = true; deleteError.value = ''
  try {
    await api.delete(`/admin/achievements/${deleteTarget.value.id}`)
    allAchievements.value = allAchievements.value.filter((a) => a.id !== deleteTarget.value.id)
    deleteTarget.value = null
  } catch (e) {
    deleteError.value = e.response?.data?.message ?? 'Erro ao excluir conquista.'
  } finally {
    deleting.value = false
  }
}

onMounted(loadAchievements)
</script>
