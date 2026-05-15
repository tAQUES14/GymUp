<template>
  <div>

    <!-- Page header -->
    <div class="mb-8">
      <h1 class="text-2xl font-bold text-slate-900 tracking-tight">
        Olá, {{ firstName }} 👋
      </h1>
      <p class="text-slate-500 text-sm mt-1">
        {{ data?.dashboard_type === 'global'
            ? 'Visão geral da plataforma GymUp.'
            : 'Aqui está o resumo da sua academia hoje.' }}
      </p>
    </div>

    <!-- Loading skeleton -->
    <template v-if="loading">
      <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">
        <div v-for="n in 4" :key="n" class="card p-5 animate-pulse">
          <div class="flex items-start gap-4">
            <div class="w-11 h-11 rounded-xl bg-slate-100" />
            <div class="flex-1 space-y-2">
              <div class="h-3 bg-slate-100 rounded w-24" />
              <div class="h-6 bg-slate-100 rounded w-16" />
            </div>
          </div>
        </div>
      </div>
      <div class="card p-6 animate-pulse h-72" />
    </template>

    <!-- ── Dashboard Global (super_admin) ─────────────────────────────────── -->
    <template v-else-if="data?.dashboard_type === 'global'">

      <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5 mb-8">
        <StatCard
          label="Academias Ativas"
          :value="data.total_gyms"
          :delta="null"
          color="indigo"
          icon="gyms"
        />
        <StatCard
          label="Usuários Totais"
          :value="data.total_users"
          :delta="null"
          color="emerald"
          icon="users"
        />
        <StatCard
          label="Treinos Hoje"
          :value="data.workouts_today"
          :delta="null"
          color="amber"
          icon="dumbbell"
        />
      </div>

      <!-- Charts row -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-5 mb-8">

        <!-- Weekly Activity Chart -->
        <div class="card p-6 xl:col-span-2">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h2 class="text-sm font-semibold text-slate-900">Atividade Semanal da Plataforma</h2>
              <p class="text-xs text-slate-400 mt-0.5">Treinos concluídos nos últimos 7 dias</p>
            </div>
            <span class="text-xs font-medium text-brand-600 bg-brand-50 px-2.5 py-1 rounded-full">
              {{ totalWeeklyWorkouts }} treinos
            </span>
          </div>
          <div class="h-52">
            <canvas ref="chartCanvas" />
          </div>
        </div>

        <!-- Top Gyms -->
        <div class="card p-6">
          <div class="flex items-center justify-between mb-5">
            <h2 class="text-sm font-semibold text-slate-900">Top Academias</h2>
            <span class="text-xs text-slate-400">por alunos</span>
          </div>
          <div class="space-y-3">
            <div
              v-for="(gym, idx) in data.top_gyms"
              :key="gym.id"
              class="flex items-center gap-3"
            >
              <div
                class="w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-bold flex-shrink-0"
                :class="rankClass(idx)"
              >{{ idx + 1 }}</div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-slate-800 truncate">{{ gym.name }}</p>
              </div>
              <span class="text-xs font-semibold text-slate-500">
                {{ gym.users }} alunos
              </span>
            </div>
            <div v-if="!data.top_gyms?.length" class="text-center py-6">
              <p class="text-sm text-slate-400">Nenhuma academia ainda.</p>
            </div>
          </div>
        </div>
      </div>

    </template>

    <!-- ── Dashboard da Academia (gym_admin / trainer) ─────────────────────── -->
    <template v-else-if="data?.dashboard_type === 'gym'">

      <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5 mb-8">
        <StatCard
          label="Total de Alunos"
          :value="data.total_users"
          :delta="null"
          color="indigo"
          icon="users"
        />
        <StatCard
          label="Treinos Hoje"
          :value="data.workouts_today"
          :delta="null"
          color="emerald"
          icon="dumbbell"
        />
        <StatCard
          label="Desafios Ativos"
          :value="data.active_challenges"
          :delta="null"
          color="amber"
          icon="trophy"
        />
        <StatCard
          label="Pontos Distribuídos"
          :value="formatPoints(data.points_distributed)"
          :delta="null"
          color="violet"
          icon="star"
        />
      </div>

      <!-- Resgates pendentes (clicável) -->
      <RouterLink
        v-if="data.pending_redemptions > 0"
        to="/redemptions?status=pending"
        class="flex items-center gap-4 card px-5 py-4 mb-8 hover:border-amber-200 hover:bg-amber-50/40
               transition-colors border border-transparent group"
      >
        <div class="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center flex-shrink-0">
          <svg class="w-5 h-5 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M16.5 6v.75m0 3v.75m0 3v.75m0 3V18m-9-5.25h5.25M7.5 15h3M3.375 5.25c-.621 0-1.125.504-1.125 1.125v3.026a2.999 2.999 0 010 5.198v3.026c0 .621.504 1.125 1.125 1.125h17.25c.621 0 1.125-.504 1.125-1.125v-3.026a3 3 0 010-5.198V6.375c0-.621-.504-1.125-1.125-1.125H3.375z" />
          </svg>
        </div>
        <div class="flex-1">
          <p class="text-sm font-semibold text-slate-800">
            {{ data.pending_redemptions }} resgate{{ data.pending_redemptions !== 1 ? 's' : '' }} pendente{{ data.pending_redemptions !== 1 ? 's' : '' }}
          </p>
          <p class="text-xs text-slate-500">Clique para revisar e aprovar</p>
        </div>
        <svg class="w-4 h-4 text-slate-400 group-hover:text-amber-500 transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
        </svg>
      </RouterLink>

      <div class="grid grid-cols-1 xl:grid-cols-3 gap-5 mb-8">

        <!-- Weekly Activity Chart -->
        <div class="card p-6 xl:col-span-2">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h2 class="text-sm font-semibold text-slate-900">Atividade Semanal</h2>
              <p class="text-xs text-slate-400 mt-0.5">Treinos concluídos nos últimos 7 dias</p>
            </div>
            <span class="text-xs font-medium text-brand-600 bg-brand-50 px-2.5 py-1 rounded-full">
              {{ totalWeeklyWorkouts }} treinos
            </span>
          </div>
          <div class="h-52">
            <canvas ref="chartCanvas" />
          </div>
        </div>

        <!-- Top Students -->
        <div class="card p-6">
          <div class="flex items-center justify-between mb-5">
            <h2 class="text-sm font-semibold text-slate-900">Top Alunos</h2>
            <span class="text-xs text-slate-400">por pontos</span>
          </div>
          <div class="space-y-3">
            <div
              v-for="(student, idx) in data.top_students"
              :key="student.id"
              class="flex items-center gap-3"
            >
              <div
                class="w-6 h-6 rounded-full flex items-center justify-center text-[11px] font-bold flex-shrink-0"
                :class="rankClass(idx)"
              >{{ idx + 1 }}</div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-slate-800 truncate">{{ student.name }}</p>
              </div>
              <span class="text-xs font-semibold text-slate-500">
                {{ student.points_balance.toLocaleString('pt-BR') }} pts
              </span>
            </div>
            <div v-if="!data.top_students?.length" class="text-center py-6">
              <p class="text-sm text-slate-400">Nenhum aluno ainda.</p>
            </div>
          </div>
        </div>
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
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar dados</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadData" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { RouterLink } from 'vue-router'
import { Chart, BarElement, CategoryScale, LinearScale, Tooltip, Filler } from 'chart.js'
import { useAuthStore } from '../stores/auth.js'
import api from '../services/api.js'
import StatCard from '../components/dashboard/StatCard.vue'

Chart.register(BarElement, CategoryScale, LinearScale, Tooltip, Filler)

const auth        = useAuthStore()
const data        = ref(null)
const loading     = ref(true)
const error       = ref('')
const chartCanvas = ref(null)
let   chartInstance = null

const firstName = computed(() => {
  const name = data.value?.admin_name ?? auth.user?.name ?? ''
  return name.split(' ')[0]
})

const totalWeeklyWorkouts = computed(() => {
  if (!data.value?.weekly_activity) return 0
  return data.value.weekly_activity.reduce((s, d) => s + d.workouts, 0)
})

function formatPoints(n) {
  if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M'
  if (n >= 1_000)     return (n / 1_000).toFixed(1) + 'k'
  return n?.toLocaleString('pt-BR') ?? '0'
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
    const { data: res } = await api.get('/admin/dashboard')
    data.value = res
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar o dashboard.'
  } finally {
    loading.value = false
  }
  await nextTick()
  renderChart()
}

function renderChart() {
  if (!chartCanvas.value || !data.value?.weekly_activity) return

  if (chartInstance) {
    chartInstance.destroy()
    chartInstance = null
  }

  const activity = data.value.weekly_activity
  const labels   = activity.map(d => d.day)
  const values   = activity.map(d => d.workouts)
  const maxVal   = Math.max(...values, 1)

  chartInstance = new Chart(chartCanvas.value, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: 'Treinos',
        data: values,
        backgroundColor: (ctx) => {
          const gradient = ctx.chart.ctx.createLinearGradient(0, 0, 0, ctx.chart.height)
          gradient.addColorStop(0, 'rgba(99, 102, 241, 0.85)')
          gradient.addColorStop(1, 'rgba(99, 102, 241, 0.25)')
          return gradient
        },
        borderColor: 'rgba(99, 102, 241, 0)',
        borderRadius: 8,
        borderSkipped: false,
        barPercentage: 0.55,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) => ` ${ctx.parsed.y} treino${ctx.parsed.y !== 1 ? 's' : ''}`,
          },
          backgroundColor: '#1e293b',
          titleColor: '#94a3b8',
          bodyColor: '#f1f5f9',
          padding: 10,
          cornerRadius: 8,
          displayColors: false,
        },
      },
      scales: {
        x: {
          grid: { display: false },
          border: { display: false },
          ticks: {
            color: '#94a3b8',
            font: { size: 12, family: 'Inter' },
          },
        },
        y: {
          grid: {
            color: '#f1f5f9',
            drawTicks: false,
          },
          border: { display: false, dash: [4, 4] },
          ticks: {
            color: '#94a3b8',
            font: { size: 11, family: 'Inter' },
            padding: 8,
            stepSize: Math.ceil(maxVal / 4) || 1,
          },
          min: 0,
        },
      },
    },
  })
}

onMounted(loadData)
</script>
