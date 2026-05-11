<template>
  <header class="fixed top-0 right-0 left-64 h-16 bg-white border-b border-slate-100 z-20 flex items-center px-6 gap-4">

    <!-- Breadcrumb / Page title -->
    <div class="flex items-center gap-2 text-sm">
      <span class="text-slate-400">GymUp</span>
      <svg class="w-4 h-4 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
      </svg>
      <span class="font-semibold text-slate-800">{{ pageTitle }}</span>
    </div>

    <!-- Spacer -->
    <div class="flex-1" />

    <!-- Date -->
    <span class="text-xs text-slate-400 hidden sm:block">{{ currentDate }}</span>

    <!-- Gym Switcher (trainer com múltiplas filiais) -->
    <GymSwitcher />

    <!-- Divider -->
    <div class="w-px h-5 bg-slate-200" />

    <!-- User pill -->
    <div class="flex items-center gap-2.5">
      <div class="w-7 h-7 rounded-full bg-brand-600 flex items-center justify-center">
        <span class="text-white text-xs font-bold">{{ userInitial }}</span>
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
