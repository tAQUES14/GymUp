<template>
  <div>

    <!-- Loading skeleton -->
    <div v-if="loading" class="animate-pulse space-y-5">
      <div class="h-4 w-28 bg-slate-100 rounded" />
      <div class="card px-6 py-5 flex items-center gap-5">
        <div class="w-16 h-16 rounded-full bg-slate-100 flex-shrink-0" />
        <div class="flex-1 space-y-2">
          <div class="h-5 w-48 bg-slate-100 rounded" />
          <div class="h-3.5 w-36 bg-slate-100 rounded" />
          <div class="flex gap-2 mt-2">
            <div class="h-6 w-20 bg-slate-100 rounded-full" />
            <div class="h-6 w-16 bg-slate-100 rounded-full" />
          </div>
        </div>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar aluno</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else-if="user">

      <!-- Breadcrumb -->
      <button @click="$router.push('/users')"
        class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors mb-5">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
        </svg>
        Alunos
      </button>

      <!-- ── HEADER CARD ─────────────────────────────────────────── -->
      <div class="card px-6 py-5 mb-6">
        <div class="flex flex-col sm:flex-row sm:items-center gap-5">

          <!-- Avatar + info -->
          <div class="flex items-center gap-4 flex-1 min-w-0">
            <div class="w-16 h-16 rounded-2xl flex items-center justify-center text-xl font-bold text-white flex-shrink-0 shadow-md"
                 :style="{ backgroundColor: avatarColor(user.name) }">
              {{ initials(user.name) }}
            </div>
            <div class="min-w-0">
              <h1 class="text-xl font-bold text-slate-900 leading-tight truncate">{{ user.name }}</h1>
              <p class="text-sm text-slate-500 mt-0.5">{{ user.email }}</p>
              <div class="flex flex-wrap items-center gap-2 mt-2">
                <!-- Status -->
                <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold"
                      :class="statusClass">
                  <span class="w-1.5 h-1.5 rounded-full" :class="statusDot" />
                  {{ statusLabel }}
                </span>
                <!-- Streak diário -->
                <span v-if="user.current_streak > 0"
                  class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-orange-50 text-orange-600">
                  🔥 {{ user.current_streak }} dia{{ user.current_streak !== 1 ? 's' : '' }}
                </span>
                <span v-if="user.best_streak > 0"
                  class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-600">
                  🏆 {{ user.best_streak }}
                </span>
                <!-- Points -->
                <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700">
                  ⭐ {{ user.points_balance.toLocaleString('pt-BR') }} pts
                </span>
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex items-center gap-2 flex-shrink-0">
            <!-- Visitor notice -->
            <span v-if="user.is_visitor"
              class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-semibold
                     bg-slate-100 text-slate-500"
              :title="user.home_gym_name ? `Filial de origem: ${user.home_gym_name}` : undefined"
            >
              Visitante{{ user.home_gym_name ? ` · ${user.home_gym_name}` : '' }}
            </span>
            <template v-else>
              <button @click="editOpen = true"
                class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-semibold text-slate-600
                       border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
                </svg>
                Editar
              </button>
              <button @click="deleteConfirm = true"
                class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-semibold text-red-600
                       border border-red-200 rounded-lg hover:bg-red-50 transition-colors">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
                </svg>
                Excluir
              </button>
            </template>
          </div>
        </div>
      </div>

      <!-- ── TABS ───────────────────────────────────────────────── -->
      <div class="flex items-center gap-1 mb-5 border-b border-slate-200">
        <button v-for="tab in tabs" :key="tab.key" @click="activeTab = tab.key"
          class="px-4 py-2.5 text-sm font-semibold transition-colors relative"
          :class="activeTab === tab.key ? 'text-brand-600' : 'text-slate-500 hover:text-slate-700'"
        >
          {{ tab.label }}
          <span v-if="tab.count !== undefined"
            class="ml-1.5 inline-flex items-center justify-center min-w-[1.25rem] h-5 px-1 rounded-full text-[11px]"
            :class="activeTab === tab.key ? 'bg-brand-100 text-brand-700' : 'bg-slate-100 text-slate-500'">
            {{ tab.count }}
          </span>
          <span v-if="activeTab === tab.key"
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-brand-600 rounded-t-full" />
        </button>
      </div>

      <!-- ── TAB: VISÃO GERAL ───────────────────────────────────── -->
      <template v-if="activeTab === 'overview'">

        <!-- Stats row -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-5">
          <div class="card px-4 py-3.5 text-center">
            <p class="text-2xl font-black text-slate-900">{{ user.workouts_total }}</p>
            <p class="text-xs text-slate-500 mt-0.5">Treinos feitos</p>
          </div>
          <div class="card px-4 py-3.5 text-center">
            <p class="text-2xl font-black text-amber-600">{{ user.points_balance.toLocaleString('pt-BR') }}</p>
            <p class="text-xs text-slate-500 mt-0.5">Pontos acumulados</p>
          </div>
          <div class="card px-4 py-3.5 text-center">
            <p class="text-2xl font-black" :class="user.current_streak > 0 ? 'text-orange-500' : 'text-slate-300'">
              {{ user.current_streak > 0 ? `🔥 ${user.current_streak}` : '—' }}
            </p>
            <p class="text-xs text-slate-500 mt-0.5">Streak atual</p>
            <p v-if="user.best_streak > 0" class="text-[10px] text-slate-400 mt-0.5">🏆 Recorde: {{ user.best_streak }}</p>
          </div>
          <div class="card px-4 py-3.5 text-center">
            <p class="text-base font-bold text-slate-900 leading-tight">{{ lastActivityLabel }}</p>
            <p class="text-xs text-slate-500 mt-0.5">Último treino</p>
          </div>
        </div>

        <!-- Profile info -->
        <div class="card px-5 py-4">
          <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-4">Perfil</p>
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-y-5 gap-x-8">

            <div>
              <p class="text-xs text-slate-400 mb-0.5">Nome completo</p>
              <p class="text-sm font-semibold text-slate-800">{{ user.name }}</p>
            </div>
            <div>
              <p class="text-xs text-slate-400 mb-0.5">E-mail</p>
              <p class="text-sm font-semibold text-slate-800 truncate">{{ user.email }}</p>
            </div>
            <div>
              <p class="text-xs text-slate-400 mb-0.5">Nascimento</p>
              <p class="text-sm font-semibold text-slate-800">
                {{ user.birth_date ? formatBirthDate(user.birth_date) : '—' }}
              </p>
            </div>
            <div>
              <p class="text-xs text-slate-400 mb-0.5">Idade</p>
              <p class="text-sm font-semibold text-slate-800">
                {{ user.birth_date ? calcAge(user.birth_date) + ' anos' : '—' }}
              </p>
            </div>
            <div>
              <p class="text-xs text-slate-400 mb-0.5">Altura</p>
              <p class="text-sm font-semibold text-slate-800">
                {{ user.height ? user.height + ' cm' : '—' }}
              </p>
            </div>
            <div>
              <p class="text-xs text-slate-400 mb-0.5">Peso</p>
              <p class="text-sm font-semibold text-slate-800">
                {{ user.weight ? user.weight + ' kg' : '—' }}
              </p>
            </div>

          </div>
        </div>

      </template>

      <!-- ── TAB: STREAK ───────────────────────────────────────── -->
      <template v-if="activeTab === 'schedule'">
        <div class="card px-5 py-5">
          <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-5">Streak diário</p>
          <div class="grid grid-cols-2 sm:grid-cols-3 gap-4">
            <div class="text-center p-4 bg-orange-50 rounded-xl">
              <p class="text-3xl font-black" :class="user.current_streak > 0 ? 'text-orange-500' : 'text-slate-300'">
                {{ user.current_streak > 0 ? `🔥 ${user.current_streak}` : '—' }}
              </p>
              <p class="text-xs text-slate-500 mt-1">Streak atual</p>
            </div>
            <div class="text-center p-4 bg-amber-50 rounded-xl">
              <p class="text-3xl font-black" :class="user.best_streak > 0 ? 'text-amber-500' : 'text-slate-300'">
                {{ user.best_streak > 0 ? `🏆 ${user.best_streak}` : '—' }}
              </p>
              <p class="text-xs text-slate-500 mt-1">Recorde</p>
            </div>
            <div class="text-center p-4 bg-slate-50 rounded-xl">
              <p class="text-3xl font-black text-slate-700">{{ user.workouts_total }}</p>
              <p class="text-xs text-slate-500 mt-1">Treinos feitos</p>
            </div>
          </div>
          <p class="text-[11px] text-slate-400 mt-5">
            O streak avança apenas em dias de treino do plano ativo. Dias de descanso pausam o contador — sem penalidade.
            Sem plano atribuído, o streak fica congelado.
          </p>
        </div>
      </template>

      <!-- ── TAB: TREINOS ───────────────────────────────────────── -->
      <template v-if="activeTab === 'sessions'">
        <div class="card overflow-hidden">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-slate-100 bg-slate-50/60">
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Data</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-center hidden sm:table-cell">Progresso</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right">Pontos</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="user.sessions.length === 0">
                <td colspan="3" class="px-5 py-14 text-center">
                  <p class="text-sm font-semibold text-slate-500 mb-1">Nenhum treino registrado</p>
                  <p class="text-xs text-slate-400">Este aluno ainda não realizou nenhum treino.</p>
                </td>
              </tr>
              <tr v-for="s in user.sessions" :key="s.id"
                class="border-b border-slate-100 hover:bg-slate-50/60 transition-colors">
                <td class="px-5 py-3.5">
                  <p class="text-sm font-semibold text-slate-800">{{ formatSessionDate(s.finished_at ?? s.started_at) }}</p>
                  <p class="text-[11px] text-slate-400 mt-0.5">{{ formatSessionTime(s.finished_at ?? s.started_at) }}</p>
                </td>
                <td class="px-5 py-3.5 hidden sm:table-cell">
                  <div class="flex items-center gap-2 justify-center">
                    <div class="w-24 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                      <div class="h-full rounded-full transition-all"
                           :class="s.progress >= 75 ? 'bg-emerald-500' : s.progress >= 40 ? 'bg-amber-400' : 'bg-slate-300'"
                           :style="{ width: s.progress + '%' }" />
                    </div>
                    <span class="text-xs text-slate-500 w-8 flex-shrink-0">{{ s.progress }}%</span>
                  </div>
                </td>
                <td class="px-5 py-3.5 text-right">
                  <span v-if="s.points_granted"
                    class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700">
                    <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    Pontos
                  </span>
                  <span v-else class="text-xs text-slate-400">Sem pontos</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>

      <!-- ── TAB: PONTOS ────────────────────────────────────────── -->
      <template v-if="activeTab === 'points'">

        <!-- Saldo + ajuste -->
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <div class="card px-4 py-2.5 flex items-center gap-2">
              <span class="text-xs text-slate-500">Saldo atual</span>
              <span class="text-base font-black text-amber-600">{{ user.points_balance.toLocaleString('pt-BR') }} pts</span>
            </div>
          </div>
          <button @click="adjustOpen = true"
            class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-semibold text-brand-600
                   border border-brand-200 rounded-lg hover:bg-brand-50 transition-colors">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Ajustar pontos
          </button>
        </div>

        <div class="card overflow-hidden">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-slate-100 bg-slate-50/60">
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Data</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Descrição</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right">Pontos</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="user.transactions.length === 0">
                <td colspan="3" class="px-5 py-14 text-center">
                  <p class="text-sm font-semibold text-slate-500 mb-1">Nenhuma transação</p>
                  <p class="text-xs text-slate-400">Este aluno ainda não tem movimentações de pontos.</p>
                </td>
              </tr>
              <tr v-for="t in user.transactions" :key="t.id"
                class="border-b border-slate-100 hover:bg-slate-50/60 transition-colors">
                <td class="px-5 py-3.5 whitespace-nowrap">
                  <p class="text-sm text-slate-700">{{ formatTxDate(t.created_at) }}</p>
                  <p class="text-[11px] text-slate-400 mt-0.5">{{ formatTxTime(t.created_at) }}</p>
                </td>
                <td class="px-5 py-3.5">
                  <div class="flex items-center gap-2">
                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold flex-shrink-0"
                          :class="categoryClass(t.category)">
                      {{ categoryLabel(t.category) }}
                    </span>
                    <span class="text-sm text-slate-600 truncate max-w-[260px]">{{ t.description ?? '—' }}</span>
                  </div>
                </td>
                <td class="px-5 py-3.5 text-right whitespace-nowrap">
                  <span class="text-sm font-bold"
                        :class="t.type === 'earn' ? 'text-emerald-600' : 'text-red-500'">
                    {{ t.type === 'earn' ? '+' : '−' }}{{ t.points.toLocaleString('pt-BR') }}
                  </span>
                  <span class="text-[10px] text-slate-400 ml-1">pts</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>

    <!-- ── TAB: RESGATES ─────────────────────────────────────────── -->
      <template v-if="activeTab === 'redemptions'">
        <div class="card overflow-hidden">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-slate-100 bg-slate-50/60">
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Data</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Recompensa</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-center hidden sm:table-cell">Pontos</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right">Status</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="!user.redemptions || user.redemptions.length === 0">
                <td colspan="4" class="px-5 py-14 text-center">
                  <p class="text-sm font-semibold text-slate-500 mb-1">Nenhum resgate realizado</p>
                  <p class="text-xs text-slate-400">Este aluno ainda não solicitou nenhuma recompensa.</p>
                </td>
              </tr>
              <tr v-for="r in user.redemptions" :key="r.id"
                class="border-b border-slate-100 hover:bg-slate-50/60 transition-colors">
                <td class="px-5 py-3.5 whitespace-nowrap">
                  <p class="text-sm font-semibold text-slate-800">{{ formatSessionDate(r.created_at) }}</p>
                  <p class="text-[11px] text-slate-400 mt-0.5">{{ formatSessionTime(r.created_at) }}</p>
                </td>
                <td class="px-5 py-3.5">
                  <p class="text-sm font-semibold text-slate-800">{{ r.reward_name }}</p>
                  <p v-if="r.approved_at" class="text-[11px] text-slate-400 mt-0.5">
                    Aprovado em {{ formatSessionDate(r.approved_at) }}
                  </p>
                </td>
                <td class="px-5 py-3.5 text-center hidden sm:table-cell whitespace-nowrap">
                  <span class="text-sm font-bold text-red-500">−{{ r.points_spent.toLocaleString('pt-BR') }}</span>
                  <span class="text-[10px] text-slate-400 ml-1">pts</span>
                </td>
                <td class="px-5 py-3.5 text-right">
                  <span class="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold"
                        :class="redemptionStatusClass(r.status)">
                    {{ redemptionStatusLabel(r.status) }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>

    </template>

    <!-- ── MODALS ─────────────────────────────────────────────────── -->
    <UserEditModal v-if="user" v-model="editOpen" :user="user" @saved="onEdited" />
    <AdjustPointsModal v-if="user" v-model="adjustOpen" :user="user" @saved="onPointsAdjusted" />

    <!-- Delete confirmation -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="deleteConfirm" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="deleteConfirm = false" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-sm">
            <div class="flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mx-auto mb-4">
              <svg class="w-6 h-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
              </svg>
            </div>
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Excluir aluno</h3>
            <p class="text-sm text-slate-500 text-center mb-5">
              Tem certeza que deseja remover
              <strong class="text-slate-700">{{ user?.name }}</strong>? Esta ação não pode ser desfeita.
            </p>
            <p v-if="deleteError" class="text-xs text-red-500 text-center mb-3">{{ deleteError }}</p>
            <div class="flex items-center gap-3">
              <button @click="deleteConfirm = false" class="flex-1 btn-secondary">Cancelar</button>
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
import { useRoute, useRouter } from 'vue-router'
import api from '../services/api.js'
import UserEditModal    from '../components/users/UserEditModal.vue'
import AdjustPointsModal from '../components/users/AdjustPointsModal.vue'

const route  = useRoute()
const router = useRouter()

const user          = ref(null)
const loading       = ref(true)
const error         = ref('')
const activeTab     = ref('overview')
const editOpen      = ref(false)
const adjustOpen    = ref(false)
const deleteConfirm = ref(false)
const deleting      = ref(false)
const deleteError   = ref('')


const tabs = computed(() => [
  { key: 'overview',    label: 'Visão Geral' },
  { key: 'schedule',    label: 'Streak' },
  { key: 'sessions',    label: 'Treinos',    count: user.value?.sessions?.length ?? 0 },
  { key: 'points',      label: 'Pontos',     count: user.value?.transactions?.length ?? 0 },
  { key: 'redemptions', label: 'Resgates',   count: user.value?.redemptions?.length ?? 0 },
])

// ── Status ─────────────────────────────────────────────────────────
const STATUS_MAP = {
  active:   { label: 'Ativo',   class: 'bg-emerald-50 text-emerald-700', dot: 'bg-emerald-500' },
  inactive: { label: 'Inativo', class: 'bg-slate-100  text-slate-500',   dot: 'bg-slate-400'   },
  new:      { label: 'Novo',    class: 'bg-brand-50   text-brand-700',   dot: 'bg-brand-500'   },
}
const statusClass = computed(() => STATUS_MAP[user.value?.status]?.class ?? STATUS_MAP.new.class)
const statusDot   = computed(() => STATUS_MAP[user.value?.status]?.dot   ?? STATUS_MAP.new.dot)
const statusLabel = computed(() => STATUS_MAP[user.value?.status]?.label ?? 'Novo')

// ── Last activity ─────────────────────────────────────────────────
const lastActivityLabel = computed(() => {
  if (!user.value?.last_activity) return '—'
  const date  = new Date(user.value.last_activity + 'T00:00:00')
  const today = new Date(); today.setHours(0, 0, 0, 0)
  const days  = Math.round((today - date) / 86400000)
  if (days === 0) return 'Hoje'
  if (days === 1) return 'Ontem'
  if (days < 7)  return `${days} dias atrás`
  if (days < 30) return `${Math.floor(days / 7)} sem. atrás`
  return date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' })
})

// ── Data ────────────────────────────────────────────────────────────
async function load() {
  loading.value = true; error.value = ''
  try {
    const { data } = await api.get(`/admin/users/${route.params.id}`)
    user.value = data
  } catch {
    error.value = 'Não foi possível carregar o aluno.'
  } finally { loading.value = false }
}

function onEdited(updated) {
  Object.assign(user.value, updated)
}

function onPointsAdjusted({ points_balance }) {
  user.value.points_balance = points_balance
  load() // reload transactions
}

async function confirmDelete() {
  deleting.value = true; deleteError.value = ''
  try {
    await api.delete(`/admin/users/${user.value.id}`)
    router.push('/users')
  } catch (e) {
    deleteError.value = e.response?.data?.message ?? 'Erro ao excluir aluno.'
  } finally { deleting.value = false }
}

// ── Helpers ─────────────────────────────────────────────────────────
function initials(name) {
  const parts = (name ?? '?').trim().split(/\s+/)
  return parts.length >= 2
    ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
    : (parts[0][0] ?? '?').toUpperCase()
}

function avatarColor(name) {
  const colors = ['#6366f1','#8b5cf6','#ec4899','#f59e0b','#10b981','#3b82f6','#ef4444','#14b8a6','#f97316','#06b6d4']
  let h = 0
  for (const c of (name ?? '')) h = (h * 31 + c.charCodeAt(0)) & 0xffffffff
  return colors[Math.abs(h) % colors.length]
}

function formatBirthDate(iso) {
  return new Date(iso + 'T00:00:00').toLocaleDateString('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' })
}

function calcAge(iso) {
  const birth = new Date(iso + 'T00:00:00')
  const now   = new Date()
  let age = now.getFullYear() - birth.getFullYear()
  if (now.getMonth() < birth.getMonth() || (now.getMonth() === birth.getMonth() && now.getDate() < birth.getDate())) age--
  return age
}

function formatSessionDate(dt) {
  if (!dt) return '—'
  return new Date(dt).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: '2-digit' })
}
function formatSessionTime(dt) {
  if (!dt) return ''
  return new Date(dt).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}
function formatTxDate(dt) { return formatSessionDate(dt) }
function formatTxTime(dt) { return formatSessionTime(dt) }

const CATEGORY_MAP = {
  workout:   { label: 'Treino',   class: 'bg-brand-50 text-brand-700' },
  checkin:   { label: 'Check-in', class: 'bg-violet-50 text-violet-700' },
  challenge: { label: 'Desafio',  class: 'bg-amber-50 text-amber-700' },
  manual:    { label: 'Manual',   class: 'bg-slate-100 text-slate-600' },
  redemption:{ label: 'Resgate',  class: 'bg-red-50 text-red-600' },
}
function categoryLabel(cat) { return CATEGORY_MAP[cat]?.label ?? cat }
function categoryClass(cat) { return CATEGORY_MAP[cat]?.class ?? 'bg-slate-100 text-slate-500' }

const REDEMPTION_STATUS_MAP = {
  pending:  { label: 'Pendente',  class: 'bg-amber-50 text-amber-700' },
  approved: { label: 'Aprovado',  class: 'bg-emerald-50 text-emerald-700' },
  rejected: { label: 'Recusado',  class: 'bg-red-50 text-red-600' },
}
function redemptionStatusLabel(s) { return REDEMPTION_STATUS_MAP[s]?.label ?? s }
function redemptionStatusClass(s) { return REDEMPTION_STATUS_MAP[s]?.class ?? 'bg-slate-100 text-slate-500' }

onMounted(load)
</script>
