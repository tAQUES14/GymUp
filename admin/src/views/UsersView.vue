<template>
  <div>

    <!-- Page header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <div class="flex items-center gap-3">
          <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Alunos</h1>
          <span
            v-if="!loading && !error"
            class="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs
                   font-semibold bg-brand-50 text-brand-700 border border-brand-100"
          >
            {{ allUsers.length }}
          </span>
        </div>
        <p class="text-slate-500 text-sm mt-1">
          Gerencie os alunos cadastrados na sua academia.
        </p>
      </div>
    </div>

    <!-- Error state -->
    <div v-if="error" class="card p-8 text-center mb-6">
      <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mb-3">
        <svg class="w-6 h-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar alunos</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadUsers" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else>

      <!-- Stats strip -->
      <div class="grid grid-cols-3 gap-4 mb-6">
        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Total</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ allUsers.length }}</template>
            </p>
          </div>
        </div>

        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center flex-shrink-0">
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-500" />
          </div>
          <div>
            <p class="text-xs text-slate-500">Ativos</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ activeCount }}</template>
            </p>
          </div>
        </div>

        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0">
            <span class="w-2.5 h-2.5 rounded-full bg-slate-400" />
          </div>
          <div>
            <p class="text-xs text-slate-500">Inativos</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-8 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ inactiveCount }}</template>
            </p>
          </div>
        </div>
      </div>

      <!-- Search + Table -->
      <div class="space-y-4">

        <!-- Search bar -->
        <div class="flex items-center gap-3">
          <div class="relative flex-1 max-w-sm">
            <svg
              class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"
              fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"
            >
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
            <input
              v-model="search"
              type="text"
              placeholder="Buscar aluno por nome ou email…"
              class="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg bg-white
                     focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent
                     placeholder-slate-400 transition"
            />
            <!-- Clear button -->
            <button
              v-if="search"
              @click="search = ''"
              class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
            >
              <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Result count chip when searching -->
          <span v-if="search" class="text-xs text-slate-500">
            {{ filteredUsers.length }}
            {{ filteredUsers.length === 1 ? 'resultado' : 'resultados' }}
          </span>
        </div>

        <!-- Table -->
        <UsersTable
          :users="filteredUsers"
          :loading="loading"
          :search="search"
          @view="goToUser"
        />

      </div>

    </template>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '../services/api.js'
import UsersTable from '../components/users/UsersTable.vue'

const router   = useRouter()
const allUsers = ref([])
const loading  = ref(true)
const error    = ref('')
const search   = ref('')

// ── Computed ──────────────────────────────────────────────────────────────────

const filteredUsers = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return allUsers.value
  return allUsers.value.filter(
    (u) =>
      u.name.toLowerCase().includes(q) ||
      u.email.toLowerCase().includes(q)
  )
})

const activeCount   = computed(() => allUsers.value.filter((u) => u.status === 'active').length)
const inactiveCount = computed(() => allUsers.value.filter((u) => u.status === 'inactive').length)

// ── Data ──────────────────────────────────────────────────────────────────────

async function loadUsers() {
  loading.value = true
  error.value   = ''
  try {
    const { data } = await api.get('/admin/users')
    allUsers.value = data.users ?? []
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar os alunos.'
  } finally {
    loading.value = false
  }
}

function goToUser(id) {
  router.push(`/users/${id}`)
}

onMounted(loadUsers)
</script>
