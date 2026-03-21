<template>
  <div>

    <!-- Page header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <div class="flex items-center gap-3">
          <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Recompensas</h1>
          <span
            v-if="!loading && !error"
            class="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs
                   font-semibold bg-brand-50 text-brand-700 border border-brand-100"
          >
            {{ allRewards.length }}
          </span>
        </div>
        <p class="text-slate-500 text-sm mt-1">Gerencie as recompensas resgatáveis com pontos.</p>
      </div>
      <button @click="openCreate"
        class="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white text-sm
               font-semibold rounded-lg hover:bg-brand-700 transition-colors shadow-sm
               shadow-brand-600/20 flex-shrink-0">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Nova recompensa
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
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar recompensas</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadRewards" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else>

      <!-- Stats strip -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">

        <!-- Total -->
        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M21 11.25v8.25a1.5 1.5 0 01-1.5 1.5H5.25a1.5 1.5 0 01-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 109.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1114.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Total</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ allRewards.length }}</template>
            </p>
          </div>
        </div>

        <!-- Ativas -->
        <div class="card px-4 py-3.5 flex items-center gap-3 cursor-pointer hover:shadow-md transition-shadow"
             @click="statusFilter = statusFilter === 'active' ? 'all' : 'active'">
          <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 transition-colors"
               :class="statusFilter === 'active' ? 'bg-emerald-100' : 'bg-emerald-50'">
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-500" />
          </div>
          <div>
            <p class="text-xs text-slate-500">Ativas</p>
            <p class="text-lg font-bold leading-tight"
               :class="activeCount > 0 ? 'text-emerald-700' : 'text-slate-900'">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ activeCount }}</template>
            </p>
          </div>
        </div>

        <!-- Pendentes -->
        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-orange-50 flex items-center justify-center flex-shrink-0 relative">
            <svg class="w-4 h-4 text-orange-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span v-if="totalPending > 0"
              class="absolute -top-0.5 -right-0.5 flex h-2.5 w-2.5">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-orange-400 opacity-75" />
              <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-orange-500" />
            </span>
          </div>
          <div>
            <p class="text-xs text-slate-500">Resgates pend.</p>
            <p class="text-lg font-bold leading-tight"
               :class="totalPending > 0 ? 'text-orange-600' : 'text-slate-900'">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ totalPending }}</template>
            </p>
          </div>
        </div>

        <!-- Sem estoque -->
        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-red-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M6 18L18 6M6 6l12 12" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Sem estoque</p>
            <p class="text-lg font-bold leading-tight"
               :class="outOfStockCount > 0 ? 'text-red-600' : 'text-slate-900'">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ outOfStockCount }}</template>
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
            <span class="ml-1 text-[10px] opacity-60">{{ f.count }}</span>
          </button>
        </div>

        <!-- Category filter pills -->
        <div class="flex items-center gap-1.5 bg-slate-100 p-1 rounded-lg flex-shrink-0">
          <button v-for="f in categoryFilters" :key="f.value"
            @click="categoryFilter = f.value"
            class="px-3 py-1 text-xs font-semibold rounded-md transition-all"
            :class="categoryFilter === f.value
              ? 'bg-white text-slate-900 shadow-sm'
              : 'text-slate-500 hover:text-slate-700'"
          >
            {{ f.label }}
          </button>
        </div>

        <!-- Search -->
        <div class="relative flex-1 max-w-sm">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"
            fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input v-model="search" type="text" placeholder="Buscar recompensa…"
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

      <!-- Table -->
      <RewardsTable
        :rewards="displayed"
        :loading="loading"
        :search="search"
        :toggling-id="togglingId"
        @edit="openEdit"
        @delete="askDelete"
        @toggle="handleToggle"
      />

    </template>

    <!-- Modal -->
    <RewardModal
      v-model="modalOpen"
      :reward-to-edit="rewardToEdit"
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
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Excluir recompensa</h3>
            <p class="text-sm text-slate-500 text-center mb-5">
              Tem certeza que deseja excluir
              <strong class="text-slate-700">"{{ deleteTarget.name }}"</strong>?
              Esta ação não pode ser desfeita.
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
import RewardsTable from '../components/rewards/RewardsTable.vue'
import RewardModal  from '../components/rewards/RewardModal.vue'

const allRewards  = ref([])
const loading     = ref(true)
const error       = ref('')
const search      = ref('')
const statusFilter   = ref('all')
const categoryFilter = ref('all')
const modalOpen   = ref(false)
const rewardToEdit = ref(null)
const deleteTarget = ref(null)
const deleting    = ref(false)
const deleteError = ref('')
const togglingId  = ref(null)

// ── Computed ───────────────────────────────────────────────────────

const activeCount     = computed(() => allRewards.value.filter((r) => r.active).length)
const totalPending    = computed(() => allRewards.value.reduce((s, r) => s + (r.pending_count ?? 0), 0))
const outOfStockCount = computed(() => allRewards.value.filter((r) => r.stock !== null && r.stock === 0).length)

const statusFilters = computed(() => [
  { value: 'all',      label: 'Todas',    count: allRewards.value.length },
  { value: 'active',   label: 'Ativas',   count: activeCount.value },
  { value: 'inactive', label: 'Inativas', count: allRewards.value.length - activeCount.value },
])

const categoryFilters = [
  { value: 'all',      label: 'Todos tipos' },
  { value: 'physical', label: '📦 Produto'  },
  { value: 'service',  label: '🎯 Serviço'  },
  { value: 'discount', label: '🏷️ Desconto' },
]

const displayed = computed(() => {
  let list = allRewards.value

  if (statusFilter.value === 'active')   list = list.filter((r) => r.active)
  if (statusFilter.value === 'inactive') list = list.filter((r) => !r.active)
  if (categoryFilter.value !== 'all')    list = list.filter((r) => r.category === categoryFilter.value)

  const q = search.value.trim().toLowerCase()
  if (q) list = list.filter((r) =>
    r.name.toLowerCase().includes(q) ||
    (r.description ?? '').toLowerCase().includes(q)
  )

  return list
})

// ── Data ──────────────────────────────────────────────────────────

async function loadRewards() {
  loading.value = true
  error.value   = ''
  try {
    const { data } = await api.get('/admin/rewards')
    allRewards.value = data.rewards ?? []
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar as recompensas.'
  } finally {
    loading.value = false
  }
}

// ── CRUD ──────────────────────────────────────────────────────────

function openCreate() { rewardToEdit.value = null; modalOpen.value = true }
function openEdit(r)  { rewardToEdit.value = r;    modalOpen.value = true }
function onSaved()    { loadRewards() }

function askDelete(r)   { deleteError.value = ''; deleteTarget.value = r }
function cancelDelete() { if (!deleting.value) deleteTarget.value = null }

async function confirmDelete() {
  if (!deleteTarget.value) return
  deleting.value = true; deleteError.value = ''
  try {
    await api.delete(`/admin/rewards/${deleteTarget.value.id}`)
    allRewards.value = allRewards.value.filter((r) => r.id !== deleteTarget.value.id)
    deleteTarget.value = null
  } catch (e) {
    deleteError.value = e.response?.data?.message ?? 'Erro ao excluir recompensa.'
  } finally {
    deleting.value = false
  }
}

async function handleToggle(reward) {
  togglingId.value = reward.id
  try {
    const { data } = await api.patch(`/admin/rewards/${reward.id}/toggle`)
    const found = allRewards.value.find((r) => r.id === reward.id)
    if (found) found.active = data.active
  } catch {
    // silencioso
  } finally {
    togglingId.value = null
  }
}

onMounted(loadRewards)
</script>
