<template>
  <Teleport to="body">
    <Transition enter-active-class="transition duration-200" enter-from-class="opacity-0" leave-active-class="transition duration-150" leave-to-class="opacity-0">
      <div v-if="modelValue" class="fixed inset-0 z-[70] flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="close" />
        <section class="relative z-10 flex max-h-[85vh] w-full max-w-lg flex-col overflow-hidden rounded-2xl bg-white shadow-2xl">
          <header class="flex items-start justify-between gap-4 border-b border-slate-100 px-6 py-5">
            <div>
              <div class="mb-2 flex h-10 w-10 items-center justify-center rounded-xl bg-brand-50 text-brand-600">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0z" /></svg>
              </div>
              <h2 class="text-base font-semibold text-slate-900">Selecionar aluno</h2>
              <p class="mt-1 text-xs text-slate-500">Escolha quem receberá <strong class="text-slate-700">{{ planName }}</strong>.</p>
            </div>
            <button type="button" class="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600" @click="close">
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
          </header>

          <div class="border-b border-slate-100 px-4 py-3">
            <div class="relative">
              <svg class="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" /></svg>
              <input v-model="search" type="search" placeholder="Filtrar alunos por nome ou e-mail" class="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-9 pr-4 text-sm outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:bg-white focus:ring-2 focus:ring-brand-100" />
            </div>
            <p v-if="!loading" class="mt-2 px-1 text-[11px] font-medium text-slate-400">{{ filteredStudents.length }} {{ filteredStudents.length === 1 ? 'aluno disponível' : 'alunos disponíveis' }}</p>
          </div>

          <div class="min-h-0 flex-1 overflow-y-auto p-3">
            <div v-if="loading" class="flex items-center justify-center gap-2 py-14 text-sm text-slate-400">
              <svg class="h-4 w-4 animate-spin text-brand-500" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/></svg>
              Carregando alunos...
            </div>
            <div v-else-if="loadError" class="py-12 text-center">
              <p class="text-sm font-semibold text-slate-700">Não foi possível carregar os alunos</p>
              <p class="mt-1 text-xs text-slate-400">{{ loadError }}</p>
              <button type="button" class="btn-secondary mt-4 text-xs" @click="loadStudents">Tentar novamente</button>
            </div>
            <div v-else-if="!filteredStudents.length" class="py-14 text-center">
              <p class="text-sm font-semibold text-slate-700">{{ search ? 'Nenhum aluno encontrado' : 'Nenhum aluno cadastrado' }}</p>
              <p class="mt-1 text-xs text-slate-400">{{ search ? 'Tente outro nome ou e-mail.' : 'Cadastre um aluno para atribuir este plano.' }}</p>
            </div>
            <div v-else class="space-y-1">
              <button v-for="student in filteredStudents" :key="student.id" type="button" class="flex w-full items-center gap-3 rounded-xl border px-3 py-3 text-left transition" :class="selectedId === student.id ? 'border-brand-300 bg-brand-50 ring-1 ring-brand-100' : 'border-transparent hover:border-slate-200 hover:bg-slate-50'" @click="selectedId = student.id">
                <span class="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full text-xs font-bold text-white" :style="{ backgroundColor: avatarColor(student.name) }">{{ initials(student.name) }}</span>
                <span class="min-w-0 flex-1"><span class="block truncate text-sm font-semibold text-slate-800">{{ student.name }}</span><span class="block truncate text-xs text-slate-400">{{ student.email }}</span></span>
                <span class="flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full border-2" :class="selectedId === student.id ? 'border-brand-600 bg-brand-600' : 'border-slate-300'">
                  <svg v-if="selectedId === student.id" class="h-3 w-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" /></svg>
                </span>
              </button>
            </div>
          </div>

          <p v-if="submitError" class="mx-4 mb-2 rounded-xl bg-red-50 px-3 py-2.5 text-xs font-medium text-red-600">{{ submitError }}</p>
          <footer class="flex items-center justify-between gap-3 border-t border-slate-100 bg-slate-50/60 px-4 py-4">
            <button type="button" class="btn-secondary" @click="close">Cancelar</button>
            <button type="button" :disabled="!selectedStudent || submitting" class="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-50" @click="assign">
              <svg v-if="submitting" class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/></svg>
              {{ submitting ? 'Atribuindo...' : 'Atribuir plano' }}
            </button>
          </footer>
        </section>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import api from '../../services/api.js'

const props = defineProps({ modelValue: Boolean, planId: { type: [Number, String], required: true }, planName: { type: String, default: 'este plano' } })
const emit = defineEmits(['update:modelValue', 'assigned'])
const students = ref([])
const loading = ref(false)
const loadError = ref('')
const submitError = ref('')
const submitting = ref(false)
const search = ref('')
const selectedId = ref(null)

const filteredStudents = computed(() => {
  const query = search.value.trim().toLocaleLowerCase('pt-BR')
  if (!query) return students.value
  return students.value.filter((student) => student.name?.toLocaleLowerCase('pt-BR').includes(query) || student.email?.toLocaleLowerCase('pt-BR').includes(query))
})
const selectedStudent = computed(() => students.value.find((student) => student.id === selectedId.value) ?? null)

watch(() => props.modelValue, async (open) => {
  if (!open) return
  search.value = ''
  selectedId.value = null
  submitError.value = ''
  await loadStudents()
})

async function loadStudents() {
  loading.value = true
  loadError.value = ''
  try {
    const { data } = await api.get('/admin/users')
    students.value = (data.users ?? []).filter((student) => !student.is_visitor)
  } catch (error) {
    students.value = []
    loadError.value = error.response?.data?.message ?? 'Tente novamente em alguns instantes.'
  } finally { loading.value = false }
}

async function assign() {
  if (!selectedStudent.value || submitting.value) return
  submitting.value = true
  submitError.value = ''
  try {
    const { data } = await api.post(`/admin/users/${selectedStudent.value.id}/assign-plan`, { plan_id: Number(props.planId) })
    emit('assigned', { user: selectedStudent.value, pending: data.pending === true })
    close()
  } catch (error) {
    submitError.value = error.response?.data?.message ?? 'Não foi possível atribuir o plano.'
  } finally { submitting.value = false }
}

function close() { if (!submitting.value) emit('update:modelValue', false) }
const COLORS = ['#2563eb', '#7c3aed', '#db2777', '#059669', '#d97706', '#dc2626', '#0891b2']
function initials(name) { return (name ?? '').split(' ').filter(Boolean).slice(0, 2).map((part) => part[0]).join('').toUpperCase() }
function avatarColor(name) { let hash = 0; for (const character of (name ?? '')) hash = (hash * 31 + character.charCodeAt(0)) & 0xffff; return COLORS[hash % COLORS.length] }
</script>
