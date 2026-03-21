<template>
  <Teleport to="body">
    <Transition enter-active-class="transition duration-200" enter-from-class="opacity-0"
      enter-to-class="opacity-100" leave-active-class="transition duration-150"
      leave-from-class="opacity-100" leave-to-class="opacity-0">
      <div v-if="modelValue" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="close" />

        <div class="relative z-10 bg-white rounded-2xl shadow-2xl w-full max-w-xl max-h-[90vh] flex flex-col overflow-hidden">

          <!-- Header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <div>
              <h2 class="text-base font-semibold text-slate-900">
                {{ editMode ? 'Editar treino' : 'Criar treino' }}
              </h2>
              <p v-if="inPlanContext && !editMode" class="text-xs text-slate-400 mt-0.5">
                O treino será adicionado automaticamente ao plano.
              </p>
            </div>
            <button @click="close"
              class="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Body -->
          <div class="flex-1 overflow-y-auto px-6 py-5 space-y-6">

            <!-- Submit error -->
            <div v-if="submitError"
              class="flex items-start gap-2 p-3 bg-red-50 border border-red-100 rounded-lg text-sm text-red-600">
              <svg class="w-4 h-4 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
              </svg>
              {{ submitError }}
            </div>

            <!-- ── Informações ──────────────────────────────────────────────── -->
            <section>
              <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">Informações</h3>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">

                <div class="sm:col-span-2">
                  <label class="block text-sm font-medium text-slate-700 mb-1.5">
                    Nome <span class="text-red-500">*</span>
                  </label>
                  <input v-model="form.name" type="text" placeholder="Ex: Treino A – Peito e Tríceps"
                    class="w-full px-3.5 py-2.5 text-sm border rounded-lg focus:outline-none focus:ring-2
                           focus:ring-brand-500 focus:border-transparent placeholder-slate-400 transition"
                    :class="errors.name ? 'border-red-300' : 'border-slate-200'" />
                  <p v-if="errors.name" class="mt-1 text-xs text-red-500">{{ errors.name }}</p>
                </div>

                <div>
                  <label class="block text-sm font-medium text-slate-700 mb-1.5">Nível</label>
                  <select v-model="form.level"
                    class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none
                           focus:ring-2 focus:ring-brand-500 focus:border-transparent bg-white transition">
                    <option value="">Selecionar nível</option>
                    <option value="Iniciante">Iniciante</option>
                    <option value="Intermediário">Intermediário</option>
                    <option value="Avançado">Avançado</option>
                  </select>
                </div>

                <div>
                  <label class="block text-sm font-medium text-slate-700 mb-1.5">Duração (min)</label>
                  <input v-model.number="form.duration" type="number" min="1" max="300" placeholder="Ex: 45"
                    class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none
                           focus:ring-2 focus:ring-brand-500 focus:border-transparent placeholder-slate-400 transition" />
                </div>

                <div class="sm:col-span-2">
                  <label class="block text-sm font-medium text-slate-700 mb-1.5">Descrição</label>
                  <textarea v-model="form.description" rows="2" placeholder="Descrição opcional do treino…"
                    class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-lg focus:outline-none
                           focus:ring-2 focus:ring-brand-500 focus:border-transparent placeholder-slate-400
                           transition resize-none" />
                </div>
              </div>
            </section>

            <!-- ── Exercícios ──────────────────────────────────────────────── -->
            <section>
              <div class="flex items-center gap-2 mb-3">
                <h3 class="text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Exercícios
                  <span v-if="form.exercises.length" class="ml-1.5 text-brand-600">
                    ({{ form.exercises.length }})
                  </span>
                </h3>
              </div>

              <p v-if="errors.exercises" class="text-xs text-red-500 mb-2">{{ errors.exercises }}</p>

              <!-- Added exercise rows (draggable) -->
              <div v-if="form.exercises.length" class="space-y-1.5 mb-3">
                <div v-for="(ex, idx) in form.exercises" :key="ex.exercise_id + '-' + idx"
                  class="flex items-center gap-2 px-3 py-2.5 rounded-xl border transition-all"
                  :class="[
                    exDragOverIdx === idx && exDraggingIdx !== idx
                      ? 'bg-brand-50 border-brand-300 ring-2 ring-brand-200'
                      : 'bg-slate-50 border-slate-100',
                    exDraggingIdx === idx ? 'opacity-40' : '',
                  ]"
                  @dragover.prevent="onExDragOver(idx)"
                  @drop.prevent="onExDrop(idx)">

                  <div draggable="true" @dragstart="onExDragStart(idx, $event)" @dragend="onExDragEnd"
                    class="cursor-grab active:cursor-grabbing p-0.5 text-slate-300 hover:text-slate-500
                           flex-shrink-0 transition-colors">
                    <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 16 16">
                      <circle cx="5.5" cy="4" r="1.5"/><circle cx="5.5" cy="8" r="1.5"/>
                      <circle cx="5.5" cy="12" r="1.5"/><circle cx="10.5" cy="4" r="1.5"/>
                      <circle cx="10.5" cy="8" r="1.5"/><circle cx="10.5" cy="12" r="1.5"/>
                    </svg>
                  </div>

                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-slate-800 truncate">{{ ex.name }}</p>
                    <p v-if="ex.muscle_group" class="text-[11px] text-slate-400 leading-none mt-0.5">
                      {{ ex.muscle_group }}
                    </p>
                  </div>

                  <div class="flex items-end gap-1.5 flex-shrink-0">
                    <div class="flex flex-col items-center gap-0.5">
                      <span class="text-[9px] text-slate-400 uppercase tracking-wide">Séries</span>
                      <input v-model.number="ex.sets" type="number" min="1" max="20"
                        class="w-10 px-1 py-1 text-xs text-center border border-slate-200 rounded-md
                               focus:outline-none focus:ring-1 focus:ring-brand-400" />
                    </div>
                    <span class="text-slate-300 text-xs pb-1.5">×</span>
                    <div class="flex flex-col items-center gap-0.5">
                      <span class="text-[9px] text-slate-400 uppercase tracking-wide">Reps</span>
                      <input v-model.number="ex.reps" type="number" min="1" max="100"
                        class="w-10 px-1 py-1 text-xs text-center border border-slate-200 rounded-md
                               focus:outline-none focus:ring-1 focus:ring-brand-400" />
                    </div>
                    <div class="flex flex-col items-center gap-0.5">
                      <span class="text-[9px] text-slate-400 uppercase tracking-wide">Desc (s)</span>
                      <input v-model.number="ex.rest" type="number" min="0" max="600"
                        class="w-12 px-1 py-1 text-xs text-center border border-slate-200 rounded-md
                               focus:outline-none focus:ring-1 focus:ring-brand-400" />
                    </div>
                  </div>

                  <button @click="removeExercise(idx)"
                    class="p-0.5 text-slate-300 hover:text-red-400 transition-colors flex-shrink-0 ml-1">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
              </div>

              <!-- ── Exercise picker ─────────────────────────────────────── -->
              <div v-if="searchOpen" class="rounded-xl border border-slate-200 overflow-hidden">

                <!-- Search input row -->
                <div class="flex items-center gap-2 px-3 py-2.5 border-b border-slate-100 bg-white">
                  <svg class="w-3.5 h-3.5 text-slate-400 flex-shrink-0" fill="none" viewBox="0 0 24 24"
                    stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                  </svg>
                  <input ref="searchInputRef" v-model="searchQuery"
                    @keydown="onKeyDown"
                    type="text"
                    placeholder="Buscar exercício…"
                    class="flex-1 text-sm text-slate-800 placeholder-slate-400 focus:outline-none min-w-0 bg-transparent" />
                  <button v-if="searchQuery" @click="clearSearch"
                    class="flex-shrink-0 text-slate-400 hover:text-slate-600 transition-colors">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                  <button @click="closeSearch"
                    class="flex-shrink-0 text-xs font-medium text-slate-400 hover:text-slate-700 px-2 py-0.5
                           hover:bg-slate-100 rounded-md transition-colors ml-0.5">
                    Fechar
                  </button>
                </div>

                <!-- Category pills -->
                <div class="relative border-b border-slate-100">
                  <!-- Left fade -->
                  <div class="pointer-events-none absolute left-0 top-0 bottom-0 w-6 z-10
                              bg-gradient-to-r from-white to-transparent" />
                  <!-- Right fade -->
                  <div class="pointer-events-none absolute right-0 top-0 bottom-0 w-8 z-10
                              bg-gradient-to-l from-white to-transparent" />

                  <div ref="catBarRef"
                    class="flex items-center gap-1.5 px-3 py-2 overflow-x-auto"
                    style="-webkit-overflow-scrolling:touch;scrollbar-width:none;-ms-overflow-style:none">
                    <button data-cat="__all__" @click="setCategory(null)"
                      class="flex-shrink-0 px-2.5 py-1 text-xs font-semibold rounded-full transition-colors"
                      :class="activeCategory === null
                        ? 'bg-brand-600 text-white'
                        : 'bg-slate-100 text-slate-600 hover:bg-slate-200'">
                      Todos
                    </button>
                    <button v-for="cat in categories" :key="cat"
                      :data-cat="cat"
                      @click="setCategory(cat)"
                      class="flex-shrink-0 px-2.5 py-1 text-xs font-semibold rounded-full transition-colors"
                      :class="activeCategory === cat
                        ? 'bg-brand-600 text-white'
                        : 'bg-slate-100 text-slate-600 hover:bg-slate-200'">
                      {{ cat }}
                    </button>
                  </div>
                </div>

                <!-- Exercise list (always visible) -->
                <div ref="listRef" class="max-h-56 overflow-y-auto">

                  <!-- Loading state -->
                  <div v-if="allLoading" class="flex items-center justify-center gap-2 py-10 text-sm text-slate-400">
                    <svg class="animate-spin w-4 h-4 text-brand-400" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                    </svg>
                    Carregando exercícios…
                  </div>

                  <template v-else>

                    <!-- Empty state -->
                    <div v-if="!visibleExercises.length" class="py-10 text-center text-sm text-slate-400">
                      {{ searchQuery ? 'Nenhum exercício encontrado para "' + searchQuery + '".' : 'Nenhum exercício nesta categoria.' }}
                    </div>

                    <!-- Grouped view: Todos + sem busca -->
                    <template v-else-if="showGrouped">
                      <div v-for="group in groupedVisible" :key="group.name">
                        <div class="sticky top-0 z-10 px-3 py-1.5 bg-slate-50 border-b border-slate-100/80">
                          <span class="text-[10px] font-bold text-slate-500 uppercase tracking-wider">
                            {{ group.name }}
                          </span>
                        </div>
                        <button v-for="ex in group.exercises" :key="ex.id"
                          :data-ex-id="ex.id"
                          @click="addExercise(ex)"
                          :disabled="isAdded(ex.id)"
                          class="w-full flex items-center gap-3 px-3 py-2.5 text-left transition-colors
                                 border-b border-slate-50 last:border-0"
                          :class="exerciseRowClass(ex)">
                          <div class="flex-1 min-w-0">
                            <span class="text-sm font-medium truncate block"
                              :class="isAdded(ex.id) ? 'text-slate-400' : 'text-slate-800'">
                              {{ ex.name }}
                            </span>
                          </div>
                          <svg v-if="isAdded(ex.id)" class="w-4 h-4 text-brand-500 flex-shrink-0"
                            fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                          </svg>
                          <span v-else-if="isFocused(ex.id)"
                            class="text-[11px] font-semibold text-brand-600 flex-shrink-0">↵</span>
                        </button>
                      </div>
                    </template>

                    <!-- Flat view: categoria selecionada OU buscando -->
                    <template v-else>
                      <button v-for="ex in visibleExercises" :key="ex.id"
                        :data-ex-id="ex.id"
                        @click="addExercise(ex)"
                        :disabled="isAdded(ex.id)"
                        class="w-full flex items-center gap-3 px-3 py-2.5 text-left transition-colors
                               border-b border-slate-50 last:border-0"
                        :class="exerciseRowClass(ex)">
                        <div class="flex-1 min-w-0">
                          <span class="text-sm font-medium truncate block"
                            :class="isAdded(ex.id) ? 'text-slate-400' : 'text-slate-800'">
                            {{ ex.name }}
                          </span>
                          <span v-if="!activeCategory && ex.muscle_group"
                            class="text-[11px] text-slate-400 leading-none">{{ ex.muscle_group }}</span>
                        </div>
                        <svg v-if="isAdded(ex.id)" class="w-4 h-4 text-brand-500 flex-shrink-0"
                          fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                        </svg>
                        <span v-else-if="isFocused(ex.id)"
                          class="text-[11px] font-semibold text-brand-600 flex-shrink-0">↵</span>
                      </button>
                    </template>

                  </template>
                </div>

                <!-- Footer -->
                <div class="flex items-center justify-between px-3 py-2 border-t border-slate-100 bg-slate-50/60">
                  <span class="text-[11px] text-slate-400">
                    <kbd class="font-mono bg-white border border-slate-200 rounded px-1 py-px text-[10px]">↑↓</kbd>
                    navegar ·
                    <kbd class="font-mono bg-white border border-slate-200 rounded px-1 py-px text-[10px]">Enter</kbd>
                    adicionar
                  </span>
                  <span class="text-[11px] text-slate-400">
                    {{ visibleExercises.length }} exercício{{ visibleExercises.length !== 1 ? 's' : '' }}
                  </span>
                </div>
              </div>

              <!-- Add button (picker closed) -->
              <button v-else @click="openSearch"
                class="flex items-center gap-1.5 text-xs font-semibold text-brand-600 hover:text-brand-700
                       hover:bg-brand-50 px-2.5 py-1.5 rounded-lg transition-colors -ml-1">
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                </svg>
                Adicionar exercício
              </button>

            </section>
          </div>

          <!-- Footer -->
          <div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-slate-100 bg-slate-50/50">
            <button @click="close" class="btn-secondary">Cancelar</button>
            <button @click="submit" :disabled="submitting" class="btn-primary">
              <svg v-if="submitting" class="animate-spin w-4 h-4 mr-1.5" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
              </svg>
              {{ submitting ? 'Salvando…' : (editMode ? 'Salvar alterações' : 'Criar treino') }}
            </button>
          </div>

        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, reactive, computed, watch, nextTick } from 'vue'
import api from '../../services/api.js'

const props = defineProps({
  modelValue:    { type: Boolean, default: false },
  workoutToEdit: { type: Object,  default: null  },
  inPlanContext: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue', 'saved'])

const editMode = computed(() => !!props.workoutToEdit)

const form = reactive({ name: '', description: '', level: '', duration: null, exercises: [] })
const errors      = reactive({})
const submitting  = ref(false)
const submitError = ref('')

// ── All exercises (loaded once, cached for component lifetime) ────────────────
const allExercises = ref([])
const allLoading   = ref(false)
const allLoaded    = ref(false)

async function ensureExercisesLoaded() {
  if (allLoaded.value || allLoading.value) return
  allLoading.value = true
  try {
    const { data } = await api.get('/admin/exercises')
    allExercises.value = data.exercises ?? []
    allLoaded.value    = true
  } catch { /* silencioso */ }
  finally { allLoading.value = false }
}

// ── Picker state ──────────────────────────────────────────────────────────────
const searchInputRef = ref(null)
const listRef        = ref(null)
const catBarRef      = ref(null)
const searchOpen     = ref(false)
const searchQuery    = ref('')
const activeCategory = ref(null)
const focusedIdx     = ref(null) // index into selectableList

// ── Derived lists ─────────────────────────────────────────────────────────────
const addedIds = computed(() => new Set(form.exercises.map(e => e.exercise_id)))
function isAdded(id) { return addedIds.value.has(id) }

const categories = computed(() => {
  const groups = [...new Set(allExercises.value.map(e => e.muscle_group).filter(Boolean))]
  return groups.sort((a, b) => a.localeCompare(b, 'pt'))
})

// All exercises visible after applying category + search filters
const visibleExercises = computed(() => {
  let list = allExercises.value

  if (activeCategory.value) {
    list = list.filter(e => e.muscle_group === activeCategory.value)
  }

  const q = searchQuery.value.trim().toLowerCase()
  if (q) {
    list = list.filter(e =>
      e.name.toLowerCase().includes(q) ||
      (e.muscle_group ?? '').toLowerCase().includes(q)
    )
  }

  return list
})

// Show grouped headers only when browsing all (no category, no search)
const showGrouped = computed(() =>
  !activeCategory.value && !searchQuery.value.trim()
)

const groupedVisible = computed(() => {
  const map = {}
  for (const ex of visibleExercises.value) {
    const g = ex.muscle_group || 'Outros'
    if (!map[g]) map[g] = []
    map[g].push(ex)
  }
  return Object.entries(map)
    .sort(([a], [b]) => a.localeCompare(b, 'pt'))
    .map(([name, exercises]) => ({ name, exercises }))
})

// Non-added exercises in order they appear in visibleExercises
const selectableList = computed(() => visibleExercises.value.filter(e => !isAdded(e.id)))

function isFocused(id) {
  return focusedIdx.value !== null && selectableList.value[focusedIdx.value]?.id === id
}

function exerciseRowClass(ex) {
  if (isAdded(ex.id))   return 'bg-brand-50/40 cursor-default'
  if (isFocused(ex.id)) return 'bg-brand-50 cursor-pointer'
  return 'hover:bg-slate-50 cursor-pointer'
}

// ── Picker actions ────────────────────────────────────────────────────────────
async function openSearch() {
  searchOpen.value     = true
  searchQuery.value    = ''
  activeCategory.value = null
  focusedIdx.value     = null
  await ensureExercisesLoaded()
  nextTick(() => searchInputRef.value?.focus())
}

function closeSearch() {
  searchOpen.value  = false
  searchQuery.value = ''
  focusedIdx.value  = null
}

function clearSearch() {
  searchQuery.value = ''
  focusedIdx.value  = null
  searchInputRef.value?.focus()
}

function setCategory(cat) {
  activeCategory.value = cat
  focusedIdx.value     = null
  searchInputRef.value?.focus()
  // Centre the selected pill in the scrollable bar
  nextTick(() => {
    const key = cat ?? '__all__'
    const el  = catBarRef.value?.querySelector(`[data-cat="${CSS.escape(String(key))}"]`)
    el?.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' })
  })
}

// Reset focus when filters change
watch([searchQuery, activeCategory], () => { focusedIdx.value = null })

// ── Keyboard navigation ───────────────────────────────────────────────────────
function onKeyDown(event) {
  const list = selectableList.value

  if (event.key === 'ArrowDown') {
    event.preventDefault()
    if (!list.length) return
    focusedIdx.value = focusedIdx.value === null
      ? 0
      : Math.min(focusedIdx.value + 1, list.length - 1)
    scrollFocusedIntoView()

  } else if (event.key === 'ArrowUp') {
    event.preventDefault()
    if (focusedIdx.value === null || focusedIdx.value === 0) {
      focusedIdx.value = null
    } else {
      focusedIdx.value--
    }
    scrollFocusedIntoView()

  } else if (event.key === 'Enter') {
    event.preventDefault()
    if (focusedIdx.value !== null && list[focusedIdx.value]) {
      // Explicit selection via arrow keys
      addExercise(list[focusedIdx.value])
    } else if (list.length === 1) {
      // Exactly one option visible
      addExercise(list[0])
    }
    // Otherwise: do nothing (ambiguous)

  } else if (event.key === 'Escape') {
    closeSearch()
  }
}

async function scrollFocusedIntoView() {
  await nextTick()
  const focusedId = focusedIdx.value !== null ? selectableList.value[focusedIdx.value]?.id : null
  if (!focusedId || !listRef.value) return
  const el = listRef.value.querySelector(`[data-ex-id="${focusedId}"]`)
  el?.scrollIntoView({ block: 'nearest' })
}

// ── Add / remove exercises ────────────────────────────────────────────────────
function addExercise(ex) {
  if (isAdded(ex.id)) return
  form.exercises.push({
    exercise_id:  ex.id,
    name:         ex.name,
    muscle_group: ex.muscle_group ?? '',
    sets:         3,
    reps:         12,
    rest:         ex.default_rest ?? 60,
  })
  // Stay open, clear search so user can keep adding
  focusedIdx.value  = null
  searchQuery.value = ''
}

function removeExercise(idx) {
  form.exercises.splice(idx, 1)
}

// ── Exercise DnD ──────────────────────────────────────────────────────────────
const exDraggingIdx = ref(null)
const exDragOverIdx = ref(null)

function onExDragStart(idx, event) {
  exDraggingIdx.value = idx
  event.dataTransfer.effectAllowed = 'move'
}
function onExDragEnd() {
  exDraggingIdx.value = null
  exDragOverIdx.value = null
}
function onExDragOver(idx) { exDragOverIdx.value = idx }
function onExDrop(idx) {
  if (exDraggingIdx.value === null || exDraggingIdx.value === idx) {
    exDraggingIdx.value = null; exDragOverIdx.value = null; return
  }
  const arr = [...form.exercises]
  const [moved] = arr.splice(exDraggingIdx.value, 1)
  arr.splice(idx, 0, moved)
  form.exercises = arr
  exDraggingIdx.value = null
  exDragOverIdx.value = null
}

// ── Open watcher ──────────────────────────────────────────────────────────────
watch(() => props.modelValue, async (open) => {
  if (!open) return
  submitError.value    = ''
  searchOpen.value     = false
  activeCategory.value = null
  focusedIdx.value     = null
  Object.keys(errors).forEach(k => delete errors[k])

  if (props.workoutToEdit) {
    form.name        = props.workoutToEdit.name        ?? ''
    form.description = props.workoutToEdit.description ?? ''
    form.level       = props.workoutToEdit.level       ?? ''
    form.duration    = props.workoutToEdit.duration    ?? null
    try {
      const { data } = await api.get(`/admin/workouts/${props.workoutToEdit.id}`)
      form.exercises = (data.exercises ?? []).map(e => ({
        exercise_id:  e.id,
        name:         e.name,
        muscle_group: e.muscle_group ?? '',
        sets:         e.sets  ?? 3,
        reps:         e.reps  ?? 12,
        rest:         e.rest  ?? 60,
      }))
    } catch { form.exercises = [] }
  } else {
    form.name        = ''
    form.description = ''
    form.level       = ''
    form.duration    = null
    form.exercises   = []
  }
})

// ── Submit ────────────────────────────────────────────────────────────────────
function validate() {
  Object.keys(errors).forEach(k => delete errors[k])
  if (!form.name.trim())      errors.name      = 'Nome é obrigatório.'
  if (!form.exercises.length) errors.exercises = 'Adicione pelo menos um exercício.'
  return !Object.keys(errors).length
}

async function submit() {
  if (!validate()) return
  submitting.value  = true
  submitError.value = ''
  try {
    const payload = {
      name:        form.name.trim(),
      description: form.description?.trim() || null,
      level:       form.level    || null,
      duration:    form.duration || null,
      exercises:   form.exercises.map(ex => ({
        exercise_id: ex.exercise_id,
        sets:        ex.sets,
        reps:        ex.reps,
        rest:        ex.rest ?? 60,
      })),
    }
    let workoutData
    if (editMode.value) {
      await api.put(`/admin/workouts/${props.workoutToEdit.id}`, payload)
      workoutData = { id: props.workoutToEdit.id, name: form.name.trim() }
    } else {
      const { data } = await api.post('/admin/workouts', payload)
      workoutData = { id: data.id, name: data.name }
    }
    emit('saved', workoutData)
    close()
  } catch (e) {
    submitError.value = e.response?.data?.message ?? 'Erro ao salvar treino.'
  } finally { submitting.value = false }
}

function close() { emit('update:modelValue', false) }
</script>
