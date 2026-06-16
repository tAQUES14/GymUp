<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-brand-900 to-slate-900 flex items-center justify-center p-4">

    <!-- Card -->
    <div class="w-full max-w-sm">

      <!-- Brand -->
      <div class="text-center mb-8">
        <div class="inline-flex items-center justify-center w-14 h-14 bg-brand-600 rounded-2xl mb-4 shadow-lg shadow-brand-600/30">
          <svg class="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
          </svg>
        </div>
        <h1 class="text-2xl font-bold text-white tracking-tight">GymUp Admin</h1>
        <p class="text-slate-400 text-sm mt-1">Painel Administrativo</p>
      </div>

      <!-- Form card -->
      <div class="bg-white rounded-2xl shadow-2xl p-8">
        <h2 class="text-lg font-semibold text-slate-800 mb-1">Entrar na sua conta</h2>
        <p class="text-sm text-slate-500 mb-6">Acesso restrito a administradores.</p>

        <div v-if="verified" class="mb-4 flex items-start gap-2 p-3 bg-emerald-50 border border-emerald-100 rounded-lg">
          <svg class="w-4 h-4 text-emerald-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
          </svg>
          <p class="text-sm text-emerald-700">Email confirmado. Agora voce ja pode entrar.</p>
        </div>

        <form @submit.prevent="handleLogin" class="space-y-4">

          <!-- Email -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1.5">E-mail</label>
            <input
              v-model="form.email"
              type="email"
              placeholder="seu@email.com"
              autocomplete="email"
              required
              class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg
                     focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent
                     placeholder-slate-400 transition"
            />
          </div>

          <!-- Password -->
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1.5">Senha</label>
            <input
              v-model="form.password"
              type="password"
              placeholder="••••••••"
              autocomplete="current-password"
              required
              class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg
                     focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent
                     placeholder-slate-400 transition"
            />
          </div>

          <div class="flex justify-end">
            <RouterLink
              to="/forgot-password"
              class="text-sm font-semibold text-brand-600 hover:text-brand-700"
            >
              Esqueci minha senha
            </RouterLink>
          </div>

          <!-- Error -->
          <div v-if="error" class="flex items-start gap-2 p-3 bg-red-50 border border-red-100 rounded-lg">
            <svg class="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
            </svg>
            <p class="text-sm text-red-600">{{ error }}</p>
          </div>

          <!-- Submit -->
          <button
            type="submit"
            :disabled="loading"
            class="w-full flex items-center justify-center gap-2 py-2.5 bg-brand-600 hover:bg-brand-700
                   active:bg-brand-800 text-white font-semibold text-sm rounded-lg transition
                   focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2
                   disabled:opacity-60 disabled:cursor-not-allowed"
          >
            <svg v-if="loading" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
            </svg>
            {{ loading ? 'Entrando…' : 'Entrar' }}
          </button>

        </form>
      </div>

    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'

const auth   = useAuthStore()
const router = useRouter()
const route  = useRoute()

const form    = reactive({ email: '', password: '' })
const loading = ref(false)
const error   = ref('')
const verified = ref(route.query.verified === '1')

async function handleLogin() {
  error.value   = ''
  loading.value = true
  try {
    const dest = await auth.login(form.email, form.password)
    router.push(dest)
  } catch (e) {
    error.value = e.response?.data?.message ?? e.message ?? 'Erro ao fazer login.'
  } finally {
    loading.value = false
  }
}
</script>
