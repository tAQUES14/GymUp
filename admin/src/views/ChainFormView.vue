<template>
  <div class="max-w-xl">

    <!-- Breadcrumb -->
    <button @click="$router.push('/chains')"
      class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors mb-5">
      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
      </svg>
      Redes
    </button>

    <div class="mb-6">
      <h1 class="text-2xl font-bold text-slate-900 tracking-tight">
        {{ isEdit ? 'Editar rede' : 'Nova rede' }}
      </h1>
    </div>

    <!-- Loading (edit mode) -->
    <div v-if="loadingChain" class="card p-6 animate-pulse space-y-4">
      <div class="h-4 w-32 bg-slate-100 rounded" />
      <div class="h-9 bg-slate-100 rounded" />
      <div class="h-4 w-24 bg-slate-100 rounded mt-2" />
      <div class="h-9 bg-slate-100 rounded" />
    </div>

    <!-- Form -->
    <form v-else @submit.prevent="submit" class="card p-6 space-y-5">

      <!-- Name -->
      <div>
        <label class="block text-sm font-semibold text-slate-700 mb-1.5">Nome da rede <span class="text-red-500">*</span></label>
        <input v-model="form.name" @input="onNameInput" type="text" placeholder="Ex: SmartFit Brasil"
          class="w-full px-3.5 py-2.5 text-sm border rounded-lg focus:outline-none focus:ring-2 transition-colors"
          :class="errors.name ? 'border-red-400 focus:ring-red-500/20' : 'border-slate-200 focus:ring-brand-500/30 focus:border-brand-400'" />
        <p v-if="errors.name" class="text-xs text-red-500 mt-1">{{ errors.name }}</p>
      </div>

      <!-- Slug -->
      <div>
        <label class="block text-sm font-semibold text-slate-700 mb-1.5">Slug <span class="text-slate-400 font-normal">(URL amigável)</span></label>
        <input v-model="form.slug" type="text" placeholder="ex: smartfit-brasil"
          class="w-full px-3.5 py-2.5 text-sm font-mono border rounded-lg focus:outline-none focus:ring-2 transition-colors"
          :class="errors.slug ? 'border-red-400 focus:ring-red-500/20' : 'border-slate-200 focus:ring-brand-500/30 focus:border-brand-400'" />
        <p class="text-xs text-slate-400 mt-1">Apenas letras minúsculas, números e hífens. Se vazio, gerado automaticamente.</p>
        <p v-if="errors.slug" class="text-xs text-red-500 mt-1">{{ errors.slug }}</p>
      </div>

      <!-- Logo URL -->
      <div>
        <label class="block text-sm font-semibold text-slate-700 mb-1.5">Logo URL <span class="text-slate-400 font-normal">(opcional)</span></label>
        <input v-model="form.logo_url" type="url" placeholder="https://..."
          class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors" />
        <div v-if="form.logo_url" class="mt-2 flex items-center gap-2">
          <img :src="form.logo_url" alt="Preview" class="w-10 h-10 rounded-lg object-cover border border-slate-200" @error="logoError = true" />
          <p v-if="logoError" class="text-xs text-red-500">URL inválida</p>
        </div>
      </div>

      <!-- API error -->
      <div v-if="submitError" class="flex items-center gap-2 p-3 rounded-lg bg-red-50 border border-red-200">
        <svg class="w-4 h-4 text-red-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
        <p class="text-xs text-red-600">{{ submitError }}</p>
      </div>

      <!-- Actions -->
      <div class="flex items-center justify-end gap-3 pt-2 border-t border-slate-100">
        <button type="button" @click="$router.push('/chains')"
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
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import api from '../services/api.js'

const router = useRouter()
const route  = useRoute()

const id      = route.params.id
const isEdit  = !!id && id !== 'new'

const form = ref({ name: '', slug: '', logo_url: '' })
const errors       = ref({})
const submitError  = ref(null)
const submitting   = ref(false)
const loadingChain = ref(isEdit)
const logoError    = ref(false)
let slugTouched    = false

onMounted(async () => {
  if (!isEdit) return
  try {
    const { data } = await api.get(`/super/chains/${id}`)
    form.value = { name: data.name, slug: data.slug, logo_url: data.logo_url ?? '' }
  } catch {
    router.push('/chains')
  } finally {
    loadingChain.value = false
  }
})

function onNameInput() {
  if (!slugTouched || !form.value.slug) {
    form.value.slug = form.value.name
      .toLowerCase()
      .normalize('NFD').replace(/[̀-ͯ]/g, '')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '')
    slugTouched = false
  }
}

async function submit() {
  errors.value     = {}
  submitError.value = null

  if (!form.value.name.trim()) {
    errors.value.name = 'Nome é obrigatório.'
    return
  }
  if (form.value.slug && !/^[a-z0-9-]+$/.test(form.value.slug)) {
    errors.value.slug = 'Apenas letras minúsculas, números e hífens.'
    return
  }

  submitting.value = true
  try {
    const payload = {
      name:     form.value.name.trim(),
      slug:     form.value.slug.trim() || undefined,
      logo_url: form.value.logo_url.trim() || null,
    }

    if (isEdit) {
      await api.put(`/super/chains/${id}`, payload)
      router.push(`/chains/${id}`)
    } else {
      const { data } = await api.post('/super/chains', payload)
      router.push(`/chains/${data.chain.id}`)
    }
  } catch (e) {
    const apiErrors = e.response?.data?.errors
    if (apiErrors) {
      Object.entries(apiErrors).forEach(([k, v]) => {
        errors.value[k] = Array.isArray(v) ? v[0] : v
      })
    } else {
      submitError.value = e.response?.data?.message ?? 'Erro ao salvar rede.'
    }
  } finally {
    submitting.value = false
  }
}
</script>
