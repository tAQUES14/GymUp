<template>
  <div>

    <!-- Page header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Ranking</h1>
        <p class="text-slate-500 text-sm mt-1">Pontuação dos alunos da academia.</p>
      </div>
      <!-- Period selector -->
      <div class="flex flex-wrap items-center gap-2">
        <div class="flex items-center gap-1.5 bg-slate-100 p-1 rounded-lg flex-shrink-0">
          <button v-for="type in rankTypes" :key="type.value"
            @click="selectRankType(type.value)"
            class="px-3 py-1.5 text-xs font-semibold rounded-md transition-all"
            :class="rankBy === type.value
              ? 'bg-white text-slate-900 shadow-sm'
              : 'text-slate-500 hover:text-slate-700'"
          >
            {{ type.label }}
          </button>
        </div>
        <div class="flex items-center gap-1.5 bg-slate-100 p-1 rounded-lg flex-shrink-0">
          <button v-for="p in periods" :key="p.value"
            @click="selectPeriod(p.value)"
            class="px-3 py-1.5 text-xs font-semibold rounded-md transition-all"
            :class="period === p.value
              ? 'bg-white text-slate-900 shadow-sm'
              : 'text-slate-500 hover:text-slate-700'"
          >
            {{ p.label }}
          </button>
        </div>
      </div>
    </div>

    <!-- Error -->
    <div v-if="error" class="card p-8 text-center mb-6">
      <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mb-3">
        <svg class="w-6 h-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar ranking</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else>

      <!-- Stats strip -->
      <div class="grid grid-cols-3 gap-4 mb-7">
        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Total de alunos</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-10 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ stats.total_users }}</template>
            </p>
          </div>
        </div>

        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Ativos no período</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-10 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ stats.active_count }}</template>
            </p>
          </div>
        </div>

        <div class="card px-4 py-3.5 flex items-center gap-3">
          <div class="w-8 h-8 rounded-lg bg-amber-50 flex items-center justify-center flex-shrink-0">
            <svg class="w-4 h-4 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
            </svg>
          </div>
          <div>
            <p class="text-xs text-slate-500">Pontos distribuídos</p>
            <p class="text-lg font-bold text-slate-900 leading-tight">
              <span v-if="loading" class="inline-block w-12 h-4 bg-slate-100 rounded animate-pulse" />
              <template v-else>{{ formatPts(stats.total_points) }}</template>
            </p>
          </div>
        </div>
      </div>

      <!-- TOP 3 PODIUM ──────────────────────────────── -->
      <div v-if="!loading && top3.length >= 2" class="mb-7">
        <div class="flex items-end justify-center gap-3">

          <!-- 2nd place -->
          <div class="flex flex-col items-center gap-2 flex-1 max-w-[160px]">
            <div class="relative">
              <div class="w-14 h-14 rounded-full flex items-center justify-center text-lg font-bold text-white flex-shrink-0 ring-4 ring-white shadow-lg"
                   :style="{ backgroundColor: avatarColor(top3[1]?.name) }">
                {{ initials(top3[1]?.name) }}
              </div>
              <span class="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-6 h-6 rounded-full bg-slate-400 border-2 border-white
                           flex items-center justify-center text-[10px] font-black text-white shadow">2</span>
            </div>
            <div class="text-center">
              <p class="text-xs font-bold text-slate-800 truncate max-w-[140px]">{{ firstName(top3[1]?.name) }}</p>
              <p class="text-sm font-black text-slate-900">{{ metricValue(top3[1]) }}</p>
              <p class="text-[10px] text-slate-400">{{ metricUnit(top3[1]) }}</p>
            </div>
            <div class="w-full bg-slate-300 rounded-t-lg flex items-center justify-center py-4 min-h-[60px]">
              <span class="text-4xl font-black text-white/30">2</span>
            </div>
          </div>

          <!-- 1st place -->
          <div class="flex flex-col items-center gap-2 flex-1 max-w-[180px]">
            <div class="text-2xl mb-1">🏆</div>
            <div class="relative">
              <div class="w-16 h-16 rounded-full flex items-center justify-center text-xl font-bold text-white flex-shrink-0 ring-4 ring-yellow-300 shadow-xl"
                   :style="{ backgroundColor: avatarColor(top3[0]?.name) }">
                {{ initials(top3[0]?.name) }}
              </div>
              <span class="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-7 h-7 rounded-full bg-yellow-400 border-2 border-white
                           flex items-center justify-center text-[11px] font-black text-white shadow-lg">1</span>
            </div>
            <div class="text-center">
              <p class="text-sm font-bold text-slate-800 truncate max-w-[160px]">{{ firstName(top3[0]?.name) }}</p>
              <p class="text-xl font-black text-yellow-600">{{ metricValue(top3[0]) }}</p>
              <p class="text-[10px] text-slate-400">{{ metricUnit(top3[0]) }}</p>
            </div>
            <div class="w-full bg-yellow-400 rounded-t-lg flex items-center justify-center py-6 min-h-[90px] shadow-md shadow-yellow-200">
              <span class="text-5xl font-black text-white/30">1</span>
            </div>
          </div>

          <!-- 3rd place -->
          <div v-if="top3.length >= 3" class="flex flex-col items-center gap-2 flex-1 max-w-[160px]">
            <div class="relative">
              <div class="w-14 h-14 rounded-full flex items-center justify-center text-lg font-bold text-white flex-shrink-0 ring-4 ring-white shadow-lg"
                   :style="{ backgroundColor: avatarColor(top3[2]?.name) }">
                {{ initials(top3[2]?.name) }}
              </div>
              <span class="absolute -bottom-1.5 left-1/2 -translate-x-1/2 w-6 h-6 rounded-full bg-amber-600 border-2 border-white
                           flex items-center justify-center text-[10px] font-black text-white shadow">3</span>
            </div>
            <div class="text-center">
              <p class="text-xs font-bold text-slate-800 truncate max-w-[140px]">{{ firstName(top3[2]?.name) }}</p>
              <p class="text-sm font-black text-slate-900">{{ metricValue(top3[2]) }}</p>
              <p class="text-[10px] text-slate-400">{{ metricUnit(top3[2]) }}</p>
            </div>
            <div class="w-full bg-amber-600/70 rounded-t-lg flex items-center justify-center py-3 min-h-[44px]">
              <span class="text-3xl font-black text-white/30">3</span>
            </div>
          </div>

        </div>
      </div>

      <!-- Podium skeleton -->
      <div v-if="loading" class="flex items-end justify-center gap-3 mb-7 animate-pulse">
        <div class="flex-1 max-w-[160px]">
          <div class="w-14 h-14 rounded-full bg-slate-100 mx-auto mb-2" />
          <div class="h-[60px] bg-slate-100 rounded-t-lg" />
        </div>
        <div class="flex-1 max-w-[180px]">
          <div class="w-16 h-16 rounded-full bg-slate-100 mx-auto mb-2" />
          <div class="h-[90px] bg-slate-100 rounded-t-lg" />
        </div>
        <div class="flex-1 max-w-[160px]">
          <div class="w-14 h-14 rounded-full bg-slate-100 mx-auto mb-2" />
          <div class="h-[44px] bg-slate-100 rounded-t-lg" />
        </div>
      </div>

      <!-- Search -->
      <div class="flex items-center gap-3 mb-4">
        <div class="relative flex-1 max-w-sm">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"
            fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input v-model="search" type="text" placeholder="Buscar aluno…"
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
          {{ filteredRanking.length }} resultado{{ filteredRanking.length !== 1 ? 's' : '' }}
        </span>
        <span class="ml-auto text-xs text-slate-400 flex-shrink-0">
          {{ periodLabel }} · {{ ranking.length }} aluno{{ ranking.length !== 1 ? 's' : '' }}
        </span>
      </div>

      <!-- Table -->
      <div class="card overflow-hidden">
        <table class="w-full text-left">
          <thead>
            <tr class="border-b border-slate-100 bg-slate-50/60">
              <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide w-12 text-center">#</th>
              <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Aluno</th>
              <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right">
                Pts no período
              </th>
              <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right hidden sm:table-cell">
                Saldo total
              </th>
              <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-center hidden md:table-cell">
                Streak
              </th>
              <th class="px-4 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right hidden md:table-cell">
                Treinos
              </th>
            </tr>
          </thead>
          <tbody>

            <!-- Loading -->
            <template v-if="loading">
              <tr v-for="i in 8" :key="i" class="border-b border-slate-100">
                <td class="px-4 py-3.5 text-center">
                  <div class="w-7 h-7 rounded-full bg-slate-100 animate-pulse mx-auto" />
                </td>
                <td class="px-4 py-3.5">
                  <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-full bg-slate-100 animate-pulse flex-shrink-0" />
                    <div class="space-y-1.5">
                      <div class="h-3.5 w-32 bg-slate-100 rounded animate-pulse" />
                      <div class="h-2.5 w-24 bg-slate-100 rounded animate-pulse" />
                    </div>
                  </div>
                </td>
                <td v-for="j in 4" :key="j" class="px-4 py-3.5">
                  <div class="h-3.5 bg-slate-100 rounded animate-pulse w-12 ml-auto" />
                </td>
              </tr>
            </template>

            <!-- Empty -->
            <tr v-else-if="filteredRanking.length === 0">
              <td colspan="6" class="px-4 py-16 text-center">
                <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
                  <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
                  </svg>
                </div>
                <p class="text-sm font-semibold text-slate-600 mb-1">
                  {{ search ? 'Nenhum aluno encontrado' : 'Nenhum aluno no ranking' }}
                </p>
                <p class="text-xs text-slate-400">
                  {{ search ? `Nenhum resultado para "${search}"` : 'Nenhuma pontuação registrada neste período.' }}
                </p>
              </td>
            </tr>

            <!-- Rows -->
            <tr v-for="entry in filteredRanking" :key="entry.user_id"
              class="border-b border-slate-100 hover:bg-slate-50/60 transition-colors"
              :class="{ 'bg-yellow-50/40': entry.position === 1 && !search }">

              <!-- Position badge -->
              <td class="px-4 py-3.5 text-center">
                <span class="inline-flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold"
                      :class="posClass(entry.position)">
                  <template v-if="entry.position <= 3 && !search">
                    {{ entry.position === 1 ? '🥇' : entry.position === 2 ? '🥈' : '🥉' }}
                  </template>
                  <template v-else>{{ entry.position }}</template>
                </span>
              </td>

              <!-- Aluno -->
              <td class="px-4 py-3.5">
                <div class="flex items-center gap-3">
                  <div class="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0 shadow-sm"
                       :style="{ backgroundColor: avatarColor(entry.name) }">
                    {{ initials(entry.name) }}
                  </div>
                  <div class="min-w-0">
                    <p class="text-sm font-semibold text-slate-800 truncate leading-tight">{{ entry.name }}</p>
                    <p class="text-[11px] text-slate-400 truncate">{{ entry.email }}</p>
                  </div>
                </div>
              </td>

              <!-- Pontos no período -->
              <td class="px-4 py-3.5 text-right">
                <div class="inline-flex flex-col items-end">
                  <span class="text-sm font-black leading-tight"
                        :class="metricNumber(entry) > 0 ? 'text-brand-700' : 'text-slate-300'">
                    {{ metricValue(entry) }}
                  </span>
                  <span class="text-[10px] text-slate-400">{{ metricUnit(entry) }}</span>
                </div>
              </td>

              <!-- Saldo total -->
              <td class="px-4 py-3.5 text-right hidden sm:table-cell">
                <span class="text-sm font-semibold text-slate-600">{{ formatPts(entry.points_balance) }}</span>
                <span class="text-[10px] text-slate-400 ml-0.5">pts</span>
              </td>

              <!-- Streak -->
              <td class="px-4 py-3.5 text-center hidden md:table-cell">
                <div v-if="entry.weekly_streak > 0"
                  class="inline-flex items-center gap-1 px-2 py-1 bg-orange-50 rounded-lg">
                  <span class="text-sm">🔥</span>
                  <span class="text-xs font-bold text-orange-600">{{ entry.weekly_streak }}</span>
                </div>
                <span v-else class="text-slate-300 text-sm">—</span>
              </td>

              <!-- Treinos -->
              <td class="px-4 py-3.5 text-right hidden md:table-cell">
                <span class="text-sm font-semibold text-slate-600">{{ entry.workouts_count }}</span>
                <span class="text-[10px] text-slate-400 ml-0.5">treinos</span>
              </td>

            </tr>
          </tbody>
        </table>
      </div>

    </template>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '../services/api.js'

const periods = [
  { value: 'weekly',    label: 'Semana' },
  { value: 'monthly',   label: 'Mês' },
  { value: 'quarterly', label: 'Trimestre' },
  { value: 'all',       label: 'Geral' },
]

const rankTypes = [
  { value: 'points', label: 'Pontos' },
  { value: 'streak', label: 'Streak' },
]

const ranking = ref([])
const stats   = ref({ total_users: 0, active_count: 0, total_points: 0 })
const period  = ref('all')
const rankBy  = ref('points')
const search  = ref('')
const loading = ref(true)
const error   = ref('')

const periodLabel = computed(() => periods.find((p) => p.value === period.value)?.label ?? '')

const top3 = computed(() => ranking.value.slice(0, 3))

const filteredRanking = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return ranking.value
  return ranking.value.filter((r) => r.name.toLowerCase().includes(q) || r.email.toLowerCase().includes(q))
})

async function load() {
  loading.value = true; error.value = ''
  try {
    const { data } = await api.get(`/admin/ranking?period=${period.value}&rank_by=${rankBy.value}&limit=100`)
    ranking.value = data.ranking ?? []
    stats.value   = {
      total_users:  data.total_users  ?? 0,
      active_count: data.active_count ?? 0,
      total_points: data.total_points ?? 0,
    }
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar o ranking.'
  } finally { loading.value = false }
}

function selectPeriod(p) {
  period.value = p
  load()
}

// ── Helpers ──────────────────────────────────────────────────────
function selectRankType(type) {
  rankBy.value = type
  load()
}

function metricNumber(entry) {
  if (!entry) return 0
  return rankBy.value === 'streak' ? (entry.current_streak ?? entry.weekly_streak ?? 0) : (entry.period_points ?? 0)
}

function metricValue(entry) {
  return formatPts(metricNumber(entry))
}

function metricUnit(entry) {
  if (rankBy.value !== 'streak') return 'pts'
  return metricNumber(entry) === 1 ? 'dia' : 'dias'
}

function formatPts(n) {
  if (n === undefined || n === null) return '0'
  if (n >= 1000) return (n / 1000).toFixed(1).replace('.0', '') + 'k'
  return String(n)
}

function posClass(pos) {
  if (pos === 1) return 'bg-yellow-100 text-yellow-700'
  if (pos === 2) return 'bg-slate-200 text-slate-600'
  if (pos === 3) return 'bg-amber-100 text-amber-700'
  return 'bg-slate-100 text-slate-500'
}

function initials(name) {
  return (name ?? '?').split(' ').slice(0, 2).map((w) => w[0]).join('').toUpperCase()
}

function firstName(name) {
  return (name ?? '').split(' ')[0]
}

function avatarColor(name) {
  const colors = ['#6366f1', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#3b82f6', '#ef4444', '#14b8a6', '#f97316', '#06b6d4']
  let h = 0
  for (const c of (name ?? '')) h = (h * 31 + c.charCodeAt(0)) & 0xffffffff
  return colors[Math.abs(h) % colors.length]
}

onMounted(load)
</script>
