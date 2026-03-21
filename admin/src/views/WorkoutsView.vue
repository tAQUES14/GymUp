<template>
  <div>

    <!-- Page header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <div class="flex items-center gap-3">
          <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Treinos</h1>
          <span v-if="!loading && !error"
            class="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs
                   font-semibold bg-brand-50 text-brand-700 border border-brand-100">
            {{ allWorkouts.length }}
          </span>
        </div>
        <p class="text-slate-500 text-sm mt-1">Biblioteca de treinos da academia.</p>
      </div>
      <button @click="openCreate"
        class="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white text-sm
               font-semibold rounded-lg hover:bg-brand-700 transition-colors shadow-sm
               shadow-brand-600/20 flex-shrink-0">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Criar treino
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
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar treinos</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadWorkouts" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else>

      <!-- Stats strip -->
      <div class="grid grid-cols-3 gap-4 mb-6">
        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M6.429 9.75L2.25 12l4.179 2.25m0-4.5l5.571 3 5.571-3m-11.142 0L2.25 7.5 12 2.25l9.75 5.25-4.179 2.25m0 0L21.75 12l-4.179 2.25m0 0l4.179 2.25L12 21.75 2.25 16.5l4.179-2.25m11.142 0l-5.571 3-5.571-3" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Total</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ allWorkouts.length }}</template>
            </p>
          </div>
        </div>

        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-violet-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-violet-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Gerados por IA</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ aiCount }}</template>
            </p>
          </div>
        </div>

        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Criados manualmente</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ manualCount }}</template>
            </p>
          </div>
        </div>
      </div>

      <!-- Search + Table -->
      <div class="space-y-4">
        <div class="flex items-center gap-3">
          <div class="relative flex-1 max-w-sm">
            <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"
              fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
            <input v-model="search" type="text" placeholder="Buscar treino por nome…"
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
          <span v-if="search" class="text-xs text-slate-500">
            {{ filteredWorkouts.length }} {{ filteredWorkouts.length === 1 ? 'resultado' : 'resultados' }}
          </span>
        </div>

        <WorkoutsTable :workouts="filteredWorkouts" :loading="loading" :search="search"
          @view="goToWorkout" @edit="openEdit" @delete="askDelete" />
      </div>

    </template>

    <!-- Create / Edit Modal -->
    <WorkoutModal v-model="modalOpen" :workout-to-edit="workoutToEdit" @saved="onSaved" />

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
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
              </svg>
            </div>
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Excluir treino</h3>
            <p class="text-sm text-slate-500 text-center mb-1">
              Tem certeza que deseja excluir
              <strong class="text-slate-700">"{{ deleteTarget.name }}"</strong>?
            </p>
            <p class="text-xs text-amber-600 text-center mb-5">
              Todas as atribuições deste treino para alunos também serão removidas.
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
import { useRouter } from 'vue-router'
import api from '../services/api.js'
import WorkoutsTable from '../components/workouts/WorkoutsTable.vue'
import WorkoutModal  from '../components/workouts/WorkoutModal.vue'

const router       = useRouter()
const allWorkouts  = ref([])
const loading      = ref(true)
const error        = ref('')
const search       = ref('')
const modalOpen    = ref(false)
const workoutToEdit = ref(null)
const deleteTarget  = ref(null)
const deleting      = ref(false)
const deleteError   = ref('')

const filteredWorkouts = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return allWorkouts.value
  return allWorkouts.value.filter((w) => w.name.toLowerCase().includes(q))
})

const aiCount     = computed(() => allWorkouts.value.filter((w) => w.is_generated).length)
const manualCount = computed(() => allWorkouts.value.filter((w) => !w.is_generated).length)

async function loadWorkouts() {
  loading.value = true; error.value = ''
  try {
    const { data } = await api.get('/admin/workouts')
    allWorkouts.value = data.workouts ?? []
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar os treinos.'
  } finally { loading.value = false }
}

function openCreate() { workoutToEdit.value = null; modalOpen.value = true }
function openEdit(w)  { workoutToEdit.value = w;    modalOpen.value = true }
function onSaved()    { loadWorkouts() }

function goToWorkout(id) { router.push(`/workouts/${id}`) }

function askDelete(w)  { deleteError.value = ''; deleteTarget.value = w }
function cancelDelete() { if (!deleting.value) deleteTarget.value = null }

async function confirmDelete() {
  if (!deleteTarget.value) return
  deleting.value = true; deleteError.value = ''
  try {
    await api.delete(`/admin/workouts/${deleteTarget.value.id}`)
    allWorkouts.value  = allWorkouts.value.filter((w) => w.id !== deleteTarget.value.id)
    deleteTarget.value = null
  } catch (e) {
    deleteError.value = e.response?.data?.message ?? 'Erro ao excluir treino.'
  } finally { deleting.value = false }
}

onMounted(loadWorkouts)
</script>
