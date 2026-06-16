<template>
  <div class="min-h-screen bg-gradient-to-br from-slate-900 via-brand-900 to-slate-900 flex items-center justify-center p-4">
    <div class="w-full max-w-sm">
      <AuthBrand />

      <div class="bg-white rounded-2xl shadow-2xl p-8">
        <template v-if="done">
          <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-500 flex items-center justify-center mb-4">
            <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
            </svg>
          </div>
          <h2 class="text-lg font-semibold text-slate-800 mb-1">Senha redefinida</h2>
          <p class="text-sm text-slate-500 mb-6">Agora voce ja pode entrar usando a nova senha.</p>
          <RouterLink to="/login" class="block w-full text-center py-2.5 bg-brand-600 hover:bg-brand-700 text-white font-semibold text-sm rounded-lg transition">
            Ir para o login
          </RouterLink>
        </template>

        <template v-else>
          <h2 class="text-lg font-semibold text-slate-800 mb-1">Criar nova senha</h2>
          <p class="text-sm text-slate-500 mb-6">Use uma senha com pelo menos 6 caracteres.</p>

          <form @submit.prevent="submit" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1.5">Nova senha</label>
              <input
                v-model="password"
                type="password"
                required
                minlength="6"
                autocomplete="new-password"
                class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent transition"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-slate-700 mb-1.5">Confirmar senha</label>
              <input
                v-model="confirm"
                type="password"
                required
                minlength="6"
                autocomplete="new-password"
                class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent transition"
              />
            </div>

            <div v-if="error" class="p-3 bg-red-50 border border-red-100 rounded-lg text-sm text-red-600">{{ error }}</div>

            <button
              type="submit"
              :disabled="loading || !canSubmit"
              class="w-full py-2.5 bg-brand-600 hover:bg-brand-700 text-white font-semibold text-sm rounded-lg transition disabled:opacity-60"
            >
              {{ loading ? 'Salvando...' : 'Redefinir senha' }}
            </button>
          </form>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth.js'
import AuthBrand from '../components/auth/AuthBrand.vue'

const route = useRoute()
const auth = useAuthStore()
const password = ref('')
const confirm = ref('')
const loading = ref(false)
const done = ref(false)
const error = ref('')

const token = computed(() => String(route.query.token ?? ''))
const email = computed(() => String(route.query.email ?? ''))
const canSubmit = computed(() =>
  token.value && email.value && password.value.length >= 6 && password.value === confirm.value
)

async function submit() {
  error.value = ''

  if (!token.value || !email.value) {
    error.value = 'Link invalido. Solicite um novo email de recuperacao.'
    return
  }
  if (password.value !== confirm.value) {
    error.value = 'As senhas nao coincidem.'
    return
  }

  loading.value = true
  try {
    await auth.resetPassword({
      token: token.value,
      email: email.value,
      password: password.value,
    })
    done.value = true
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Nao foi possivel redefinir a senha.'
  } finally {
    loading.value = false
  }
}
</script>
