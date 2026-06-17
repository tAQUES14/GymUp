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
    <div class="relative">
      <button
        type="button"
        class="flex items-center gap-2.5 rounded-full px-1.5 py-1 hover:bg-slate-50 transition"
        @click="profileOpen = !profileOpen"
      >
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
      </button>

      <div
        v-if="profileOpen"
        class="absolute right-0 top-12 w-72 rounded-2xl border border-slate-100 bg-white p-4 shadow-xl shadow-slate-900/10"
      >
        <div class="flex items-center gap-3">
          <div class="w-12 h-12 rounded-full bg-brand-600 flex items-center justify-center overflow-hidden ring-4 ring-brand-50">
            <img
              v-if="auth.user?.avatar_url"
              :src="auth.user.avatar_url"
              :alt="auth.user?.name ?? 'Perfil'"
              class="w-full h-full object-cover"
            />
            <span v-else class="text-white text-sm font-bold">{{ userInitial }}</span>
          </div>
          <div class="min-w-0">
            <p class="text-sm font-bold text-slate-900 truncate">{{ auth.user?.name }}</p>
            <p class="text-xs text-slate-400 truncate">{{ auth.user?.email }}</p>
          </div>
        </div>

        <label class="mt-4 flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-slate-200 px-3 py-2.5 text-xs font-bold text-brand-600 hover:bg-brand-50 transition">
          <input type="file" accept="image/*" class="hidden" @change="onAvatarSelected" />
          <span v-if="avatarUploading">Enviando foto...</span>
          <span v-else>Alterar foto do perfil</span>
        </label>
      </div>
    </div>

  </header>
</template>

<script setup>
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '../../stores/auth.js'
import GymSwitcher from './GymSwitcher.vue'

const auth  = useAuthStore()
const route = useRoute()
const profileOpen = ref(false)
const avatarUploading = ref(false)

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

async function onAvatarSelected(event) {
  const file = event.target.files?.[0]
  event.target.value = ''
  if (!file || avatarUploading.value) return

  avatarUploading.value = true
  try {
    await auth.updateAvatar(file)
    profileOpen.value = false
  } finally {
    avatarUploading.value = false
  }
}
</script>
