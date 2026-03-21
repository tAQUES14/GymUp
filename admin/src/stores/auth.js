import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../services/api.js'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('admin_token') || null)
  const user  = ref(JSON.parse(localStorage.getItem('admin_user') || 'null'))

  const isAuthenticated = computed(() => !!token.value && !!user.value)
  const isSuperAdmin    = computed(() => user.value?.role === 'super_admin')
  const isGymAdmin      = computed(() => user.value?.role === 'gym_admin')
  const isTrainer       = computed(() => user.value?.role === 'trainer')

  async function login(email, password) {
    const { data } = await api.post('/login', { email, password })

    const allowedRoles = ['super_admin', 'gym_admin', 'trainer']
    if (!allowedRoles.includes(data.user?.role)) {
      throw new Error('Acesso negado. Somente administradores e trainers podem acessar este painel.')
    }

    token.value = data.token
    user.value  = data.user

    localStorage.setItem('admin_token', data.token)
    localStorage.setItem('admin_user', JSON.stringify(data.user))
  }

  async function logout() {
    try {
      await api.post('/logout')
    } catch {
      // silencioso — limpa estado local de qualquer forma
    }
    token.value = null
    user.value  = null
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_user')
  }

  return { token, user, isAuthenticated, isSuperAdmin, isGymAdmin, isTrainer, login, logout }
})
