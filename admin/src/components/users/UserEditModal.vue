<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <div v-if="modelValue" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="close" />

        <div class="relative z-10 bg-white rounded-2xl shadow-2xl w-full max-w-md flex flex-col">

          <!-- Header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0"
                   :style="{ backgroundColor: avatarColor(user.name) }">
                {{ initials(user.name) }}
              </div>
              <div>
                <h2 class="text-sm font-bold text-slate-900 leading-tight">Editar aluno</h2>
                <p class="text-xs text-slate-400">{{ user.name }}</p>
              </div>
            </div>
            <button @click="close" class="text-slate-400 hover:text-slate-600 transition-colors p-1">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Body -->
          <div class="px-6 py-5 space-y-4">

            <!-- Nome -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Nome completo</label>
              <input v-model="form.name" type="text" class="input-field w-full"
                :class="{ 'border-red-400': errors.name }" />
              <p v-if="errors.name" class="text-xs text-red-500 mt-1">{{ errors.name }}</p>
            </div>

            <!-- Email -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">E-mail</label>
              <input v-model="form.email" type="email" class="input-field w-full"
                :class="{ 'border-red-400': errors.email }" />
              <p v-if="errors.email" class="text-xs text-red-500 mt-1">{{ errors.email }}</p>
            </div>

            <!-- Nascimento -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">
                Data de nascimento <span class="text-slate-400 font-normal">— opcional</span>
              </label>
              <input v-model="form.birth_date" type="date" class="input-field w-full" />
            </div>

            <!-- Altura + Peso -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold text-slate-700 mb-1.5">Altura (cm)</label>
                <input v-model.number="form.height" type="number" min="100" max="250"
                  placeholder="175" class="input-field w-full" />
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-700 mb-1.5">Peso (kg)</label>
                <input v-model.number="form.weight" type="number" min="20" max="300"
                  placeholder="70" class="input-field w-full" />
              </div>
            </div>

            <p v-if="apiError"
              class="flex items-center gap-2 text-xs text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
              {{ apiError }}
            </p>

          </div>

          <!-- Footer -->
          <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-slate-100">
            <button @click="close" class="btn-secondary">Cancelar</button>
            <button @click="submit" :disabled="saving"
              class="inline-flex items-center gap-1.5 px-5 py-2 bg-brand-600 text-white text-sm
                     font-semibold rounded-lg hover:bg-brand-700 transition-colors
                     disabled:opacity-60 disabled:cursor-not-allowed">
              <svg v-if="saving" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
              </svg>
              {{ saving ? 'Salvando…' : 'Salvar alterações' }}
            </button>
          </div>

        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, watch } from 'vue'
import api from '../../services/api.js'

const props = defineProps({
  modelValue: { type: Boolean, required: true },
  user:       { type: Object,  required: true },
})
const emit = defineEmits(['update:modelValue', 'saved'])

const form     = ref({})
const saving   = ref(false)
const apiError = ref('')
const errors   = ref({})

watch(() => props.modelValue, (open) => {
  if (!open) return
  apiError.value = ''
  errors.value   = {}
  form.value = {
    name:       props.user.name       ?? '',
    email:      props.user.email      ?? '',
    birth_date: props.user.birth_date ?? '',
    height:     props.user.height     ?? '',
    weight:     props.user.weight     ?? '',
  }
})

function close() {
  if (!saving.value) emit('update:modelValue', false)
}

function validate() {
  const e = {}
  if (!form.value.name?.trim()) e.name = 'Nome é obrigatório.'
  if (!form.value.email?.trim()) e.email = 'E-mail é obrigatório.'
  else if (!/\S+@\S+\.\S+/.test(form.value.email)) e.email = 'E-mail inválido.'
  errors.value = e
  return Object.keys(e).length === 0
}

async function submit() {
  apiError.value = ''
  if (!validate()) return
  saving.value = true
  try {
    const payload = { ...form.value }
    if (!payload.height) delete payload.height
    if (!payload.weight) delete payload.weight
    if (!payload.birth_date) delete payload.birth_date

    await api.put(`/admin/users/${props.user.id}`, payload)
    emit('saved', { ...payload })
    emit('update:modelValue', false)
  } catch (e) {
    apiError.value = e.response?.data?.message ?? 'Erro ao salvar alterações.'
  } finally {
    saving.value = false
  }
}

function initials(name) {
  const parts = (name ?? '?').trim().split(/\s+/)
  return parts.length >= 2
    ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
    : (parts[0][0] ?? '?').toUpperCase()
}
function avatarColor(name) {
  const colors = ['#6366f1','#8b5cf6','#ec4899','#f59e0b','#10b981','#3b82f6','#ef4444','#14b8a6']
  let h = 0
  for (const c of (name ?? '')) h = (h * 31 + c.charCodeAt(0)) & 0xffffffff
  return colors[Math.abs(h) % colors.length]
}
</script>
