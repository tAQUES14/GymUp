<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-brand-900 to-slate-900 flex items-center justify-center p-4">
    <div class="w-full max-w-sm">
      <AuthBrand />

      <div class="bg-white rounded-2xl shadow-2xl p-8">
        <template v-if="sent">
          <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-500 flex items-center justify-center mb-4">
            <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21.75 6.75v10.5A2.25 2.25 0 0 1 19.5 19.5h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0-9.75 6.75L2.25 6.75" />
            </svg>
          </div>
          <h2 class="text-lg font-semibold text-slate-800 mb-1">Confira seu email</h2>
          <p class="text-sm text-slate-500 mb-6">Se o email existir, enviaremos um link para criar uma nova senha.</p>
          <RouterLink to="/login" class="block w-full text-center py-2.5 bg-brand-600 hover:bg-brand-700 text-white font-semibold text-sm rounded-lg transition">
            Voltar ao login
          </RouterLink>
        </template>

        <template v-else>
          <h2 class="text-lg font-semibold text-slate-800 mb-1">Recuperar senha</h2>
          <p class="text-sm text-slate-500 mb-6">Informe seu email para receber o link de redefinicao.</p>

          <form @submit.prevent="submit" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1.5">E-mail</label>
              <input
                v-model="email"
                type="email"
                required
                autocomplete="email"
                placeholder="seu@email.com"
                class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent placeholder-slate-400 transition"
              />
            </div>

            <div v-if="error" class="p-3 bg-red-50 border border-red-100 rounded-lg text-sm text-red-600">{{ error }}</div>

            <button
              type="submit"
              :disabled="loading"
              class="w-full py-2.5 bg-brand-600 hover:bg-brand-700 text-white font-semibold text-sm rounded-lg transition disabled:opacity-60"
            >
              {{ loading ? 'Enviando...' : 'Enviar link' }}
            </button>

            <RouterLink to="/login" class="block text-center text-sm font-semibold text-slate-600 hover:text-slate-800">
              Voltar ao login
            </RouterLink>
          </form>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'
import AuthBrand from '../components/auth/AuthBrand.vue'

const auth = useAuthStore()
const email = ref('')
const loading = ref(false)
const sent = ref(false)
const error = ref('')

async function submit() {
  error.value = ''
  loading.value = true
  try {
    await auth.forgotPassword(email.value)
    sent.value = true
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Nao foi possivel enviar o email.'
  } finally {
    loading.value = false
  }
}
</script>
