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

        <div class="relative z-10 bg-white rounded-2xl shadow-2xl w-full max-w-lg flex flex-col"
             style="max-height: min(92vh, 740px)">

          <!-- ── HEADER ────────────────────────────────────────────── -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100 flex-shrink-0">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                   :class="categoryStyle.headerBg">
                <span class="text-base leading-none">{{ categoryStyle.icon }}</span>
              </div>
              <div>
                <h2 class="text-sm font-bold text-slate-900 leading-tight">
                  {{ isEdit ? 'Editar recompensa' : 'Nova recompensa' }}
                </h2>
                <p class="text-xs text-slate-400 mt-0.5">{{ categoryStyle.label }}</p>
              </div>
            </div>
            <button @click="close" class="text-slate-400 hover:text-slate-600 transition-colors p-1">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- ── BODY ──────────────────────────────────────────────── -->
          <div class="overflow-y-auto flex-1 min-h-0 px-6 py-5 space-y-6">

            <!-- ◆ IMAGEM ──────────────────────────────────────────── -->
            <section>
              <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-3">Imagem do produto</p>

              <!-- Preview ou Drop zone -->
              <div
                class="relative rounded-xl border-2 transition-all overflow-hidden"
                :class="dragging
                  ? 'border-brand-400 bg-brand-50'
                  : imagePreview ? 'border-slate-200' : 'border-dashed border-slate-300 bg-slate-50'"
                @dragover.prevent="dragging = true"
                @dragleave.prevent="dragging = false"
                @drop.prevent="onDrop"
              >
                <!-- Image preview -->
                <div v-if="imagePreview" class="relative group">
                  <img :src="imagePreview" alt="Preview"
                       class="w-full h-48 object-cover" />
                  <!-- Overlay actions -->
                  <div class="absolute inset-0 bg-slate-900/40 opacity-0 group-hover:opacity-100
                              transition-opacity flex items-center justify-center gap-3">
                    <label class="cursor-pointer inline-flex items-center gap-1.5 px-3 py-1.5 bg-white
                                  text-slate-800 text-xs font-semibold rounded-lg hover:bg-slate-100 transition-colors">
                      <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round"
                          d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931z" />
                      </svg>
                      Trocar
                      <input type="file" class="hidden" accept="image/*" @change="onFileChange" />
                    </label>
                    <button type="button" @click="removeImage"
                      class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-red-500 text-white
                             text-xs font-semibold rounded-lg hover:bg-red-600 transition-colors">
                      <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                      Remover
                    </button>
                  </div>
                </div>

                <!-- Drop zone (no image) -->
                <label v-else class="flex flex-col items-center justify-center h-40 cursor-pointer select-none">
                  <div class="w-12 h-12 rounded-full bg-slate-200 flex items-center justify-center mb-3">
                    <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                      <path stroke-linecap="round" stroke-linejoin="round"
                        d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z" />
                    </svg>
                  </div>
                  <p class="text-sm font-semibold text-slate-600 mb-1">
                    {{ dragging ? 'Solte a imagem aqui' : 'Arraste ou clique para adicionar' }}
                  </p>
                  <p class="text-xs text-slate-400">PNG, JPG, WEBP • Máx. 2MB</p>
                  <input type="file" class="hidden" accept="image/*" @change="onFileChange" />
                </label>
              </div>
            </section>

            <!-- ◆ TIPO ───────────────────────────────────────────── -->
            <section>
              <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-3">Tipo de recompensa</p>
              <div class="grid grid-cols-3 gap-2.5">
                <button v-for="cat in categories" :key="cat.value" type="button"
                  @click="form.category = cat.value"
                  class="flex flex-col items-center gap-2 py-3 rounded-xl border-2 text-xs font-semibold transition-all"
                  :class="form.category === cat.value
                    ? cat.selected
                    : 'border-slate-200 bg-white text-slate-500 hover:border-slate-300'"
                >
                  <span class="text-lg leading-none">{{ cat.icon }}</span>
                  <span>{{ cat.label }}</span>
                  <div v-if="form.category === cat.value"
                    class="w-4 h-4 rounded-full flex items-center justify-center"
                    :class="cat.checkBg">
                    <svg class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                </button>
              </div>
            </section>

            <!-- ◆ INFORMAÇÕES ─────────────────────────────────────── -->
            <section>
              <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-3">Informações</p>
              <div class="space-y-3">

                <div>
                  <label class="block text-xs font-semibold text-slate-700 mb-1.5">Nome da recompensa</label>
                  <input v-model="form.name" type="text"
                    placeholder="Ex: Camiseta GymUp Dry-Fit"
                    class="input-field w-full"
                    :class="{ 'border-red-400 focus:ring-red-400': errors.name }" />
                  <p v-if="errors.name" class="text-xs text-red-500 mt-1">{{ errors.name }}</p>
                </div>

                <div>
                  <label class="block text-xs font-semibold text-slate-700 mb-1.5">
                    Descrição
                    <span class="font-normal text-slate-400 ml-1">— opcional</span>
                  </label>
                  <textarea v-model="form.description" rows="3"
                    placeholder="Descreva a recompensa para os alunos: material, tamanho, condições…"
                    class="input-field w-full resize-none" />
                  <p class="text-[10px] text-slate-400 mt-1 text-right">{{ form.description?.length ?? 0 }}/600</p>
                </div>

              </div>
            </section>

            <!-- ◆ CONFIGURAÇÃO ────────────────────────────────────── -->
            <section>
              <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-3">Configuração</p>
              <div class="bg-slate-50 rounded-xl p-4 space-y-4">

                <!-- Pontos -->
                <div>
                  <label class="block text-xs font-semibold text-slate-700 mb-1.5">Custo em pontos</label>
                  <div class="relative">
                    <div class="absolute left-3 top-1/2 -translate-y-1/2">
                      <svg class="w-4 h-4 text-amber-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round"
                          d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
                      </svg>
                    </div>
                    <input v-model.number="form.points_cost" type="number" min="1"
                      placeholder="500"
                      class="input-field w-full pl-9 bg-white"
                      :class="{ 'border-red-400': errors.points_cost }" />
                    <span class="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-slate-400">pontos</span>
                  </div>
                  <p v-if="errors.points_cost" class="text-xs text-red-500 mt-1">{{ errors.points_cost }}</p>
                </div>

                <!-- Desconto (apenas category = discount) -->
                <div v-if="form.category === 'discount'">
                  <label class="block text-xs font-semibold text-slate-700 mb-1.5">Percentual de desconto</label>
                  <div class="relative">
                    <input v-model.number="form.discount_percent" type="number" min="0" max="100" step="0.5"
                      placeholder="10"
                      class="input-field w-full pr-8 bg-white"
                      :class="{ 'border-red-400': errors.discount_percent }" />
                    <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm font-bold text-slate-400">%</span>
                  </div>
                  <p v-if="errors.discount_percent" class="text-xs text-red-500 mt-1">{{ errors.discount_percent }}</p>
                  <!-- Preview -->
                  <div v-if="form.discount_percent > 0"
                    class="mt-2 flex items-center gap-2 text-xs text-green-700 bg-green-50 px-3 py-1.5 rounded-lg">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round"
                        d="M9 14.25l6-6m4.5-3.493V21.75l-4.125-2.625-3.375 2.25-3.375-2.25-4.125 2.625V4.757c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0c1.1.128 1.907 1.077 1.907 2.185z" />
                    </svg>
                    O aluno receberá {{ form.discount_percent }}% de desconto
                  </div>
                </div>

                <!-- Estoque -->
                <div>
                  <div class="flex items-center justify-between mb-2">
                    <label class="text-xs font-semibold text-slate-700">Estoque</label>
                    <label class="flex items-center gap-2 cursor-pointer select-none">
                      <span class="text-xs text-slate-500">Ilimitado</span>
                      <button type="button" @click="toggleUnlimited"
                        class="relative inline-flex h-5 w-9 items-center rounded-full transition-colors"
                        :class="form.stock === null ? 'bg-brand-600' : 'bg-slate-200'">
                        <span class="inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow transition-transform"
                              :class="form.stock === null ? 'translate-x-[18px]' : 'translate-x-[3px]'" />
                      </button>
                    </label>
                  </div>

                  <div v-if="form.stock !== null" class="flex items-center gap-3">
                    <button type="button" @click="adjustStock(-10)"
                      class="w-9 h-9 rounded-xl bg-white border border-slate-200 flex items-center justify-center
                             text-slate-600 hover:bg-slate-100 transition-colors font-bold text-sm flex-shrink-0">
                      −10
                    </button>
                    <button type="button" @click="adjustStock(-1)"
                      class="w-9 h-9 rounded-xl bg-white border border-slate-200 flex items-center justify-center
                             text-slate-600 hover:bg-slate-100 transition-colors font-bold text-lg flex-shrink-0">
                      −
                    </button>
                    <input v-model.number="form.stock" type="number" min="0"
                      class="flex-1 input-field text-center text-lg font-bold bg-white"
                      :class="{ 'border-red-400': errors.stock }" />
                    <button type="button" @click="adjustStock(1)"
                      class="w-9 h-9 rounded-xl bg-white border border-slate-200 flex items-center justify-center
                             text-slate-600 hover:bg-slate-100 transition-colors font-bold text-lg flex-shrink-0">
                      +
                    </button>
                    <button type="button" @click="adjustStock(10)"
                      class="w-9 h-9 rounded-xl bg-white border border-slate-200 flex items-center justify-center
                             text-slate-600 hover:bg-slate-100 transition-colors font-bold text-sm flex-shrink-0">
                      +10
                    </button>
                  </div>
                  <div v-else
                    class="flex items-center gap-2 text-xs text-slate-500 bg-white border border-slate-200 rounded-xl px-4 py-3">
                    <svg class="w-4 h-4 text-brand-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round"
                        d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    Estoque ilimitado — disponível para todos os alunos
                  </div>
                  <p v-if="errors.stock" class="text-xs text-red-500 mt-1">{{ errors.stock }}</p>
                </div>

              </div>
            </section>

            <!-- ◆ STATUS ──────────────────────────────────────────── -->
            <section>
              <div class="flex items-center justify-between p-4 bg-slate-50 rounded-xl">
                <div>
                  <p class="text-xs font-semibold text-slate-700">Recompensa ativa</p>
                  <p class="text-[11px] text-slate-400 mt-0.5">Alunos poderão visualizar e resgatar esta recompensa</p>
                </div>
                <button type="button" @click="form.active = !form.active"
                  class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors flex-shrink-0"
                  :class="form.active ? 'bg-emerald-500' : 'bg-slate-200'">
                  <span class="inline-block h-4.5 w-4.5 transform rounded-full bg-white shadow transition-transform"
                        :class="form.active ? 'translate-x-[22px]' : 'translate-x-[3px]'"
                        style="width:18px;height:18px" />
                </button>
              </div>
            </section>

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

          <!-- ── FOOTER ─────────────────────────────────────────────── -->
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
              {{ saving ? 'Salvando…' : (isEdit ? 'Salvar alterações' : 'Criar recompensa') }}
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
  modelValue:    { type: Boolean, required: true },
  rewardToEdit:  { type: Object,  default: null  },
})
const emit = defineEmits(['update:modelValue', 'saved'])

const isEdit   = computed(() => !!props.rewardToEdit)
const saving   = ref(false)
const apiError = ref('')
const errors   = ref({})
const dragging = ref(false)

// Image state
const imageFile    = ref(null)   // File object (new upload)
const imagePreview = ref(null)   // Data URL or existing URL
const removeImg    = ref(false)  // Flag to remove existing image

const categories = [
  {
    value:    'physical',
    label:    'Produto',
    icon:     '📦',
    selected: 'border-blue-500 bg-blue-50 text-blue-700',
    checkBg:  'bg-blue-600',
  },
  {
    value:    'service',
    label:    'Serviço',
    icon:     '🎯',
    selected: 'border-violet-500 bg-violet-50 text-violet-700',
    checkBg:  'bg-violet-600',
  },
  {
    value:    'discount',
    label:    'Desconto',
    icon:     '🏷️',
    selected: 'border-green-500 bg-green-50 text-green-700',
    checkBg:  'bg-green-600',
  },
]

const categoryStyle = computed(() => {
  const map = {
    physical: { label: 'Produto físico',  icon: '📦', headerBg: 'bg-blue-100'   },
    service:  { label: 'Serviço',          icon: '🎯', headerBg: 'bg-violet-100' },
    discount: { label: 'Desconto',         icon: '🏷️', headerBg: 'bg-green-100'  },
  }
  return map[form.value.category] ?? map.physical
})

function defaultForm() {
  return {
    name:             '',
    description:      '',
    category:         'physical',
    points_cost:      null,
    stock:            0,
    discount_percent: null,
    active:           true,
  }
}
const form = ref(defaultForm())

// ── Image handling ─────────────────────────────────────────────────

function onFileChange(e) {
  const file = e.target.files?.[0]
  if (file) setImage(file)
}

function onDrop(e) {
  dragging.value = false
  const file = e.dataTransfer?.files?.[0]
  if (file && file.type.startsWith('image/')) setImage(file)
}

function setImage(file) {
  if (file.size > 2 * 1024 * 1024) {
    apiError.value = 'A imagem deve ter no máximo 2MB.'
    return
  }
  imageFile.value = file
  removeImg.value = false
  const reader    = new FileReader()
  reader.onload   = (e) => { imagePreview.value = e.target.result }
  reader.readAsDataURL(file)
}

function removeImage() {
  imageFile.value    = null
  imagePreview.value = null
  removeImg.value    = true
}

// ── Stock helpers ──────────────────────────────────────────────────

function toggleUnlimited() {
  form.value.stock = form.value.stock === null ? 0 : null
}

function adjustStock(delta) {
  form.value.stock = Math.max(0, (form.value.stock ?? 0) + delta)
}

// ── Watch ─────────────────────────────────────────────────────────

watch(() => props.modelValue, (open) => {
  if (!open) return
  apiError.value    = ''
  errors.value      = {}
  imageFile.value   = null
  removeImg.value   = false

  if (props.rewardToEdit) {
    const r = props.rewardToEdit
    form.value = {
      name:             r.name             ?? '',
      description:      r.description      ?? '',
      category:         r.category         ?? 'physical',
      points_cost:      r.points_cost       ?? null,
      stock:            r.stock             ?? null,
      discount_percent: r.discount_percent  ?? null,
      active:           r.active            ?? true,
    }
    imagePreview.value = r.image_url ?? null
  } else {
    form.value         = defaultForm()
    imagePreview.value = null
  }
})

// ── Validation ────────────────────────────────────────────────────

function validate() {
  const e = {}
  if (!form.value.name?.trim())                              e.name         = 'Nome é obrigatório.'
  if (!form.value.points_cost || form.value.points_cost < 1) e.points_cost  = 'Informe o custo em pontos (mínimo 1).'
  if (form.value.category === 'discount' && (form.value.discount_percent === null || form.value.discount_percent < 0))
    e.discount_percent = 'Informe o percentual de desconto.'
  if (form.value.stock !== null && form.value.stock < 0)     e.stock        = 'Estoque não pode ser negativo.'
  errors.value = e
  return Object.keys(e).length === 0
}

// ── Submit ────────────────────────────────────────────────────────

function close() {
  if (!saving.value) emit('update:modelValue', false)
}

async function submit() {
  apiError.value = ''
  if (!validate()) return

  saving.value = true

  try {
    // Always use FormData to support image upload
    const fd = new FormData()
    fd.append('name',             form.value.name)
    fd.append('description',      form.value.description ?? '')
    fd.append('category',         form.value.category)
    fd.append('points_cost',      form.value.points_cost)
    fd.append('active',           form.value.active ? '1' : '0')

    if (form.value.stock !== null) {
      fd.append('stock', form.value.stock)
    }
    if (form.value.category === 'discount' && form.value.discount_percent !== null) {
      fd.append('discount_percent', form.value.discount_percent)
    }
    if (imageFile.value) {
      fd.append('image', imageFile.value)
    }
    if (removeImg.value) {
      fd.append('remove_image', '1')
    }

    if (isEdit.value) {
      await api.post(`/admin/rewards/${props.rewardToEdit.id}`, fd)
    } else {
      await api.post('/admin/rewards', fd)
    }

    emit('saved')
    emit('update:modelValue', false)
  } catch (e) {
    const msg = e.response?.data?.message
    const errs = e.response?.data?.errors
    if (errs) {
      errors.value = Object.fromEntries(
        Object.entries(errs).map(([k, v]) => [k, Array.isArray(v) ? v[0] : v])
      )
    }
    apiError.value = msg ?? 'Ocorreu um erro ao salvar a recompensa.'
  } finally {
    saving.value = false
  }
}
</script>
