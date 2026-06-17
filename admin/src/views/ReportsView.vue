<template>
  <div>

    <!-- Page header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Relatórios</h1>
        <p class="text-slate-500 text-sm mt-1">Análises de desempenho e engajamento da academia.</p>
      </div>

      <!-- Period selector -->
      <div class="flex items-center gap-1 bg-slate-100 rounded-lg p-1 self-start sm:self-auto">
        <button
          v-for="p in periods"
          :key="p.value"
          @click="selectPeriod(p.value)"
          :class="[
            'px-3 py-1.5 text-xs font-semibold rounded-md transition-all',
            period === p.value
              ? 'bg-white text-slate-900 shadow-sm'
              : 'text-slate-500 hover:text-slate-700'
          ]"
        >
          {{ p.label }}
        </button>
      </div>
    </div>

    <!-- Loading skeleton -->
    <template v-if="loading">
      <div class="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
        <div v-for="n in 6" :key="n" class="card px-4 py-3.5 animate-pulse">
          <div class="h-3 bg-slate-100 rounded w-20 mb-2" />
          <div class="h-6 bg-slate-100 rounded w-12" />
        </div>
      </div>
      <div class="grid grid-cols-1 xl:grid-cols-2 gap-5 mb-5">
        <div class="card p-6 animate-pulse h-64" />
        <div class="card p-6 animate-pulse h-64" />
      </div>
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-5">
        <div v-for="n in 3" :key="n" class="card p-6 animate-pulse h-52" />
      </div>
    </template>

    <!-- Error state -->
    <div v-else-if="error" class="card p-8 text-center">
      <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mb-3">
        <svg class="w-6 h-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar relatórios</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadData" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Content -->
    <template v-else-if="data">

      <!-- KPI strip -->
      <div class="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">

        <div class="card px-4 py-3.5 flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <div class="w-7 h-7 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-3.5 h-3.5 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
              </svg>
            </div>
            <span class="text-xs text-slate-500 font-medium leading-tight">Treinos</span>
          </div>
          <p class="text-xl font-bold text-slate-900 tracking-tight pl-0.5">{{ data.kpis.total_workouts.toLocaleString('pt-BR') }}</p>
        </div>

        <div class="card px-4 py-3.5 flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <div class="w-7 h-7 rounded-lg bg-emerald-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-3.5 h-3.5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
              </svg>
            </div>
            <span class="text-xs text-slate-500 font-medium leading-tight">Alunos ativos</span>
          </div>
          <p class="text-xl font-bold text-slate-900 tracking-tight pl-0.5">{{ data.kpis.active_users }}</p>
        </div>

        <div class="card px-4 py-3.5 flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <div class="w-7 h-7 rounded-lg bg-sky-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-3.5 h-3.5 text-sky-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5" />
              </svg>
            </div>
            <span class="text-xs text-slate-500 font-medium leading-tight">Check-ins</span>
          </div>
          <p class="text-xl font-bold text-slate-900 tracking-tight pl-0.5">{{ data.kpis.total_checkins.toLocaleString('pt-BR') }}</p>
        </div>

        <div class="card px-4 py-3.5 flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <div class="w-7 h-7 rounded-lg bg-amber-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-3.5 h-3.5 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
              </svg>
            </div>
            <span class="text-xs text-slate-500 font-medium leading-tight">Pts ganhos</span>
          </div>
          <p class="text-xl font-bold text-slate-900 tracking-tight pl-0.5">{{ fmtPts(data.kpis.points_earned) }}</p>
        </div>

        <div class="card px-4 py-3.5 flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <div class="w-7 h-7 rounded-lg bg-violet-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-3.5 h-3.5 text-violet-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z" />
              </svg>
            </div>
            <span class="text-xs text-slate-500 font-medium leading-tight">Pts gastos</span>
          </div>
          <p class="text-xl font-bold text-slate-900 tracking-tight pl-0.5">{{ fmtPts(data.kpis.points_spent) }}</p>
        </div>

        <div class="card px-4 py-3.5 flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <div class="w-7 h-7 rounded-lg bg-rose-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-3.5 h-3.5 text-rose-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 11.25v8.25a1.5 1.5 0 01-1.5 1.5H5.25a1.5 1.5 0 01-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 109.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1114.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
              </svg>
            </div>
            <span class="text-xs text-slate-500 font-medium leading-tight">Resgates</span>
          </div>
          <p class="text-xl font-bold text-slate-900 tracking-tight pl-0.5">{{ data.kpis.redemptions }}</p>
        </div>

      </div>

      <!-- Charts row -->
      <div class="grid grid-cols-1 xl:grid-cols-2 gap-5 mb-5">

        <!-- Workouts trend -->
        <div class="card p-6">
          <div class="flex items-center justify-between mb-5">
            <div>
              <h2 class="text-sm font-semibold text-slate-900">Treinos por dia</h2>
              <p class="text-xs text-slate-400 mt-0.5">Evolução nos últimos {{ period }} dias</p>
            </div>
            <span class="text-xs font-medium text-brand-600 bg-brand-50 px-2.5 py-1 rounded-full">
              {{ data.kpis.total_workouts.toLocaleString('pt-BR') }} total
            </span>
          </div>
          <div class="relative h-56 pt-4">
            <div class="absolute inset-x-0 top-4 bottom-8 flex flex-col justify-between">
              <div v-for="line in 4" :key="line" class="border-t border-slate-100" />
            </div>

            <svg class="relative z-10 h-48 w-full overflow-visible" viewBox="0 0 100 100" preserveAspectRatio="none">
              <defs>
                <linearGradient id="workoutLineFill" x1="0" x2="0" y1="0" y2="1">
                  <stop offset="0%" stop-color="#2F6FED" stop-opacity="0.20" />
                  <stop offset="100%" stop-color="#2F6FED" stop-opacity="0.02" />
                </linearGradient>
              </defs>
              <path
                v-if="workoutsLine.areaPath"
                :d="workoutsLine.areaPath"
                fill="url(#workoutLineFill)"
              />
              <path
                v-if="workoutsLine.linePath"
                :d="workoutsLine.linePath"
                fill="none"
                stroke="#2F6FED"
                stroke-width="1.8"
                stroke-linecap="round"
                stroke-linejoin="round"
                vector-effect="non-scaling-stroke"
              />
            </svg>

            <div class="absolute inset-x-0 top-4 z-20 h-48">
              <div
                v-for="point in workoutsLine.points"
                :key="point.date"
                class="group absolute h-4 w-4 -translate-x-1/2 -translate-y-1/2"
                :style="{ left: `${point.x}%`, top: `${point.y}%` }"
              >
                <span
                  class="block h-3 w-3 rounded-full border-2 border-white shadow-sm"
                  :class="point.workouts > 0 ? 'bg-brand-600' : 'bg-slate-300'"
                />
                <span
                  class="pointer-events-none absolute bottom-5 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity px-2 py-1 rounded-lg bg-slate-900 text-white text-[11px] font-semibold whitespace-nowrap shadow-lg"
                >
                  {{ point.label }} · {{ point.workouts }} treino{{ point.workouts === 1 ? '' : 's' }}
                </span>
              </div>
            </div>

            <div class="relative z-10 mt-1 flex justify-between">
              <span
                v-for="day in workoutsLine.labels"
                :key="day.date"
                class="text-[10px] font-semibold text-slate-400"
              >
                {{ day.label }}
              </span>
            </div>
          </div>
          <div v-if="!data.workouts_by_day?.some((d) => d.workouts > 0)" class="mt-3 rounded-xl bg-slate-50 px-4 py-3 text-xs text-slate-500">
            Ainda nao ha treinos finalizados neste periodo.
          </div>
        </div>

        <!-- Checkins by weekday -->
        <div class="card p-6">
          <div class="flex items-center justify-between mb-5">
            <div>
              <h2 class="text-sm font-semibold text-slate-900">Check-ins por dia da semana</h2>
              <p class="text-xs text-slate-400 mt-0.5">Distribuição de presença</p>
            </div>
          </div>
          <div class="h-48 flex items-end justify-between gap-3 pt-5">
            <div
              v-for="day in checkinBars"
              :key="day.day"
              class="flex-1 h-full flex flex-col justify-end gap-3 group"
            >
              <div class="relative flex-1 flex items-end justify-center">
                <div
                  class="w-full max-w-12 min-h-[8px] rounded-t-xl bg-gradient-to-t from-emerald-100 to-emerald-500 transition-all group-hover:from-emerald-200 group-hover:to-emerald-600"
                  :style="{ height: `${day.height}%` }"
                />
                <div
                  class="pointer-events-none absolute -top-8 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity px-2 py-1 rounded-lg bg-slate-900 text-white text-[11px] font-semibold whitespace-nowrap shadow-lg"
                >
                  {{ day.checkins }} check-in{{ day.checkins === 1 ? '' : 's' }}
                </div>
              </div>
              <div class="text-center">
                <span class="block text-[11px] font-bold text-slate-600">{{ day.day }}</span>
                <span class="block text-[10px] font-semibold text-slate-400">{{ day.checkins }}</span>
              </div>
            </div>
          </div>
          <div class="mt-3 grid grid-cols-3 gap-2">
            <div class="rounded-xl bg-slate-50 px-3 py-2">
              <p class="text-[10px] font-bold uppercase tracking-wide text-slate-400">Melhor dia</p>
              <p class="text-sm font-bold text-slate-900">{{ bestCheckinDay.day }}</p>
            </div>
            <div class="rounded-xl bg-slate-50 px-3 py-2">
              <p class="text-[10px] font-bold uppercase tracking-wide text-slate-400">Media/dia</p>
              <p class="text-sm font-bold text-slate-900">{{ checkinAverage }}</p>
            </div>
            <div class="rounded-xl bg-slate-50 px-3 py-2">
              <p class="text-[10px] font-bold uppercase tracking-wide text-slate-400">Total</p>
              <p class="text-sm font-bold text-slate-900">{{ data.kpis.total_checkins }}</p>
            </div>
          </div>
        </div>

      </div>

      <!-- Tables row -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-5">

        <!-- Top by workouts -->
        <div class="card p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-sm font-semibold text-slate-900">Top alunos — treinos</h2>
            <span class="text-xs text-slate-400">últimos {{ period }}d</span>
          </div>
          <div class="space-y-3">
            <div
              v-for="(row, idx) in data.top_by_workouts"
              :key="row.id"
              class="flex items-center gap-3"
            >
              <div
                class="w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-bold flex-shrink-0"
                :class="rankClass(idx)"
              >{{ idx + 1 }}</div>
              <p class="flex-1 text-sm font-medium text-slate-800 truncate">{{ row.name }}</p>
              <span class="text-xs font-semibold text-slate-500 flex-shrink-0">{{ row.workouts }} treinos</span>
            </div>
            <div v-if="!data.top_by_workouts?.length" class="py-6 text-center">
              <p class="text-sm text-slate-400">Sem dados no período.</p>
            </div>
          </div>
        </div>

        <!-- Top by points -->
        <div class="card p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-sm font-semibold text-slate-900">Top alunos — pontos</h2>
            <span class="text-xs text-slate-400">últimos {{ period }}d</span>
          </div>
          <div class="space-y-3">
            <div
              v-for="(row, idx) in data.top_by_points"
              :key="row.id"
              class="flex items-center gap-3"
            >
              <div
                class="w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-bold flex-shrink-0"
                :class="rankClass(idx)"
              >{{ idx + 1 }}</div>
              <p class="flex-1 text-sm font-medium text-slate-800 truncate">{{ row.name }}</p>
              <span class="text-xs font-semibold text-slate-500 flex-shrink-0">{{ row.points.toLocaleString('pt-BR') }} pts</span>
            </div>
            <div v-if="!data.top_by_points?.length" class="py-6 text-center">
              <p class="text-sm text-slate-400">Sem dados no período.</p>
            </div>
          </div>
        </div>

        <!-- Top redemptions -->
        <div class="card p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-sm font-semibold text-slate-900">Recompensas mais resgatadas</h2>
            <span class="text-xs text-slate-400">últimos {{ period }}d</span>
          </div>
          <div class="space-y-3">
            <div
              v-for="(row, idx) in data.top_redemptions"
              :key="idx"
              class="flex items-center gap-3"
            >
              <div
                class="w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-bold flex-shrink-0"
                :class="rankClass(idx)"
              >{{ idx + 1 }}</div>
              <p class="flex-1 text-sm font-medium text-slate-800 truncate">{{ row.reward }}</p>
              <span class="text-xs font-semibold text-slate-500 flex-shrink-0">{{ row.count }}×</span>
            </div>
            <div v-if="!data.top_redemptions?.length" class="py-6 text-center">
              <p class="text-sm text-slate-400">Sem resgates no período.</p>
            </div>
          </div>
        </div>

      </div>

    </template>

  </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue'
import api from '../services/api.js'

const periods = [
  { label: '7 dias',  value: '7'  },
  { label: '30 dias', value: '30' },
  { label: '90 dias', value: '90' },
]

const period       = ref('30')
const data         = ref(null)
const loading      = ref(true)
const error        = ref('')

const workoutsLine = computed(() => {
  const days = data.value?.workouts_by_day ?? []
  if (!days.length) {
    return { points: [], labels: [], linePath: '', areaPath: '' }
  }

  const max = Math.max(...days.map((day) => day.workouts), 1)
  const xStep = days.length === 1 ? 0 : 100 / (days.length - 1)
  const labelEvery = days.length <= 10 ? 1 : Math.ceil(days.length / 6)

  const points = days.map((day, index) => {
    const x = days.length === 1 ? 50 : index * xStep
    const y = 88 - ((day.workouts / max) * 76)

    return {
      ...day,
      x: Number(x.toFixed(2)),
      y: Number(y.toFixed(2)),
    }
  })

  const linePath = points
    .map((point, index) => `${index === 0 ? 'M' : 'L'} ${point.x} ${point.y}`)
    .join(' ')

  const first = points[0]
  const last = points[points.length - 1]
  const areaPath = `${linePath} L ${last.x} 92 L ${first.x} 92 Z`

  return {
    points,
    linePath,
    areaPath,
    labels: points.filter((_, index) => index === 0 || index === points.length - 1 || index % labelEvery === 0),
  }
})

const checkinBars = computed(() => {
  const days = data.value?.checkins_by_weekday ?? []
  const max = Math.max(...days.map((day) => day.checkins), 1)

  return days.map((day) => ({
    ...day,
    height: day.checkins > 0 ? Math.max(12, Math.round((day.checkins / max) * 100)) : 5,
  }))
})

const bestCheckinDay = computed(() => {
  const days = data.value?.checkins_by_weekday ?? []
  return days.reduce(
    (best, day) => (day.checkins > best.checkins ? day : best),
    { day: '-', checkins: 0 },
  )
})

const checkinAverage = computed(() => {
  const total = data.value?.kpis?.total_checkins ?? 0
  return (total / 7).toLocaleString('pt-BR', { maximumFractionDigits: 1 })
})

function fmtPts(n) {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M'
  if (n >= 1_000)     return (n / 1_000).toFixed(1) + 'k'
  return (n ?? 0).toLocaleString('pt-BR')
}

function rankClass(idx) {
  if (idx === 0) return 'bg-amber-100 text-amber-700'
  if (idx === 1) return 'bg-slate-100 text-slate-600'
  if (idx === 2) return 'bg-orange-100 text-orange-700'
  return 'bg-slate-50 text-slate-500'
}

async function loadData() {
  loading.value = true
  error.value   = ''

  try {
    const { data: res } = await api.get('/admin/reports', { params: { period: period.value } })
    data.value = res
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar os relatórios.'
  } finally {
    loading.value = false
  }
}

function selectPeriod(p) {
  period.value = p
  loadData()
}

onMounted(loadData)
</script>
