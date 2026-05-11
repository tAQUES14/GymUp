<template>
  <div>

    <div class="mb-6">
      <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Painel da Rede</h1>
      <p class="text-slate-500 text-sm mt-1">Visão consolidada de todas as filiais da sua rede.</p>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="space-y-5 animate-pulse">
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div v-for="n in 4" :key="n" class="card p-5 space-y-2">
          <div class="h-3 w-20 bg-slate-100 rounded" />
          <div class="h-7 w-12 bg-slate-100 rounded" />
        </div>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar painel</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else-if="data">

      <!-- ── CARDS ──────────────────────────────────────────────────────── -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">

        <div class="card p-5">
          <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1">Total de alunos</p>
          <p class="text-3xl font-bold text-slate-900">{{ data.total_students.toLocaleString('pt-BR') }}</p>
        </div>

        <div class="card p-5">
          <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1">Check-ins esta semana</p>
          <p class="text-3xl font-bold text-brand-600">{{ data.weekly_checkins.toLocaleString('pt-BR') }}</p>
        </div>

        <div class="card p-5">
          <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1">Total de filiais</p>
          <p class="text-3xl font-bold text-slate-900">{{ data.total_branches }}</p>
        </div>

        <div class="card p-5">
          <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1">Trainers</p>
          <p class="text-3xl font-bold text-slate-900">{{ data.total_trainers }}</p>
        </div>

      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-5">

        <!-- ── TOP 5 ALUNOS ─────────────────────────────────────────────── -->
        <div class="card overflow-hidden">
          <div class="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
            <h2 class="text-sm font-semibold text-slate-800">Top 5 alunos</h2>
            <span class="text-[11px] text-slate-400">por pontos</span>
          </div>

          <div v-if="data.top_students.length === 0" class="px-5 py-8 text-center text-sm text-slate-400">
            Nenhum aluno ainda.
          </div>

          <ul v-else>
            <li v-for="(student, i) in data.top_students" :key="student.id"
                class="flex items-center gap-3.5 px-5 py-3 border-b border-slate-100 last:border-0">
              <span class="w-6 text-center text-xs font-bold"
                    :class="i === 0 ? 'text-amber-500' : i === 1 ? 'text-slate-400' : i === 2 ? 'text-amber-700' : 'text-slate-300'">
                {{ i + 1 }}
              </span>
              <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0"
                   :style="{ backgroundColor: avatarColor(student.name) }">
                {{ student.name[0].toUpperCase() }}
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-slate-800 truncate">{{ student.name }}</p>
                <p class="text-[11px] text-slate-400 truncate">{{ student.gym_name ?? '—' }}</p>
              </div>
              <span class="text-sm font-bold text-amber-600">
                {{ student.points_balance.toLocaleString('pt-BR') }} pts
              </span>
            </li>
          </ul>
        </div>

        <!-- ── FILIAIS ───────────────────────────────────────────────────── -->
        <div class="card overflow-hidden">
          <div class="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
            <h2 class="text-sm font-semibold text-slate-800">Filiais</h2>
            <button @click="$router.push('/network/gyms')"
              class="text-[11px] text-brand-600 hover:text-brand-700 font-semibold transition-colors">
              Gerenciar →
            </button>
          </div>

          <div v-if="data.branches.length === 0" class="px-5 py-8 text-center text-sm text-slate-400">
            Nenhuma filial na rede.
          </div>

          <ul v-else>
            <li v-for="branch in data.branches" :key="branch.id"
                class="flex items-center gap-3.5 px-5 py-3.5 border-b border-slate-100 last:border-0">
              <div class="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
                <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
                  <path stroke-linecap="round" stroke-linejoin="round"
                    d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21" />
                </svg>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-slate-800 truncate">{{ branch.name }}</p>
                <p class="text-[11px] text-slate-400">{{ branch.city ?? '—' }}</p>
              </div>
              <div class="text-right shrink-0">
                <p class="text-xs font-semibold text-slate-700">{{ branch.students_count }} alunos</p>
                <p class="text-[11px] text-slate-400">{{ branch.weekly_checkins }} check-ins</p>
              </div>
            </li>
          </ul>
        </div>

      </div>

    </template>

  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../services/api.js'

const data    = ref(null)
const loading = ref(true)
const error   = ref(null)

const AVATAR_COLORS = ['#3B82F6','#8B5CF6','#10B981','#F59E0B','#EF4444','#06B6D4','#6366F1','#14B8A6']

function avatarColor(name) {
  const code = [...(name ?? 'A')].reduce((acc, c) => acc + c.charCodeAt(0), 0)
  return AVATAR_COLORS[code % AVATAR_COLORS.length]
}

onMounted(load)

async function load() {
  loading.value = true
  error.value   = null
  try {
    const { data: d } = await api.get('/network/dashboard')
    data.value = d
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao carregar painel.'
  } finally {
    loading.value = false
  }
}
</script>
