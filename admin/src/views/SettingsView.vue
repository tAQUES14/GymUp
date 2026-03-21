<template>
  <div>

    <!-- Page header -->
    <div class="mb-8">
      <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Configurações</h1>
      <p class="text-slate-500 text-sm mt-1">Gerencie os dados da academia e da sua conta.</p>
    </div>

    <!-- Loading skeleton -->
    <template v-if="loading">
      <div class="space-y-5">
        <div v-for="n in 3" :key="n" class="card p-6 animate-pulse">
          <div class="h-4 bg-slate-100 rounded w-40 mb-5" />
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div v-for="f in 4" :key="f" class="space-y-2">
              <div class="h-3 bg-slate-100 rounded w-24" />
              <div class="h-9 bg-slate-100 rounded" />
            </div>
          </div>
        </div>
      </div>
    </template>

    <!-- Error state -->
    <div v-else-if="loadError" class="card p-8 text-center">
      <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mb-3">
        <svg class="w-6 h-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar configurações</p>
      <p class="text-xs text-slate-400 mb-4">{{ loadError }}</p>
      <button @click="loadData" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Content -->
    <template v-else>
      <div class="space-y-5">

        <!-- ── Dados da academia ──────────────────────────────────────────── -->
        <div v-if="gym" class="card p-6">
          <div class="flex items-center gap-3 mb-6">
            <div class="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 21h16.5M4.5 3h15M5.25 3v18m13.5-18v18M9 6.75h1.5m-1.5 3h1.5m-1.5 3h1.5m3-6H15m-1.5 3H15m-1.5 3H15M9 21v-3.375c0-.621.504-1.125 1.125-1.125h3.75c.621 0 1.125.504 1.125 1.125V21" />
              </svg>
            </div>
            <div>
              <h2 class="text-sm font-semibold text-slate-900">Dados da academia</h2>
              <p class="text-xs text-slate-400">Nome, contato e endereço</p>
            </div>
          </div>

          <form @submit.prevent="saveGym" class="space-y-4">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1.5">Nome da academia <span class="text-red-400">*</span></label>
                <input
                  v-model="gymForm.name"
                  type="text"
                  class="input w-full"
                  placeholder="Ex: GymUp Centro"
                  required
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1.5">E-mail</label>
                <input
                  v-model="gymForm.email"
                  type="email"
                  class="input w-full"
                  placeholder="contato@academia.com"
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1.5">Telefone</label>
                <input
                  v-model="gymForm.phone"
                  type="text"
                  class="input w-full"
                  placeholder="(11) 99999-9999"
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1.5">Endereço</label>
                <input
                  v-model="gymForm.address"
                  type="text"
                  class="input w-full"
                  placeholder="Rua, número, bairro"
                />
              </div>
            </div>

            <!-- Feedback -->
            <div v-if="gymMsg" :class="['text-xs font-medium px-3 py-2 rounded-lg', gymMsg.ok ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700']">
              {{ gymMsg.text }}
            </div>

            <div class="flex justify-end pt-1">
              <button type="submit" class="btn-primary text-sm" :disabled="gymSaving">
                <svg v-if="gymSaving" class="animate-spin w-4 h-4 mr-1.5 inline-block" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
                {{ gymSaving ? 'Salvando…' : 'Salvar alterações' }}
              </button>
            </div>
          </form>
        </div>

        <!-- ── Minha conta ────────────────────────────────────────────────── -->
        <div class="card p-6">
          <div class="flex items-center gap-3 mb-6">
            <div class="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-4 h-4 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
              </svg>
            </div>
            <div>
              <h2 class="text-sm font-semibold text-slate-900">Minha conta</h2>
              <p class="text-xs text-slate-400">Nome e e-mail de acesso</p>
            </div>
          </div>

          <form @submit.prevent="saveAccount" class="space-y-4">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1.5">Nome <span class="text-red-400">*</span></label>
                <input
                  v-model="accountForm.name"
                  type="text"
                  class="input w-full"
                  placeholder="Seu nome"
                  required
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1.5">E-mail <span class="text-red-400">*</span></label>
                <input
                  v-model="accountForm.email"
                  type="email"
                  class="input w-full"
                  placeholder="seu@email.com"
                  required
                />
              </div>
            </div>

            <!-- Feedback -->
            <div v-if="accountMsg" :class="['text-xs font-medium px-3 py-2 rounded-lg', accountMsg.ok ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700']">
              {{ accountMsg.text }}
            </div>

            <div class="flex justify-end pt-1">
              <button type="submit" class="btn-primary text-sm" :disabled="accountSaving">
                <svg v-if="accountSaving" class="animate-spin w-4 h-4 mr-1.5 inline-block" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
                {{ accountSaving ? 'Salvando…' : 'Salvar conta' }}
              </button>
            </div>
          </form>
        </div>

        <!-- ── Alterar senha ──────────────────────────────────────────────── -->
        <div class="card p-6">
          <div class="flex items-center gap-3 mb-6">
            <div class="w-8 h-8 rounded-lg bg-amber-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-4 h-4 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
              </svg>
            </div>
            <div>
              <h2 class="text-sm font-semibold text-slate-900">Alterar senha</h2>
              <p class="text-xs text-slate-400">Recomendamos usar uma senha forte</p>
            </div>
          </div>

          <form @submit.prevent="savePassword" class="space-y-4">
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1.5">Senha atual <span class="text-red-400">*</span></label>
                <input
                  v-model="passwordForm.current_password"
                  type="password"
                  class="input w-full"
                  placeholder="••••••••"
                  required
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1.5">Nova senha <span class="text-red-400">*</span></label>
                <input
                  v-model="passwordForm.new_password"
                  type="password"
                  class="input w-full"
                  placeholder="Min. 8 caracteres"
                  required
                  minlength="8"
                />
              </div>
              <div>
                <label class="block text-xs font-medium text-slate-600 mb-1.5">Confirmar nova senha <span class="text-red-400">*</span></label>
                <input
                  v-model="passwordForm.new_password_confirmation"
                  type="password"
                  class="input w-full"
                  placeholder="••••••••"
                  required
                />
              </div>
            </div>

            <!-- Feedback -->
            <div v-if="passwordMsg" :class="['text-xs font-medium px-3 py-2 rounded-lg', passwordMsg.ok ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700']">
              {{ passwordMsg.text }}
            </div>

            <div class="flex justify-end pt-1">
              <button type="submit" class="btn-primary text-sm" :disabled="passwordSaving">
                <svg v-if="passwordSaving" class="animate-spin w-4 h-4 mr-1.5 inline-block" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
                {{ passwordSaving ? 'Alterando…' : 'Alterar senha' }}
              </button>
            </div>
          </form>
        </div>

      </div>
    </template>

  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useAuthStore } from '../stores/auth.js'
import api from '../services/api.js'

const auth = useAuthStore()

const loading   = ref(true)
const loadError = ref('')
const gym       = ref(null)

const gymForm     = reactive({ name: '', email: '', phone: '', address: '' })
const accountForm = reactive({ name: '', email: '' })
const passwordForm = reactive({ current_password: '', new_password: '', new_password_confirmation: '' })

const gymSaving      = ref(false)
const accountSaving  = ref(false)
const passwordSaving = ref(false)

const gymMsg      = ref(null)
const accountMsg  = ref(null)
const passwordMsg = ref(null)

function flash(target, ok, text) {
  target.value = { ok, text }
  setTimeout(() => { target.value = null }, 4000)
}

async function loadData() {
  loading.value   = true
  loadError.value = ''
  try {
    const { data } = await api.get('/admin/settings')
    gym.value = data.gym

    if (data.gym) {
      gymForm.name    = data.gym.name    ?? ''
      gymForm.email   = data.gym.email   ?? ''
      gymForm.phone   = data.gym.phone   ?? ''
      gymForm.address = data.gym.address ?? ''
    }

    accountForm.name  = data.account.name  ?? ''
    accountForm.email = data.account.email ?? ''
  } catch (e) {
    loadError.value = e.response?.data?.message ?? 'Erro ao carregar configurações.'
  } finally {
    loading.value = false
  }
}

async function saveGym() {
  gymSaving.value = true
  try {
    await api.put('/admin/settings/gym', gymForm)
    flash(gymMsg, true, 'Dados da academia atualizados com sucesso.')
  } catch (e) {
    const msg = firstValidationError(e) ?? e.response?.data?.message ?? 'Erro ao salvar.'
    flash(gymMsg, false, msg)
  } finally {
    gymSaving.value = false
  }
}

async function saveAccount() {
  accountSaving.value = true
  try {
    const { data } = await api.put('/admin/settings/account', accountForm)
    // Sync auth store so the header name updates
    if (auth.user) {
      auth.user = { ...auth.user, name: data.account.name, email: data.account.email }
      localStorage.setItem('admin_user', JSON.stringify(auth.user))
    }
    flash(accountMsg, true, 'Conta atualizada com sucesso.')
  } catch (e) {
    const msg = firstValidationError(e) ?? e.response?.data?.message ?? 'Erro ao salvar.'
    flash(accountMsg, false, msg)
  } finally {
    accountSaving.value = false
  }
}

async function savePassword() {
  if (passwordForm.new_password !== passwordForm.new_password_confirmation) {
    flash(passwordMsg, false, 'As senhas não coincidem.')
    return
  }
  passwordSaving.value = true
  try {
    await api.put('/admin/settings/password', passwordForm)
    passwordForm.current_password          = ''
    passwordForm.new_password              = ''
    passwordForm.new_password_confirmation = ''
    flash(passwordMsg, true, 'Senha alterada com sucesso.')
  } catch (e) {
    const msg = firstValidationError(e) ?? e.response?.data?.message ?? 'Erro ao alterar senha.'
    flash(passwordMsg, false, msg)
  } finally {
    passwordSaving.value = false
  }
}

function firstValidationError(e) {
  const errors = e.response?.data?.errors
  if (!errors) return null
  const first = Object.values(errors)[0]
  return Array.isArray(first) ? first[0] : first
}

onMounted(loadData)
</script>
