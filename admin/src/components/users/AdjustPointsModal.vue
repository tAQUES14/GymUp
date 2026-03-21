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

        <div class="relative z-10 bg-white rounded-2xl shadow-2xl w-full max-w-sm flex flex-col">

          <!-- Header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <div>
              <h2 class="text-sm font-bold text-slate-900">Ajustar pontos</h2>
              <p class="text-xs text-slate-400 mt-0.5">{{ user.name }}</p>
            </div>
            <button @click="close" class="text-slate-400 hover:text-slate-600 transition-colors p-1">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Body -->
          <div class="px-6 py-5 space-y-4">

            <!-- Current balance -->
            <div class="flex items-center justify-between px-4 py-3 bg-slate-50 rounded-xl">
              <span class="text-xs text-slate-500">Saldo atual</span>
              <span class="text-base font-black text-amber-600">{{ currentBalance.toLocaleString('pt-BR') }} pts</span>
            </div>

            <!-- Operation type -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-2">Operação</label>
              <div class="grid grid-cols-2 gap-2">
                <button type="button" @click="form.type = 'add'"
                  class="flex items-center justify-center gap-2 py-2.5 rounded-xl border-2 text-sm font-semibold transition-all"
                  :class="form.type === 'add'
                    ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
                    : 'border-slate-200 text-slate-500 hover:border-slate-300'"
                >
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                  </svg>
                  Adicionar
                </button>
                <button type="button" @click="form.type = 'remove'"
                  class="flex items-center justify-center gap-2 py-2.5 rounded-xl border-2 text-sm font-semibold transition-all"
                  :class="form.type === 'remove'
                    ? 'border-red-500 bg-red-50 text-red-700'
                    : 'border-slate-200 text-slate-500 hover:border-slate-300'"
                >
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 12h14" />
                  </svg>
                  Remover
                </button>
              </div>
            </div>

            <!-- Amount -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Quantidade de pontos</label>
              <div class="flex items-center gap-2">
                <button type="button" @click="form.amount = Math.max(1, form.amount - 10)"
                  class="w-9 h-9 rounded-xl border border-slate-200 flex items-center justify-center
                         text-slate-600 hover:bg-slate-100 transition-colors font-bold flex-shrink-0">−</button>
                <input v-model.number="form.amount" type="number" min="1"
                  class="input-field flex-1 text-center text-lg font-black" />
                <button type="button" @click="form.amount += 10"
                  class="w-9 h-9 rounded-xl border border-slate-200 flex items-center justify-center
                         text-slate-600 hover:bg-slate-100 transition-colors font-bold flex-shrink-0">+</button>
              </div>
              <!-- Quick amounts -->
              <div class="flex gap-1.5 mt-2">
                <button v-for="q in quickAmounts" :key="q" type="button"
                  @click="form.amount = q"
                  class="flex-1 py-1 text-xs font-semibold rounded-lg border transition-colors"
                  :class="form.amount === q
                    ? 'border-brand-400 bg-brand-50 text-brand-700'
                    : 'border-slate-200 text-slate-500 hover:border-slate-300'"
                >
                  {{ q }}
                </button>
              </div>
            </div>

            <!-- Preview -->
            <div v-if="form.amount > 0"
              class="flex items-center justify-between px-4 py-2.5 rounded-xl border"
              :class="form.type === 'add' ? 'bg-emerald-50 border-emerald-200' : 'bg-red-50 border-red-200'"
            >
              <span class="text-xs font-semibold" :class="form.type === 'add' ? 'text-emerald-700' : 'text-red-700'">
                Novo saldo
              </span>
              <span class="text-base font-black" :class="form.type === 'add' ? 'text-emerald-700' : 'text-red-700'">
                {{ newBalance.toLocaleString('pt-BR') }} pts
              </span>
            </div>

            <!-- Motivo -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Motivo</label>
              <input v-model="form.description" type="text"
                :placeholder="form.type === 'add' ? 'Ex: Bônus por frequência' : 'Ex: Correção de pontos'"
                class="input-field w-full" :class="{ 'border-red-400': errors.description }" />
              <p v-if="errors.description" class="text-xs text-red-500 mt-1">{{ errors.description }}</p>
            </div>

            <p v-if="apiError"
              class="text-xs text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
              {{ apiError }}
            </p>

          </div>

          <!-- Footer -->
          <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-slate-100">
            <button @click="close" class="btn-secondary">Cancelar</button>
            <button @click="submit" :disabled="saving || form.amount <= 0"
              class="inline-flex items-center gap-1.5 px-5 py-2 text-sm font-semibold rounded-lg
                     transition-colors disabled:opacity-60 disabled:cursor-not-allowed text-white"
              :class="form.type === 'add' ? 'bg-emerald-600 hover:bg-emerald-700' : 'bg-red-600 hover:bg-red-700'"
            >
              <svg v-if="saving" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
              </svg>
              {{ saving ? 'Salvando…' : (form.type === 'add' ? `Adicionar ${form.amount} pts` : `Remover ${form.amount} pts`) }}
            </button>
          </div>

        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import api from '../../services/api.js'

const props = defineProps({
  modelValue: { type: Boolean, required: true },
  user:       { type: Object,  required: true },
})
const emit = defineEmits(['update:modelValue', 'saved'])

const quickAmounts = [50, 100, 200, 500]

const form = ref({ type: 'add', amount: 100, description: '' })
const saving   = ref(false)
const apiError = ref('')
const errors   = ref({})

const currentBalance = computed(() => props.user.points_balance ?? 0)
const newBalance = computed(() => {
  const delta = form.value.type === 'add' ? form.value.amount : -form.value.amount
  return Math.max(0, currentBalance.value + delta)
})

watch(() => props.modelValue, (open) => {
  if (!open) return
  apiError.value = ''
  errors.value   = {}
  form.value = { type: 'add', amount: 100, description: '' }
})

function close() {
  if (!saving.value) emit('update:modelValue', false)
}

function validate() {
  const e = {}
  if (!form.value.description?.trim()) e.description = 'Informe o motivo do ajuste.'
  if (!form.value.amount || form.value.amount <= 0) e.amount = 'Informe uma quantidade válida.'
  errors.value = e
  return Object.keys(e).length === 0
}

async function submit() {
  apiError.value = ''
  if (!validate()) return
  saving.value = true
  try {
    const points = form.value.type === 'add' ? form.value.amount : -form.value.amount
    const { data } = await api.post(`/admin/users/${props.user.id}/adjust-points`, {
      points,
      description: form.value.description,
    })
    emit('saved', { points_balance: data.points_balance })
    emit('update:modelValue', false)
  } catch (e) {
    apiError.value = e.response?.data?.message ?? 'Erro ao ajustar pontos.'
  } finally {
    saving.value = false
  }
}
</script>
