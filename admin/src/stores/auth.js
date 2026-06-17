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
  const isStaff         = computed(() => isAuthenticated.value && !isSuperAdmin.value && !isGymAdmin.value)

  function hasPermission(permission) {
    if (!user.value) return false
    if (user.value.role === 'super_admin') return true
    if (user.value.role === 'gym_admin') return true
    return (user.value.permissions ?? []).includes(permission)
  }

  async function login(email, password) {
    const { data } = await api.post('/login', { email, password })

    const allowedRoles = ['super_admin', 'network_admin', 'gym_admin', 'trainer']
    if (!allowedRoles.includes(data.user?.role)) {
      throw new Error('Acesso negado. Este painel é restrito a administradores e treinadores. Para uso pessoal, baixe o app GymUp.')
    }

    token.value = data.token
    user.value  = data.user

    localStorage.setItem('admin_token', data.token)
    localStorage.setItem('admin_user', JSON.stringify(data.user))

    await refreshMe()

    return loginRedirect(user.value?.role)
  }

  function loginRedirect(role) {
    if (role === 'network_admin') return '/network/dashboard'
    if (role === 'super_admin')   return '/chains'
    return '/dashboard'
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

  async function forgotPassword(email) {
    await api.post('/auth/forgot-password', { email })
  }

  async function resetPassword({ token, email, password }) {
    await api.post('/auth/reset-password', {
      token,
      email,
      password,
      password_confirmation: password,
    })
  }

  async function refreshMe() {
    try {
      const { data } = await api.get('/me')
      user.value = data
      localStorage.setItem('admin_user', JSON.stringify(data))
    } catch {
      // ignora erros silenciosamente
    }
  }

  async function updateAvatar(file) {
    const formData = new FormData()
    formData.append('avatar', file)

    await api.post('/profile/avatar', formData)
    await refreshMe()
  }

  return {
    token,
    user,
    isAuthenticated,
    isSuperAdmin,
    isGymAdmin,
    isTrainer,
    isStaff,
    hasPermission,
    login,
    logout,
    forgotPassword,
    resetPassword,
    refreshMe,
    updateAvatar,
    loginRedirect,
  }
})
