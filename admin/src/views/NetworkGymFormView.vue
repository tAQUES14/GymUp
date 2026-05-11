<template>
  <div class="max-w-xl">

    <button @click="$router.push('/network/gyms')"
      class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors mb-5">
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
      </svg>
      Filiais
    </button>

    <div class="mb-6">
      <h1 class="text-2xl font-bold text-slate-900 tracking-tight">
        {{ isEdit ? 'Editar filial' : 'Nova filial' }}
      </h1>
    </div>

    <div v-if="loadingGym" class="card p-6 animate-pulse space-y-4">
      <div class="h-4 w-32 bg-slate-100 rounded" />
      <div class="h-9 bg-slate-100 rounded" />
    </div>

    <form v-else @submit.prevent="submit" class="card p-6 space-y-5">

      <!-- Name -->
      <div>
        <label class="block text-sm font-semibold text-slate-700 mb-1.5">Nome <span class="text-red-500">*</span></label>
        <input v-model="form.name" type="text" placeholder="Ex: Filial Centro"
          class="w-full px-3.5 py-2.5 text-sm border rounded-lg focus:outline-none focus:ring-2 transition-colors"
          :class="errors.name ? 'border-red-400 focus:ring-red-500/20' : 'border-slate-200 focus:ring-brand-500/30 focus:border-brand-400'" />
        <p v-if="errors.name" class="text-xs text-red-500 mt-1">{{ errors.name }}</p>
      </div>

      <!-- City -->
      <div>
        <label class="block text-sm font-semibold text-slate-700 mb-1.5">Cidade</label>
        <input v-model="form.city" type="text" placeholder="Ex: São Paulo"
          class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors" />
      </div>

      <!-- Address -->
      <div>
        <label class="block text-sm font-semibold text-slate-700 mb-1.5">Endereço</label>
        <input v-model="form.address" type="text" placeholder="Ex: Av. Paulista, 1000"
          class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors" />
      </div>

      <!-- API error -->
      <div v-if="submitError" class="flex items-center gap-2 p-3 rounded-lg bg-red-50 border border-red-200">
        <svg class="w-4 h-4 text-red-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
        <p class="text-xs text-red-600">{{ submitError }}</p>
      </div>

      <div class="flex items-center justify-end gap-3 pt-2 border-t border-slate-100">
        <button type="button" @click="$router.push('/network/gyms')"
          class="px-4 py-2 text-sm font-semibold text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
          Cancelar
        </button>
        <button type="submit" :disabled="submitting"
          class="px-5 py-2 text-sm font-semibold text-white bg-brand-600 rounded-lg hover:bg-brand-700 transition-colors disabled:opacity-60 shadow-sm">
          {{ submitting ? 'Salvando…' : 'Salvar' }}
        </button>
      </div>

    </form>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import api from '../services/api.js'

const router = useRouter()
const route  = useRoute()

const id     = route.params.id
const isEdit = !!id && id !== 'new'

const form        = ref({ name: '', city: '', address: '' })
const errors      = ref({})
const submitError = ref(null)
const submitting  = ref(false)
const loadingGym  = ref(isEdit)

onMounted(async () => {
  if (!isEdit) return
  try {
    const { data } = await api.get('/network/gyms')
    const gym = data.gyms.find(g => g.id === parseInt(id))
    if (!gym) { router.push('/network/gyms'); return }
    form.value = { name: gym.name, city: gym.city ?? '', address: gym.address ?? '' }
  } catch {
    router.push('/network/gyms')
  } finally {
    loadingGym.value = false
  }
})

async function submit() {
  errors.value      = {}
  submitError.value = null

  if (!form.value.name.trim()) {
    errors.value.name = 'Nome é obrigatório.'
    return
  }

  submitting.value = true
  try {
    const payload = {
      name:    form.value.name.trim(),
      city:    form.value.city.trim() || null,
      address: form.value.address.trim() || null,
    }

    if (isEdit) {
      await api.put(`/network/gyms/${id}`, payload)
    } else {
      await api.post('/network/gyms', payload)
    }
    router.push('/network/gyms')
  } catch (e) {
    const apiErrors = e.response?.data?.errors
    if (apiErrors) {
      Object.entries(apiErrors).forEach(([k, v]) => { errors.value[k] = Array.isArray(v) ? v[0] : v })
    } else {
      submitError.value = e.response?.data?.message ?? 'Erro ao salvar filial.'
    }
  } finally {
    submitting.value = false
  }
}
</script>
