<template>
  <header class="fixed inset-x-0 top-0 z-30 flex h-16 items-center gap-2 border-b border-slate-100 bg-white px-4 sm:gap-4 sm:px-6 lg:left-64">

    <button
      type="button"
      class="-ml-1 flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-xl text-slate-600 transition hover:bg-slate-100 lg:hidden"
      aria-label="Abrir menu"
      @click="$emit('toggle-sidebar')"
    >
      <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" /></svg>
    </button>

    <!-- Breadcrumb / Page title -->
    <div class="flex min-w-0 items-center gap-2 text-sm">
      <span class="hidden text-slate-400 sm:inline">GymUp</span>
      <svg class="hidden w-4 h-4 text-slate-300 sm:block" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
      </svg>
      <span class="truncate font-semibold text-slate-800">{{ pageTitle }}</span>
    </div>

    <!-- Spacer -->
    <div class="flex-1" />

    <!-- Date -->
    <span class="text-xs text-slate-400 hidden sm:block">{{ currentDate }}</span>

    <!-- Gym Switcher (trainer com múltiplas filiais) -->
    <GymSwitcher />

    <!-- Divider -->
    <div class="hidden h-5 w-px bg-slate-200 sm:block" />

    <!-- User pill -->
    <div class="flex items-center gap-2.5 rounded-full px-1.5 py-1">
      <div class="w-7 h-7 rounded-full bg-brand-600 flex items-center justify-center overflow-hidden">
        <img
          v-if="auth.user?.avatar_url"
          :src="auth.user.avatar_url"
          :alt="auth.user?.name ?? 'Perfil'"
          class="w-full h-full object-cover"
        />
        <span v-else class="text-white text-xs font-bold">{{ userInitial }}</span>
      </div>
      <span class="text-sm font-medium text-slate-700 hidden sm:block">{{ auth.user?.name }}</span>
    </div>

  </header>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '../../stores/auth.js'
import GymSwitcher from './GymSwitcher.vue'

defineEmits(['toggle-sidebar'])

const auth  = useAuthStore()
const route = useRoute()

const pageTitles = {
  '/dashboard':          'Dashboard',
  '/users':              'Alunos',
  '/workouts':           'Treinos',
  '/workout-plans':      'Planos de Treino',
  '/exercises':          'Exercícios',
  '/challenges':         'Desafios',
  '/achievements':       'Conquistas',
  '/ranking':            'Ranking',
  '/rewards':            'Recompensas',
  '/redemptions':        'Resgates',
  '/invite':             'Convidar Alunos',
  '/checkin':            'Check-in & QR Code',
  '/roles':              'Permissões',
  '/gyms':               'Academias',
  '/reports':            'Relatórios',
  '/settings':           'Configurações',
  '/chains':             'Redes',
  '/network/dashboard':  'Painel da Rede',
  '/network/gyms':       'Filiais da Rede',
  '/network/trainers':   'Trainers da Rede',
}

const pageTitle = computed(() => {
  if (route.path.startsWith('/users/')) return 'Perfil do Aluno'
  if (route.path === '/chains/new') return 'Nova Rede'
  if (route.path.match(/^\/chains\/\d+\/edit$/)) return 'Editar Rede'
  if (route.path.match(/^\/chains\/\d+$/)) return 'Detalhes da Rede'
  if (route.path === '/network/gyms/new') return 'Nova Filial'
  if (route.path.match(/^\/network\/gyms\/\d+\/edit$/)) return 'Editar Filial'
  if (route.path.startsWith('/workouts/')) return 'Detalhe do Treino'
  if (route.path.startsWith('/workout-plans/')) return 'Detalhe do Plano'
  if (route.path.startsWith('/challenges/')) return 'Detalhe do Desafio'
  return pageTitles[route.path] ?? 'Admin'
})

const userInitial = computed(() => auth.user?.name?.[0]?.toUpperCase() ?? 'A')

const currentDate = computed(() => {
  return new Intl.DateTimeFormat('pt-BR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  }).format(new Date())
})

</script>
