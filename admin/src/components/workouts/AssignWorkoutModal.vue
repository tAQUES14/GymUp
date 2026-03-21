<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition duration-200"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-150"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="modelValue"
        class="fixed inset-0 z-50 flex items-center justify-center p-4"
      >
        <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="close" />

        <Transition
          enter-active-class="transition duration-200"
          enter-from-class="opacity-0 scale-95 translate-y-2"
          enter-to-class="opacity-100 scale-100 translate-y-0"
          leave-active-class="transition duration-150"
          leave-from-class="opacity-100 scale-100"
          leave-to-class="opacity-0 scale-95"
        >
          <div
            v-if="modelValue"
            class="relative z-10 bg-white rounded-2xl shadow-2xl w-full max-w-md flex flex-col overflow-hidden"
            style="max-height: 85vh"
          >

            <!-- Header -->
            <div class="px-6 py-4 border-b border-slate-100">
              <div class="flex items-start justify-between gap-3">
                <div>
                  <h2 class="text-base font-semibold text-slate-900">Atribuir treino para alunos</h2>
                  <p class="text-xs text-slate-400 mt-0.5 leading-relaxed">
                    Cada aluno receberá uma cópia independente de
                    <strong class="text-slate-600">"{{ workout?.name }}"</strong>.
                  </p>
                </div>
                <button
                  @click="close"
                  class="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors flex-shrink-0 mt-0.5"
                >
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            </div>

            <!-- Search + select all -->
            <div class="px-4 pt-4 pb-2 space-y-2">
              <!-- Search -->
              <div class="relative">
                <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400 pointer-events-none"
                  fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round"
                    d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                </svg>
                <input
                  v-model="search"
                  type="text"
                  placeholder="Buscar aluno…"
                  class="w-full pl-8 pr-3 py-2 text-sm border border-slate-200 rounded-lg
                         focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent
                         placeholder-slate-400 transition"
                />
              </div>

              <!-- Select all / count -->
              <div class="flex items-center justify-between px-0.5">
                <label class="flex items-center gap-2 cursor-pointer select-none">
                  <div
                    class="w-4 h-4 rounded border-2 flex items-center justify-center flex-shrink-0 transition-all cursor-pointer"
                    :class="allSelected
                      ? 'bg-brand-600 border-brand-600'
                      : someSelected
                        ? 'bg-brand-100 border-brand-400'
                        : 'border-slate-300'"
                    @click="toggleSelectAll"
                  >
                    <svg v-if="allSelected" class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    <div v-else-if="someSelected" class="w-1.5 h-0.5 bg-brand-600 rounded" />
                  </div>
                  <span class="text-xs font-medium text-slate-600">
                    {{ allSelected ? 'Desmarcar todos' : 'Selecionar todos' }}
                  </span>
                </label>
                <span class="text-xs text-slate-400">
                  {{ selectedIds.size }} selecionado{{ selectedIds.size !== 1 ? 's' : '' }}
                </span>
              </div>
            </div>

            <!-- Student list -->
            <div class="flex-1 overflow-y-auto px-4 pb-2">

              <div v-if="loading" class="flex items-center justify-center py-10 text-sm text-slate-400">
                <svg class="animate-spin w-4 h-4 mr-2 text-brand-500" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
                Carregando alunos…
              </div>

              <div v-else-if="!filteredStudents.length" class="py-10 text-center text-sm text-slate-400">
                {{ search ? 'Nenhum aluno encontrado.' : 'Nenhum aluno cadastrado.' }}
              </div>

              <div v-else class="space-y-0.5">
                <div
                  v-for="student in filteredStudents"
                  :key="student.id"
                  class="flex items-center gap-3 px-3 py-2.5 rounded-xl hover:bg-slate-50 cursor-pointer transition-colors"
                  :class="selectedIds.has(student.id) ? 'bg-brand-50/60' : ''"
                  @click="toggleStudent(student.id)"
                >
                  <!-- Checkbox -->
                  <div
                    class="w-4 h-4 rounded border-2 flex items-center justify-center flex-shrink-0 transition-all"
                    :class="selectedIds.has(student.id)
                      ? 'bg-brand-600 border-brand-600'
                      : 'border-slate-300'"
                  >
                    <svg v-if="selectedIds.has(student.id)" class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>

                  <!-- Avatar -->
                  <div
                    class="w-7 h-7 rounded-full flex items-center justify-center text-[10px] font-bold text-white flex-shrink-0"
                    :style="{ backgroundColor: avatarColor(student.name) }"
                  >
                    {{ initials(student.name) }}
                  </div>

                  <!-- Info -->
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-slate-700 truncate leading-tight">{{ student.name }}</p>
                    <p class="text-[11px] text-slate-400 truncate leading-tight">{{ student.email }}</p>
                  </div>

                  <!-- Already has badge -->
                  <span
                    v-if="alreadyAssigned.has(student.id)"
                    class="text-[10px] font-semibold px-1.5 py-0.5 bg-amber-50 text-amber-600 rounded-full flex-shrink-0"
                  >
                    já tem
                  </span>
                </div>
              </div>
            </div>

            <!-- Result message -->
            <div v-if="resultMessage" class="px-4 py-2">
              <div
                class="flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-medium"
                :class="resultMessage.type === 'success'
                  ? 'bg-emerald-50 text-emerald-700'
                  : 'bg-red-50 text-red-600'"
              >
                <svg v-if="resultMessage.type === 'success'" class="w-3.5 h-3.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {{ resultMessage.text }}
              </div>
            </div>

            <!-- Footer -->
            <div class="flex items-center justify-between gap-3 px-4 py-3.5 border-t border-slate-100 bg-slate-50/50">
              <button @click="close" class="btn-secondary text-sm">Fechar</button>
              <button
                @click="assign"
                :disabled="selectedIds.size === 0 || submitting"
                class="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white text-sm
                       font-semibold rounded-lg hover:bg-brand-700 transition-colors
                       disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <svg v-if="submitting" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
                <svg v-else class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9" />
                </svg>
                {{ submitting ? 'Enviando…' : `Atribuir para ${selectedIds.size || ''} aluno${selectedIds.size !== 1 ? 's' : ''}` }}
              </button>
            </div>

          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue'
import api from '../../services/api.js'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  workout:    { type: Object,  default: null  },
})

const emit = defineEmits(['update:modelValue', 'assigned'])

// ── State ─────────────────────────────────────────────────────────────────────

const students       = ref([])
const loading        = ref(false)
const search         = ref('')
const selectedIds    = ref(new Set())
const alreadyAssigned = ref(new Set())
const submitting     = ref(false)
const resultMessage  = ref(null)

// ── Computed ──────────────────────────────────────────────────────────────────

const filteredStudents = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return students.value
  return students.value.filter(
    (s) => s.name.toLowerCase().includes(q) || s.email.toLowerCase().includes(q)
  )
})

const allSelected  = computed(() =>
  filteredStudents.value.length > 0 &&
  filteredStudents.value.every((s) => selectedIds.value.has(s.id))
)
const someSelected = computed(() =>
  !allSelected.value && filteredStudents.value.some((s) => selectedIds.value.has(s.id))
)

// ── Watchers ──────────────────────────────────────────────────────────────────

watch(
  () => props.modelValue,
  async (open) => {
    if (!open) return
    search.value        = ''
    selectedIds.value   = new Set()
    resultMessage.value = null
    await loadStudents()
  }
)

// ── Actions ───────────────────────────────────────────────────────────────────

async function loadStudents() {
  loading.value = true
  try {
    const { data } = await api.get('/admin/users')
    students.value = data.users ?? []

    // Marca alunos que já possuem uma cópia deste template
    if (props.workout?.id) {
      const workoutsResp = await api.get('/admin/workouts')
      const all = workoutsResp.data.workouts ?? []
      const ids = all
        .filter((w) => w.template_id === props.workout.id)
        .map((w) => w.user_id)
      alreadyAssigned.value = new Set(ids)
    }
  } catch {
    // silencioso
  } finally {
    loading.value = false
  }
}

function toggleStudent(id) {
  const set = new Set(selectedIds.value)
  if (set.has(id)) {
    set.delete(id)
  } else {
    set.add(id)
  }
  selectedIds.value = set
}

function toggleSelectAll() {
  if (allSelected.value) {
    const set = new Set(selectedIds.value)
    filteredStudents.value.forEach((s) => set.delete(s.id))
    selectedIds.value = set
  } else {
    const set = new Set(selectedIds.value)
    filteredStudents.value.forEach((s) => set.add(s.id))
    selectedIds.value = set
  }
}

async function assign() {
  if (selectedIds.value.size === 0 || !props.workout) return
  submitting.value    = true
  resultMessage.value = null
  try {
    const { data } = await api.post(`/admin/workouts/${props.workout.id}/assign`, {
      user_ids: [...selectedIds.value],
    })
    resultMessage.value = { type: 'success', text: data.message }
    // Refresh already-assigned set
    data.assigned > 0 && (await loadStudents())
    emit('assigned', data)
    selectedIds.value = new Set()
  } catch (e) {
    resultMessage.value = {
      type: 'error',
      text: e.response?.data?.message ?? 'Erro ao atribuir treino.',
    }
  } finally {
    submitting.value = false
  }
}

function close() {
  emit('update:modelValue', false)
}

// ── Avatar helpers ────────────────────────────────────────────────────────────

const COLORS = ['#2563eb', '#7c3aed', '#db2777', '#059669', '#d97706', '#dc2626', '#0891b2']

function initials(name) {
  return (name ?? '')
    .split(' ')
    .slice(0, 2)
    .map((n) => n[0] ?? '')
    .join('')
    .toUpperCase()
}

function avatarColor(name) {
  let hash = 0
  for (const c of (name ?? '')) hash = (hash * 31 + c.charCodeAt(0)) & 0xffff
  return COLORS[hash % COLORS.length]
}
</script>
