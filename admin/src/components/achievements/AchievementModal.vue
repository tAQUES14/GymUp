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

        <div class="relative z-10 bg-white rounded-2xl shadow-2xl w-full max-w-md flex flex-col"
             style="max-height: min(90vh, 600px)">

          <!-- Header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100 flex-shrink-0">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                   :class="form.metric === 'streak_days' ? 'bg-amber-100' : 'bg-brand-50'">
                <svg v-if="form.metric === 'streak_days'" class="w-4 h-4 text-amber-500"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round"
                    d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
                </svg>
                <svg v-else class="w-4 h-4 text-brand-600"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round"
                    d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                </svg>
              </div>
              <h2 class="text-sm font-bold text-slate-900">
                {{ isEdit ? 'Editar conquista' : 'Nova conquista' }}
              </h2>
            </div>
            <button @click="close" class="text-slate-400 hover:text-slate-600 transition-colors p-1">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Body -->
          <div class="overflow-y-auto flex-1 min-h-0 px-6 py-5 space-y-5">

            <!-- Métrica -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-2">Tipo de métrica</label>
              <div class="grid grid-cols-2 gap-3">
                <button type="button" @click="form.metric = 'workouts_total'"
                  class="flex items-center gap-3 px-4 py-3 rounded-xl border-2 text-left transition-all"
                  :class="form.metric === 'workouts_total'
                    ? 'border-brand-500 bg-brand-50 shadow-sm'
                    : 'border-slate-200 hover:border-brand-300 hover:bg-brand-50/40'"
                >
                  <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                       :class="form.metric === 'workouts_total' ? 'bg-brand-600' : 'bg-brand-100'">
                    <svg class="w-4 h-4 transition-colors"
                         :class="form.metric === 'workouts_total' ? 'text-white' : 'text-brand-500'"
                         fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round"
                        d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-xs font-bold text-slate-800">Treinos</p>
                    <p class="text-[10px] text-slate-500">Qtd. de treinos</p>
                  </div>
                  <div v-if="form.metric === 'workouts_total'"
                       class="ml-auto w-4 h-4 rounded-full bg-brand-600 flex items-center justify-center flex-shrink-0">
                    <svg class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                </button>

                <button type="button" @click="form.metric = 'streak_days'"
                  class="flex items-center gap-3 px-4 py-3 rounded-xl border-2 text-left transition-all"
                  :class="form.metric === 'streak_days'
                    ? 'border-amber-500 bg-amber-50 shadow-sm'
                    : 'border-slate-200 hover:border-amber-300 hover:bg-amber-50/40'"
                >
                  <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                       :class="form.metric === 'streak_days' ? 'bg-amber-500' : 'bg-amber-100'">
                    <svg class="w-4 h-4 transition-colors"
                         :class="form.metric === 'streak_days' ? 'text-white' : 'text-amber-500'"
                         fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round"
                        d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-xs font-bold text-slate-800">Streak</p>
                    <p class="text-[10px] text-slate-500">Dias seguidos</p>
                  </div>
                  <div v-if="form.metric === 'streak_days'"
                       class="ml-auto w-4 h-4 rounded-full bg-amber-500 flex items-center justify-center flex-shrink-0">
                    <svg class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                </button>
              </div>
            </div>

            <!-- Título -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Título</label>
              <input v-model="form.title" type="text" placeholder="Ex: 10 treinos concluídos"
                class="input-field w-full"
                :class="{ 'border-red-400 focus:ring-red-400': errors.title }" />
              <p v-if="errors.title" class="text-xs text-red-500 mt-1">{{ errors.title }}</p>
            </div>

            <!-- Descrição -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Descrição</label>
              <input v-model="form.description" type="text" placeholder="Ex: Complete 10 treinos"
                class="input-field w-full"
                :class="{ 'border-red-400 focus:ring-red-400': errors.description }" />
              <p v-if="errors.description" class="text-xs text-red-500 mt-1">{{ errors.description }}</p>
            </div>

            <!-- Meta + Pontos -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-xs font-semibold text-slate-700 mb-1.5">
                  Meta
                  <span class="font-normal text-slate-400 ml-1">
                    {{ form.metric === 'streak_days' ? '(dias)' : '(treinos)' }}
                  </span>
                </label>
                <input v-model.number="form.target_value" type="number" min="1"
                  placeholder="10"
                  class="input-field w-full"
                  :class="{ 'border-red-400 focus:ring-red-400': errors.target_value }" />
                <p v-if="errors.target_value" class="text-xs text-red-500 mt-1">{{ errors.target_value }}</p>
              </div>

              <div>
                <label class="block text-xs font-semibold text-slate-700 mb-1.5">Pontos de recompensa</label>
                <div class="relative">
                  <input v-model.number="form.points_reward" type="number" min="0"
                    placeholder="50"
                    class="input-field w-full pl-8"
                    :class="{ 'border-red-400 focus:ring-red-400': errors.points_reward }" />
                  <span class="absolute left-3 top-1/2 -translate-y-1/2">
                    <svg class="w-4 h-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round"
                        d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
                    </svg>
                  </span>
                </div>
                <p v-if="errors.points_reward" class="text-xs text-red-500 mt-1">{{ errors.points_reward }}</p>
              </div>
            </div>

            <!-- Preview card -->
            <div v-if="form.title" class="bg-slate-50 rounded-xl p-3">
              <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-widest mb-2">Pré-visualização</p>
              <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                     :class="form.metric === 'streak_days' ? 'bg-amber-100' : 'bg-brand-50'">
                  <svg v-if="form.metric === 'streak_days'" class="w-5 h-5 text-amber-500"
                       fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
                  </svg>
                  <svg v-else class="w-5 h-5 text-brand-600"
                       fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                  </svg>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-xs font-semibold text-slate-800 truncate">{{ form.title }}</p>
                  <p class="text-[11px] text-slate-500 truncate">{{ form.description || '…' }}</p>
                </div>
                <div class="text-right flex-shrink-0">
                  <p class="text-xs font-bold text-amber-600">+{{ form.points_reward || 0 }} pts</p>
                  <p class="text-[10px] text-slate-400">meta: {{ form.target_value || '?' }}</p>
                </div>
              </div>
            </div>

            <!-- API error -->
            <div v-if="apiError"
              class="flex items-start gap-2 px-3 py-2.5 bg-red-50 border border-red-200 rounded-lg">
              <svg class="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
              </svg>
              <p class="text-xs text-red-600">{{ apiError }}</p>
            </div>

          </div>

          <!-- Footer -->
          <div class="flex items-center justify-between gap-3 px-6 py-4 border-t border-slate-100 flex-shrink-0">
            <button @click="close" class="btn-secondary">Cancelar</button>
            <button @click="submit" :disabled="saving"
              class="inline-flex items-center gap-1.5 px-5 py-2 bg-brand-600 text-white text-sm
                     font-semibold rounded-lg hover:bg-brand-700 transition-colors
                     disabled:opacity-60 disabled:cursor-not-allowed">
              <svg v-if="saving" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
              </svg>
              {{ saving ? 'Salvando…' : (isEdit ? 'Salvar alterações' : 'Criar conquista') }}
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
  modelValue:        { type: Boolean, required: true },
  achievementToEdit: { type: Object,  default: null  },
})
const emit = defineEmits(['update:modelValue', 'saved'])

const isEdit   = computed(() => !!props.achievementToEdit)
const saving   = ref(false)
const apiError = ref('')
const errors   = ref({})

function defaultForm() {
  return { metric: 'workouts_total', title: '', description: '', target_value: null, points_reward: null }
}
const form = ref(defaultForm())

watch(() => props.modelValue, (open) => {
  if (!open) return
  apiError.value = ''
  errors.value   = {}
  if (props.achievementToEdit) {
    const a = props.achievementToEdit
    form.value = {
      metric:        a.metric,
      title:         a.title,
      description:   a.description,
      target_value:  a.target_value,
      points_reward: a.points_reward,
    }
  } else {
    form.value = defaultForm()
  }
})

function close() {
  if (!saving.value) emit('update:modelValue', false)
}

function validate() {
  const e = {}
  if (!form.value.title?.trim())                        e.title         = 'Título é obrigatório.'
  if (!form.value.description?.trim())                  e.description   = 'Descrição é obrigatória.'
  if (!form.value.target_value || form.value.target_value < 1) e.target_value  = 'Informe uma meta válida (mínimo 1).'
  if (form.value.points_reward === null || form.value.points_reward < 0) e.points_reward = 'Informe os pontos de recompensa.'
  errors.value = e
  return Object.keys(e).length === 0
}

async function submit() {
  apiError.value = ''
  if (!validate()) return

  saving.value = true
  try {
    const payload = { ...form.value }
    if (isEdit.value) {
      await api.put(`/admin/achievements/${props.achievementToEdit.id}`, payload)
    } else {
      await api.post('/admin/achievements', payload)
    }
    emit('saved')
    emit('update:modelValue', false)
  } catch (e) {
    apiError.value = e.response?.data?.message ?? 'Ocorreu um erro ao salvar.'
  } finally {
    saving.value = false
  }
}
</script>
