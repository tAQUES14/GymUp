<template>
  <div>

    <!-- Page header -->
    <div class="mb-8">
      <div class="flex items-center gap-3">
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Resgates</h1>
        <span
          v-if="!loading && totalPending > 0"
          class="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs
                 font-semibold bg-amber-50 text-amber-700 border border-amber-100"
        >
          {{ totalPending }} pendente{{ totalPending !== 1 ? 's' : '' }}
        </span>
      </div>
      <p class="text-slate-500 text-sm mt-1">Aprove ou rejeite as solicitações de resgate dos alunos.</p>
    </div>

    <!-- Filters -->
    <div class="flex flex-col sm:flex-row gap-3 mb-6">

      <!-- Status tabs -->
      <div class="flex flex-wrap gap-2">
        <button
          v-for="tab in tabs"
          :key="tab.value"
          @click="setStatus(tab.value)"
          class="px-4 py-1.5 rounded-full text-sm font-medium transition-colors border"
          :class="activeStatus === tab.value
            ? 'bg-brand-600 text-white border-brand-600'
            : 'bg-white text-slate-600 border-slate-200 hover:border-slate-300'"
        >
          {{ tab.label }}
        </button>
      </div>

      <!-- Search inputs -->
      <div class="flex gap-2 sm:ml-auto">
        <input
          v-model="userSearch"
          @input="debouncedLoad"
          type="text"
          placeholder="Buscar aluno..."
          class="px-3 py-1.5 text-sm border border-slate-200 rounded-lg focus:outline-none
                 focus:ring-2 focus:ring-brand-500 focus:border-transparent w-40"
        />
        <input
          v-model="rewardSearch"
          @input="debouncedLoad"
          type="text"
          placeholder="Buscar recompensa..."
          class="px-3 py-1.5 text-sm border border-slate-200 rounded-lg focus:outline-none
                 focus:ring-2 focus:ring-brand-500 focus:border-transparent w-44"
        />
        <button
          v-if="userSearch || rewardSearch"
          @click="clearSearch"
          class="px-3 py-1.5 text-xs text-slate-500 border border-slate-200 rounded-lg hover:bg-slate-50"
        >
          Limpar
        </button>
      </div>
    </div>

    <!-- Error state -->
    <div v-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar resgates</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadRedemptions" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Table -->
    <div v-else class="card overflow-hidden">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-100">
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wide">Aluno</th>
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wide">Recompensa</th>
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wide">Pontos</th>
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wide">Data</th>
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wide">Status</th>
            <th class="px-5 py-3.5" />
          </tr>
        </thead>
        <tbody>
          <!-- Loading skeleton -->
          <template v-if="loading">
            <tr v-for="n in 5" :key="n" class="border-b border-slate-50">
              <td class="px-5 py-4"><div class="h-4 bg-slate-100 rounded w-32 animate-pulse" /></td>
              <td class="px-5 py-4"><div class="h-4 bg-slate-100 rounded w-28 animate-pulse" /></td>
              <td class="px-5 py-4"><div class="h-4 bg-slate-100 rounded w-14 animate-pulse" /></td>
              <td class="px-5 py-4"><div class="h-4 bg-slate-100 rounded w-20 animate-pulse" /></td>
              <td class="px-5 py-4"><div class="h-5 bg-slate-100 rounded-full w-20 animate-pulse" /></td>
              <td class="px-5 py-4" />
            </tr>
          </template>

          <!-- Empty state -->
          <tr v-else-if="!redemptions.length">
            <td colspan="6" class="px-5 py-12 text-center text-slate-400 text-sm">
              Nenhum resgate {{ activeStatus !== 'all' ? statusLabel(activeStatus) : '' }} encontrado.
            </td>
          </tr>

          <!-- Data rows -->
          <tr
            v-else
            v-for="r in redemptions"
            :key="r.id"
            class="border-b border-slate-50 hover:bg-slate-50/50 transition-colors"
          >
            <td class="px-5 py-4">
              <p class="font-medium text-slate-800">{{ r.user?.name ?? '—' }}</p>
              <p class="text-xs text-slate-400">{{ r.user?.email }}</p>
            </td>
            <td class="px-5 py-4 text-slate-700">{{ r.reward?.name ?? '—' }}</td>
            <td class="px-5 py-4">
              <span class="font-semibold text-brand-600">{{ r.points_spent.toLocaleString('pt-BR') }}</span>
              <span class="text-slate-400 text-xs ml-0.5">pts</span>
            </td>
            <td class="px-5 py-4 text-slate-500 text-xs whitespace-nowrap">{{ formatDate(r.created_at) }}</td>
            <td class="px-5 py-4">
              <StatusBadge :status="r.status" />
            </td>
            <td class="px-5 py-4">
              <div v-if="r.status === 'pending'" class="flex items-center gap-2 justify-end">
                <button
                  @click="approve(r)"
                  :disabled="processingId === r.id"
                  class="px-3 py-1.5 bg-emerald-600 text-white text-xs font-semibold rounded-lg
                         hover:bg-emerald-700 transition-colors disabled:opacity-50"
                >
                  Aprovar
                </button>
                <button
                  @click="openReject(r)"
                  :disabled="processingId === r.id"
                  class="px-3 py-1.5 bg-white text-red-600 text-xs font-semibold rounded-lg border
                         border-red-200 hover:bg-red-50 transition-colors disabled:opacity-50"
                >
                  Rejeitar
                </button>
              </div>
              <p v-else-if="r.status === 'rejected' && r.rejection_reason"
                 class="text-xs text-slate-400 max-w-[160px] truncate" :title="r.rejection_reason">
                {{ r.rejection_reason }}
              </p>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div v-if="!loading && meta && meta.last_page > 1" class="flex items-center justify-between px-5 py-3.5 border-t border-slate-100">
        <p class="text-xs text-slate-500">
          {{ meta.from }}–{{ meta.to }} de {{ meta.total }} resgates
        </p>
        <div class="flex gap-1.5">
          <button
            @click="loadPage(meta.current_page - 1)"
            :disabled="meta.current_page <= 1"
            class="px-3 py-1.5 text-xs rounded-lg border border-slate-200 text-slate-600
                   hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed"
          >Anterior</button>
          <button
            @click="loadPage(meta.current_page + 1)"
            :disabled="meta.current_page >= meta.last_page"
            class="px-3 py-1.5 text-xs rounded-lg border border-slate-200 text-slate-600
                   hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed"
          >Próxima</button>
        </div>
      </div>
    </div>

    <!-- Reject modal -->
    <Transition name="fade">
      <div v-if="rejectTarget" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-sm p-6">
          <h3 class="text-base font-bold text-slate-900 mb-1">Rejeitar resgate</h3>
          <p class="text-sm text-slate-500 mb-4">
            {{ rejectTarget.reward?.name }} — {{ rejectTarget.user?.name }}
          </p>
          <label class="block text-xs font-semibold text-slate-600 mb-1.5">Motivo <span class="font-normal text-slate-400">(opcional)</span></label>
          <input
            v-model="rejectReason"
            type="text"
            maxlength="255"
            placeholder="Ex: item indisponível no momento"
            class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none
                   focus:ring-2 focus:ring-brand-500 focus:border-transparent mb-5"
            @keydown.enter="confirmReject"
          />
          <div class="flex gap-3">
            <button @click="rejectTarget = null; rejectReason = ''"
              class="flex-1 px-4 py-2 text-sm font-medium text-slate-600 border border-slate-200
                     rounded-lg hover:bg-slate-50 transition-colors">
              Cancelar
            </button>
            <button @click="confirmReject" :disabled="processingId !== null"
              class="flex-1 px-4 py-2 text-sm font-semibold text-white bg-red-600 rounded-lg
                     hover:bg-red-700 transition-colors disabled:opacity-50">
              Confirmar rejeição
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Toast -->
    <Transition name="fade">
      <div
        v-if="toast"
        class="fixed bottom-5 right-5 z-50 flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg text-sm font-medium"
        :class="toast.type === 'success' ? 'bg-emerald-600 text-white' : 'bg-red-600 text-white'"
      >
        {{ toast.message }}
      </div>
    </Transition>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '../services/api.js'

// ── Sub-component inline ──────────────────────────────────────────────────────
const StatusBadge = {
  props: ['status'],
  template: `
    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold"
      :class="{
        'bg-amber-50 text-amber-700 border border-amber-100': status === 'pending',
        'bg-emerald-50 text-emerald-700 border border-emerald-100': status === 'approved',
        'bg-red-50 text-red-600 border border-red-100': status === 'rejected',
      }"
    >
      {{ { pending: 'Pendente', approved: 'Aprovado', rejected: 'Rejeitado' }[status] ?? status }}
    </span>
  `,
}

const route  = useRoute()
const router = useRouter()

const redemptions  = ref([])
const meta         = ref(null)
const loading      = ref(true)
const error        = ref('')
const processingId = ref(null)
const toast        = ref(null)
const rejectTarget = ref(null)
const rejectReason = ref('')
const userSearch   = ref('')
const rewardSearch = ref('')

// Debounce: wait 400ms after the user stops typing before fetching
let searchTimer = null
function debouncedLoad() {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => loadRedemptions(), 400)
}

function clearSearch() {
  userSearch.value   = ''
  rewardSearch.value = ''
  loadRedemptions()
}

const activeStatus = ref(route.query.status ?? 'pending')

const tabs = [
  { label: 'Pendentes',  value: 'pending'  },
  { label: 'Aprovados',  value: 'approved' },
  { label: 'Rejeitados', value: 'rejected' },
  { label: 'Todos',      value: 'all'      },
]

const totalPending = computed(() => {
  if (activeStatus.value === 'pending') return meta.value?.total ?? 0
  return 0
})

function statusLabel(s) {
  return { pending: 'pendente', approved: 'aprovado', rejected: 'rejeitado' }[s] ?? ''
}

function formatDate(iso) {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('pt-BR', {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

async function loadRedemptions(page = 1) {
  loading.value = true
  error.value   = ''
  try {
    const params = { per_page: 20, page }
    if (activeStatus.value !== 'all') params.status = activeStatus.value
    if (userSearch.value.trim())   params.user   = userSearch.value.trim()
    if (rewardSearch.value.trim()) params.reward = rewardSearch.value.trim()
    const { data } = await api.get('/admin/redemptions', { params })
    redemptions.value = data.data
    meta.value        = data.meta
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar os resgates.'
  } finally {
    loading.value = false
  }
}

function loadPage(page) {
  loadRedemptions(page)
}

function setStatus(value) {
  activeStatus.value = value
  router.replace({ query: value !== 'pending' ? { status: value } : {} })
}

async function approve(redemption) {
  if (!confirm(`Aprovar resgate de "${redemption.reward?.name}" para ${redemption.user?.name}?`)) return
  processingId.value = redemption.id
  try {
    await api.post(`/admin/redemptions/${redemption.id}/approve`)
    showToast('Resgate aprovado com sucesso.', 'success')
    loadRedemptions()
  } catch (e) {
    showToast(e.response?.data?.message ?? 'Erro ao aprovar resgate.', 'error')
  } finally {
    processingId.value = null
  }
}

function openReject(redemption) {
  rejectTarget.value = redemption
  rejectReason.value = ''
}

async function confirmReject() {
  const redemption = rejectTarget.value
  if (!redemption) return
  processingId.value = redemption.id
  try {
    await api.post(`/admin/redemptions/${redemption.id}/reject`, {
      reason: rejectReason.value || null,
    })
    rejectTarget.value = null
    rejectReason.value = ''
    showToast('Resgate rejeitado. Pontos devolvidos ao aluno.', 'success')
    loadRedemptions()
  } catch (e) {
    showToast(e.response?.data?.message ?? 'Erro ao rejeitar resgate.', 'error')
  } finally {
    processingId.value = null
  }
}

function showToast(message, type = 'success') {
  toast.value = { message, type }
  setTimeout(() => { toast.value = null }, 3000)
}

watch(activeStatus, () => loadRedemptions())

onMounted(() => loadRedemptions())
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active { transition: opacity 0.25s, transform 0.25s; }
.fade-enter-from,
.fade-leave-to    { opacity: 0; transform: translateY(8px); }
</style>
