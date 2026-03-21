<template>
  <div>

    <!-- Back -->
    <button @click="router.push('/workouts')"
      class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors mb-6">
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
      </svg>
      Treinos
    </button>

    <!-- Loading -->
    <div v-if="loading" class="space-y-4">
      <div class="h-8 bg-slate-100 rounded-xl w-64 animate-pulse" />
      <div class="h-5 bg-slate-100 rounded w-96 animate-pulse" />
    </div>

    <!-- Error -->
    <div v-else-if="error" class="card p-10 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Treino não encontrado</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadWorkout" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else-if="workout">

      <!-- Header do treino -->
      <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-6">
        <div>
          <div class="flex items-center gap-3 mb-1">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0" :class="iconBg">
              <svg class="w-5 h-5" :class="iconColor" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M6.429 9.75L2.25 12l4.179 2.25m0-4.5l5.571 3 5.571-3m-11.142 0L2.25 7.5 12 2.25l9.75 5.25-4.179 2.25m0 0L21.75 12l-4.179 2.25m0 0l4.179 2.25L12 21.75 2.25 16.5l4.179-2.25m11.142 0l-5.571 3-5.571-3" />
              </svg>
            </div>
            <h1 class="text-2xl font-bold text-slate-900 tracking-tight">{{ workout.name }}</h1>
          </div>
          <p v-if="workout.description" class="text-sm text-slate-500 ml-13 mb-2">{{ workout.description }}</p>

          <!-- Meta chips -->
          <div class="flex items-center flex-wrap gap-2 mt-2">
            <span v-if="workout.level"
              class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold" :class="levelClass">
              {{ levelLabel }}
            </span>
            <span v-if="workout.duration" class="inline-flex items-center gap-1 text-xs text-slate-500">
              <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              {{ workout.duration }} min
            </span>
            <span class="inline-flex items-center gap-1 text-xs text-slate-500">
              <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 9h16.5m-16.5 6.75h16.5" />
              </svg>
              {{ workout.exercises?.length ?? 0 }} exercícios
            </span>
            <span class="inline-flex items-center gap-1 text-xs text-slate-500">
              <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
              </svg>
              {{ workout.assigned_count ?? 0 }} aluno{{ workout.assigned_count !== 1 ? 's' : '' }}
            </span>
            <span v-if="workout.is_generated"
              class="inline-flex items-center gap-1 px-2 py-0.5 bg-violet-50 text-violet-700 rounded-full text-[11px] font-semibold">
              <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
              </svg>
              IA GymUp
            </span>
            <span v-else class="text-xs text-slate-400">por {{ workout.created_by }}</span>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-2 flex-shrink-0">
          <button @click="openEdit"
            class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-semibold text-slate-600
                   border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
            </svg>
            Editar
          </button>
        </div>
      </div>

      <!-- Tab bar -->
      <div class="flex gap-1 mb-6 border-b border-slate-200">
        <button
          v-for="tab in tabs" :key="tab.id"
          @click="activeTab = tab.id"
          class="px-4 py-2.5 text-sm font-semibold transition-colors border-b-2 -mb-px"
          :class="activeTab === tab.id
            ? 'border-brand-600 text-brand-600'
            : 'border-transparent text-slate-500 hover:text-slate-700'"
        >
          {{ tab.label }}
          <span v-if="tab.count !== null"
            class="ml-1.5 inline-flex items-center justify-center w-5 h-5 rounded-full text-[10px] font-bold"
            :class="activeTab === tab.id ? 'bg-brand-100 text-brand-700' : 'bg-slate-100 text-slate-500'">
            {{ tab.count }}
          </span>
        </button>
      </div>

      <!-- ── TAB: Exercícios ─────────────────────────────────────────────── -->
      <div v-if="activeTab === 'exercises'">
        <div v-if="!workout.exercises?.length" class="card px-6 py-12 text-center text-slate-400 text-sm">
          Nenhum exercício cadastrado neste treino.
        </div>
        <div v-else class="card overflow-hidden">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="border-b border-slate-100 bg-slate-50/60">
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider w-8">#</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Exercício</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden sm:table-cell">Grupo muscular</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider text-center">Séries</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider text-center">Reps</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider text-center hidden sm:table-cell">Descanso</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(ex, idx) in workout.exercises" :key="ex.id"
                class="border-b border-slate-100 last:border-0 hover:bg-slate-50/50 transition-colors">
                <td class="px-5 py-3.5">
                  <span class="text-xs font-bold text-slate-400">{{ idx + 1 }}</span>
                </td>
                <td class="px-5 py-3.5">
                  <div class="flex items-center gap-3">
                    <!-- Exercise image or placeholder -->
                    <div class="w-9 h-9 rounded-lg bg-slate-100 flex-shrink-0 overflow-hidden">
                      <img v-if="ex.image_url" :src="ex.image_url" :alt="ex.name"
                        class="w-full h-full object-cover" />
                      <div v-else class="w-full h-full flex items-center justify-center">
                        <svg class="w-4 h-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z" />
                        </svg>
                      </div>
                    </div>
                    <span class="text-sm font-semibold text-slate-800">{{ ex.name }}</span>
                  </div>
                </td>
                <td class="px-5 py-3.5 hidden sm:table-cell">
                  <span class="text-sm text-slate-500">{{ ex.muscle_group || '—' }}</span>
                </td>
                <td class="px-5 py-3.5 text-center">
                  <span class="inline-flex items-center justify-center w-8 h-6 bg-brand-50 text-brand-700 rounded text-xs font-bold">
                    {{ ex.sets }}
                  </span>
                </td>
                <td class="px-5 py-3.5 text-center">
                  <span class="inline-flex items-center justify-center w-8 h-6 bg-slate-100 text-slate-700 rounded text-xs font-bold">
                    {{ ex.reps }}
                  </span>
                </td>
                <td class="px-5 py-3.5 text-center hidden sm:table-cell">
                  <span class="text-sm text-slate-500">{{ ex.rest }}s</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- ── TAB: Alunos ────────────────────────────────────────────────── -->
      <div v-if="activeTab === 'students'">

        <!-- Actions bar -->
        <div class="flex items-center justify-between mb-4">
          <p class="text-sm text-slate-500">
            {{ assignments.length }} aluno{{ assignments.length !== 1 ? 's' : '' }} com este treino atribuído.
          </p>
          <button @click="assignOpen = true"
            class="inline-flex items-center gap-2 px-3.5 py-2 bg-brand-600 text-white text-sm
                   font-semibold rounded-lg hover:bg-brand-700 transition-colors shadow-sm shadow-brand-600/20">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
            </svg>
            Atribuir treino
          </button>
        </div>

        <div v-if="!assignments.length" class="card px-6 py-12 text-center">
          <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
            <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
            </svg>
          </div>
          <p class="text-sm font-semibold text-slate-700 mb-1">Nenhum aluno ainda</p>
          <p class="text-xs text-slate-400">Clique em "Atribuir treino" para enviar para alunos.</p>
        </div>

        <div v-else class="card overflow-hidden">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="border-b border-slate-100 bg-slate-50/60">
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Aluno</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden sm:table-cell">E-mail</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Data</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">Status</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider text-right">Ação</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="a in assignments" :key="a.assignment_id"
                class="group border-b border-slate-100 last:border-0 hover:bg-slate-50/50 transition-colors">
                <td class="px-5 py-3.5">
                  <div class="flex items-center gap-2.5">
                    <div class="w-7 h-7 rounded-full flex items-center justify-center text-[10px] font-bold text-white flex-shrink-0"
                      :style="{ backgroundColor: avatarColor(a.user_name) }">
                      {{ initials(a.user_name) }}
                    </div>
                    <span class="text-sm font-medium text-slate-800">{{ a.user_name }}</span>
                  </div>
                </td>
                <td class="px-5 py-3.5 hidden sm:table-cell">
                  <span class="text-sm text-slate-500">{{ a.user_email }}</span>
                </td>
                <td class="px-5 py-3.5">
                  <span class="text-sm text-slate-500">{{ formatDate(a.assigned_at) }}</span>
                </td>
                <td class="px-5 py-3.5">
                  <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700">
                    <span class="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                    Atribuído
                  </span>
                </td>
                <td class="px-5 py-3.5 text-right">
                  <button
                    @click="askRemove(a)"
                    class="opacity-0 group-hover:opacity-100 transition-opacity inline-flex items-center gap-1
                           px-2.5 py-1.5 text-xs font-semibold text-red-600 border border-red-200
                           rounded-lg hover:bg-red-50 transition-colors"
                  >
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    Remover
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

    </template>

    <!-- Edit modal -->
    <WorkoutModal v-model="editOpen" :workout-to-edit="workout" @saved="loadWorkout" />

    <!-- Assign modal -->
    <AssignWorkoutModal v-model="assignOpen" :workout="workout" @assigned="loadWorkout" />

    <!-- Remove assignment confirmation -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="removeTarget" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="cancelRemove" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-sm">
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Remover atribuição</h3>
            <p class="text-sm text-slate-500 text-center mb-5">
              Remover o treino de
              <strong class="text-slate-700">{{ removeTarget?.user_name }}</strong>?
              O aluno perderá acesso a este treino no app.
            </p>
            <p v-if="removeError" class="text-xs text-red-500 text-center mb-3">{{ removeError }}</p>
            <div class="flex items-center gap-3">
              <button @click="cancelRemove" class="flex-1 btn-secondary">Cancelar</button>
              <button @click="confirmRemove" :disabled="removing"
                class="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 bg-red-600
                       text-white text-sm font-semibold rounded-lg hover:bg-red-700 transition-colors
                       disabled:opacity-60 disabled:cursor-not-allowed">
                <svg v-if="removing" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
                {{ removing ? 'Removendo…' : 'Sim, remover' }}
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
import { useRoute, useRouter } from 'vue-router'
import api from '../services/api.js'
import WorkoutModal       from '../components/workouts/WorkoutModal.vue'
import AssignWorkoutModal from '../components/workouts/AssignWorkoutModal.vue'

const route  = useRoute()
const router = useRouter()

const workout    = ref(null)
const loading    = ref(true)
const error      = ref('')
const activeTab  = ref('exercises')
const editOpen   = ref(false)
const assignOpen = ref(false)

// ── Remove assignment state ───────────────────────────────────────────────────

const removeTarget = ref(null)
const removing     = ref(false)
const removeError  = ref('')

// ── Computed ──────────────────────────────────────────────────────────────────

const assignments = computed(() => workout.value?.assignments ?? [])

const tabs = computed(() => [
  { id: 'exercises', label: 'Exercícios', count: workout.value?.exercises?.length ?? 0 },
  { id: 'students',  label: 'Alunos',     count: assignments.value.length },
])

const LEVEL_MAP = {
  beginner: 'bg-emerald-50 text-emerald-700', iniciante: 'bg-emerald-50 text-emerald-700',
  intermediate: 'bg-amber-50 text-amber-700', 'intermediário': 'bg-amber-50 text-amber-700',
  advanced: 'bg-rose-50 text-rose-700', 'avançado': 'bg-rose-50 text-rose-700',
}
const LEVEL_LABEL = {
  beginner: 'Iniciante', iniciante: 'Iniciante',
  intermediate: 'Intermediário', 'intermediário': 'Intermediário',
  advanced: 'Avançado', 'avançado': 'Avançado',
}
const levelKey   = computed(() => workout.value?.level?.toLowerCase() ?? '')
const levelClass = computed(() => LEVEL_MAP[levelKey.value] ?? 'bg-slate-100 text-slate-500')
const levelLabel = computed(() => LEVEL_LABEL[levelKey.value] ?? (workout.value?.level ?? ''))

const ICON_BG    = { beginner: 'bg-emerald-50', iniciante: 'bg-emerald-50', intermediate: 'bg-amber-50', 'intermediário': 'bg-amber-50', advanced: 'bg-rose-50', 'avançado': 'bg-rose-50' }
const ICON_COLOR = { beginner: 'text-emerald-600', iniciante: 'text-emerald-600', intermediate: 'text-amber-600', 'intermediário': 'text-amber-600', advanced: 'text-rose-600', 'avançado': 'text-rose-600' }
const iconBg    = computed(() => ICON_BG[levelKey.value]    ?? 'bg-brand-50')
const iconColor = computed(() => ICON_COLOR[levelKey.value] ?? 'text-brand-600')

// ── Data ──────────────────────────────────────────────────────────────────────

async function loadWorkout() {
  loading.value = true; error.value = ''
  try {
    const { data } = await api.get(`/admin/workouts/${route.params.id}`)
    workout.value = data
  } catch (e) {
    error.value = e.response?.status === 404
      ? 'Treino não encontrado.'
      : (e.response?.data?.message ?? 'Erro ao carregar treino.')
  } finally { loading.value = false }
}

function openEdit() { editOpen.value = true }

// ── Remove assignment ─────────────────────────────────────────────────────────

function askRemove(assignment)  { removeError.value = ''; removeTarget.value = assignment }
function cancelRemove()         { if (!removing.value) removeTarget.value = null }

async function confirmRemove() {
  if (!removeTarget.value) return
  removing.value = true; removeError.value = ''
  try {
    await api.delete(`/admin/workouts/${route.params.id}/assignments/${removeTarget.value.assignment_id}`)
    // Remove from local list
    if (workout.value) {
      workout.value.assignments = workout.value.assignments.filter(
        (a) => a.assignment_id !== removeTarget.value.assignment_id
      )
      workout.value.assigned_count = workout.value.assignments.length
    }
    removeTarget.value = null
  } catch (e) {
    removeError.value = e.response?.data?.message ?? 'Erro ao remover atribuição.'
  } finally { removing.value = false }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function formatDate(dateStr) {
  if (!dateStr) return '—'
  const [y, m, d] = dateStr.split('-')
  return `${d}/${m}/${y}`
}

const COLORS = ['#2563eb', '#7c3aed', '#db2777', '#059669', '#d97706', '#dc2626', '#0891b2']
function initials(name) {
  return (name ?? '').split(' ').slice(0, 2).map((n) => n[0] ?? '').join('').toUpperCase()
}
function avatarColor(name) {
  let h = 0
  for (const c of (name ?? '')) h = (h * 31 + c.charCodeAt(0)) & 0xffff
  return COLORS[h % COLORS.length]
}

onMounted(loadWorkout)
</script>
