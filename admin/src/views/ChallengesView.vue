<template>
  <div>

    <!-- Page header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Desafios</h1>
        <p class="text-slate-500 text-sm mt-1">Desafios gamificados da academia.</p>
      </div>
      <button @click="openCreate"
        class="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white text-sm
               font-semibold rounded-lg hover:bg-brand-700 transition-colors shadow-sm
               shadow-brand-600/20 flex-shrink-0">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Criar desafio
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
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar desafios</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadChallenges" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else>

      <!-- Stats strip -->
      <div class="grid grid-cols-3 gap-4 mb-6">
        <!-- Total -->
        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zm0 9.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zm9.75-9.75A2.25 2.25 0 0115.75 3.75H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zm0 9.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Total</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ allChallenges.length }}</template>
            </p>
          </div>
        </div>

        <!-- Ativos -->
        <div class="card px-4 py-3.5 flex items-center gap-3 cursor-pointer hover:shadow-md transition-shadow"
             @click="statusFilter = statusFilter === 'active' ? 'all' : 'active'">
          <div class="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center flex-shrink-0 relative">
            <svg class="w-4 h-4 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
            </svg>
            <span v-if="activeCount > 0" class="absolute -top-0.5 -right-0.5 flex h-2.5 w-2.5">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
              <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500" />
            </span>
          </div>
          <div>
            <p class="text-xs text-slate-500">Ativos agora</p>
            <p class="text-lg font-bold leading-tight"
               :class="activeCount > 0 ? 'text-emerald-700' : 'text-slate-900'">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ activeCount }}</template>
            </p>
          </div>
        </div>

        <!-- Finalizados -->
        <div class="card px-4 py-3.5 flex items-center gap-3 cursor-pointer hover:shadow-md transition-shadow"
             @click="statusFilter = statusFilter === 'finished' ? 'all' : 'finished'">
          <div class="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Finalizados</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ finishedCount }}</template>
            </p>
          </div>
        </div>
      </div>

      <!-- Filters + Search -->
      <div class="flex flex-col sm:flex-row sm:items-center gap-3 mb-4">

        <!-- Status filter pills -->
        <div class="flex items-center gap-1.5 bg-slate-100 p-1 rounded-lg flex-shrink-0">
          <button v-for="f in statusFilters" :key="f.value"
            @click="statusFilter = f.value"
            class="px-3 py-1 text-xs font-semibold rounded-md transition-all"
            :class="statusFilter === f.value
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
          <input v-model="search" type="text" placeholder="Buscar por nome…"
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
          {{ displayedChallenges.length }} resultado{{ displayedChallenges.length !== 1 ? 's' : '' }}
        </span>
      </div>

      <!-- Table -->
      <ChallengesTable :challenges="displayedChallenges" :loading="loading" :search="search"
        @view="goToChallenge" @edit="openEdit" @delete="askDelete" />

    </template>

    <!-- Create / Edit Modal -->
    <ChallengeModal v-model="modalOpen" :challenge-to-edit="challengeToEdit" @saved="onSaved" />

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
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Excluir desafio</h3>
            <p class="text-sm text-slate-500 text-center mb-5">
              Tem certeza que deseja excluir
              <strong class="text-slate-700">"{{ deleteTarget.name }}"</strong>?
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
import ChallengesTable from '../components/challenges/ChallengesTable.vue'
import ChallengeModal  from '../components/challenges/ChallengeModal.vue'

const router          = useRouter()
const allChallenges   = ref([])
const loading         = ref(true)
const error           = ref('')
const search          = ref('')
const statusFilter    = ref('all')
const modalOpen       = ref(false)
const challengeToEdit = ref(null)
const deleteTarget    = ref(null)
const deleting        = ref(false)
const deleteError     = ref('')

function getChallengeStatus(c) {
  if (c.status === 'finished') return 'finished'
  const now   = new Date()
  const start = new Date(c.starts_at)
  const end   = new Date(c.ends_at)
  if (now < start) return 'scheduled'
  if (now > end)   return 'expired'
  return 'active'
}

const activeCount   = computed(() => allChallenges.value.filter((c) => getChallengeStatus(c) === 'active').length)
const scheduledCount = computed(() => allChallenges.value.filter((c) => getChallengeStatus(c) === 'scheduled').length)
const finishedCount = computed(() => allChallenges.value.filter((c) => ['finished', 'expired'].includes(getChallengeStatus(c))).length)

const statusFilters = computed(() => [
  { value: 'all',      label: 'Todos',      count: allChallenges.value.length },
  { value: 'active',   label: 'Ativos',     count: activeCount.value },
  { value: 'scheduled',label: 'Agendados',  count: scheduledCount.value },
  { value: 'finished', label: 'Finalizados', count: finishedCount.value },
])

const displayedChallenges = computed(() => {
  let list = allChallenges.value

  if (statusFilter.value !== 'all') {
    list = list.filter((c) => {
      const s = getChallengeStatus(c)
      if (statusFilter.value === 'finished') return ['finished', 'expired'].includes(s)
      return s === statusFilter.value
    })
  }

  const q = search.value.trim().toLowerCase()
  if (q) list = list.filter((c) => c.name.toLowerCase().includes(q))

  return list
})

async function loadChallenges() {
  loading.value = true; error.value = ''
  try {
    const { data } = await api.get('/admin/challenges')
    allChallenges.value = data.challenges ?? []
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar os desafios.'
  } finally { loading.value = false }
}

function openCreate() { challengeToEdit.value = null; modalOpen.value = true }
function openEdit(c)  { challengeToEdit.value = c;    modalOpen.value = true }
function onSaved()    { loadChallenges() }

function goToChallenge(id) { router.push(`/challenges/${id}`) }

function askDelete(c)   { deleteError.value = ''; deleteTarget.value = c }
function cancelDelete() { if (!deleting.value) deleteTarget.value = null }

async function confirmDelete() {
  if (!deleteTarget.value) return
  deleting.value = true; deleteError.value = ''
  try {
    await api.delete(`/admin/challenges/${deleteTarget.value.id}`)
    allChallenges.value = allChallenges.value.filter((c) => c.id !== deleteTarget.value.id)
    deleteTarget.value  = null
  } catch (e) {
    deleteError.value = e.response?.data?.message ?? 'Erro ao excluir desafio.'
  } finally { deleting.value = false }
}

onMounted(loadChallenges)
</script>
