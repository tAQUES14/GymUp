<template>
  <Teleport to="body">
    <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
      enter-to-class="opacity-100" leave-active-class="transition duration-100"
      leave-from-class="opacity-100" leave-to-class="opacity-0">
      <div class="fixed inset-0 z-[70] flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="emit('close')" />
        <div class="relative z-10 bg-white rounded-2xl shadow-2xl w-full max-w-3xl flex flex-col max-h-[90vh]">

          <!-- Header -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100 flex-shrink-0">
            <div>
              <h3 class="text-base font-semibold text-slate-900">
                {{ exercise.gif_file ? 'Trocar GIF' : 'Vincular GIF' }}
              </h3>
              <p class="text-xs text-slate-500 mt-0.5">{{ exercise.name }} · {{ exercise.muscle_group }}</p>
            </div>
            <button @click="emit('close')"
              class="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Search bar -->
          <div class="px-6 pt-4 pb-3 border-b border-slate-100 flex-shrink-0">
            <div class="relative">
              <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"
                fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
              </svg>
              <input v-model="gifSearch" type="text" placeholder="Filtrar por nome ou pasta…"
                class="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg bg-white
                       focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
            </div>
            <p class="text-xs text-slate-400 mt-2">
              {{ filteredGifs.length }} GIF{{ filteredGifs.length !== 1 ? 's' : '' }}
              disponíve{{ filteredGifs.length !== 1 ? 'is' : 'l' }}
            </p>
          </div>

          <!-- Suggestions strip (hidden when searching) -->
          <div v-if="displaySuggestions.length > 0 && !gifSearch" class="px-4 pt-4 pb-0 flex-shrink-0">
            <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-widest mb-3 flex items-center gap-1.5">
              <svg class="w-3 h-3 text-brand-500" fill="currentColor" viewBox="0 0 20 20">
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
              Sugerido
            </p>
            <div v-if="suggestionsLoading" class="flex items-center gap-2 text-slate-400 text-xs mb-4">
              <svg class="animate-spin w-3.5 h-3.5" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
              </svg>
              Carregando sugestões…
            </div>
            <div v-else class="grid grid-cols-3 gap-3 mb-4">
              <button v-for="sug in displaySuggestions" :key="sug.file"
                @click="selectSuggestion(sug)"
                :class="[
                  'flex flex-col items-start gap-2 p-2 rounded-xl border-2 transition-all text-left w-full',
                  selectedGif?.path === sug.file
                    ? 'border-brand-500 bg-brand-50 shadow-sm'
                    : 'border-slate-200 bg-white hover:border-brand-300 hover:bg-brand-50/40',
                ]">
                <img :src="sug.url" :alt="sug.file"
                  class="w-full h-20 object-contain rounded-lg bg-slate-50 border border-slate-100"
                  loading="lazy" />
                <div class="w-full min-w-0 px-0.5">
                  <div class="flex items-start justify-between gap-1">
                    <p class="text-[11px] font-semibold text-slate-700 truncate leading-tight flex-1">
                      {{ sug.file.split('/').pop().replace(/\.gif$/i, '') }}
                    </p>
                    <span v-if="sug.fallback"
                      class="flex-shrink-0 text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-blue-100 text-blue-600">
                      Popular
                    </span>
                    <span v-else :class="[
                      'flex-shrink-0 text-[10px] font-bold px-1.5 py-0.5 rounded-full',
                      sug.confidence === 'high'   ? 'bg-emerald-100 text-emerald-700'
                        : sug.confidence === 'medium' ? 'bg-amber-100 text-amber-700'
                        : 'bg-slate-100 text-slate-500',
                    ]">{{ sug.score }}%</span>
                  </div>
                  <p class="text-[10px] text-slate-400 truncate mt-0.5">{{ sug.folder }}</p>
                </div>
              </button>
            </div>
            <div class="border-t border-slate-100 mb-4" />
            <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-widest mb-3">Todos os GIFs</p>
          </div>

          <!-- GIF grid -->
          <div class="flex-1 overflow-y-auto p-4" :class="{ 'pt-0': displaySuggestions.length > 0 && !gifSearch }">
            <div v-if="gifCategories.length > 1" class="mb-4 -mx-1 overflow-x-auto pb-1">
              <div class="flex items-center gap-2 px-1">
                <button
                  type="button"
                  @click="selectedFolder = 'all'"
                  :class="[
                    'whitespace-nowrap rounded-full px-3 py-1.5 text-xs font-bold transition-colors',
                    selectedFolder === 'all'
                      ? 'bg-brand-600 text-white shadow-sm'
                      : 'bg-slate-100 text-slate-500 hover:bg-slate-200 hover:text-slate-700',
                  ]">
                  Todos
                  <span class="ml-1 opacity-75">{{ gifCategoryTotal }}</span>
                </button>
                <button
                  v-for="category in gifCategories"
                  :key="category.folder"
                  type="button"
                  @click="selectedFolder = category.folder"
                  :class="[
                    'whitespace-nowrap rounded-full px-3 py-1.5 text-xs font-bold transition-colors',
                    selectedFolder === category.folder
                      ? 'bg-brand-600 text-white shadow-sm'
                      : 'bg-slate-100 text-slate-500 hover:bg-slate-200 hover:text-slate-700',
                  ]">
                  {{ category.label }}
                  <span class="ml-1 opacity-75">{{ category.count }}</span>
                </button>
              </div>
            </div>
            <div v-if="gifsLoading" class="flex items-center justify-center py-16 text-slate-400 gap-2">
              <svg class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
              </svg>
              <span class="text-sm">Carregando GIFs…</span>
            </div>
            <div v-else-if="filteredGifs.length === 0"
              class="text-center py-16 text-sm text-slate-400">
              Nenhum GIF encontrado.
            </div>
            <div v-else class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
              <button v-for="gif in filteredGifs" :key="gif.path"
                @click="selectedGif = gif"
                :class="[
                  'flex flex-col items-start gap-2 p-2 rounded-xl border-2 transition-all text-left w-full',
                  selectedGif?.path === gif.path
                    ? 'border-brand-500 bg-brand-50 shadow-sm'
                    : 'border-transparent bg-slate-50 hover:border-slate-300 hover:bg-slate-100',
                ]">
                <img :src="gif.url" :alt="gif.filename"
                  class="w-full h-20 object-contain rounded-lg bg-white border border-slate-100"
                  loading="lazy" />
                <div class="w-full min-w-0 px-0.5">
                  <p class="text-[11px] font-semibold text-slate-700 truncate leading-tight">{{ gif.filename }}</p>
                  <p class="text-[10px] text-slate-400 truncate mt-0.5">{{ gif.folder }}</p>
                  <p v-if="gif.usage_count > 0"
                    class="text-[10px] text-amber-600 mt-0.5 font-medium">
                    Usado em {{ gif.usage_count }} exercício{{ gif.usage_count !== 1 ? 's' : '' }}
                  </p>
                </div>
              </button>
            </div>
          </div>

          <!-- Selected GIF info bar -->
          <div v-if="selectedGif"
            class="px-6 py-3 border-t border-slate-100 bg-brand-50/60 flex-shrink-0">
            <div class="flex items-center gap-3">
              <img :src="selectedGif.url"
                class="w-10 h-10 object-contain rounded-lg border border-brand-200 bg-white flex-shrink-0" />
              <div class="flex-1 min-w-0">
                <p class="text-xs font-semibold text-brand-800 truncate font-mono">{{ selectedGif.path }}</p>
                <p v-if="selectedGif.usage_count > 0"
                  class="text-[11px] text-amber-600 mt-0.5">
                  Este GIF já está vinculado a {{ selectedGif.usage_count }}
                  exercício{{ selectedGif.usage_count !== 1 ? 's' : '' }}. Pode ser usado mesmo assim.
                </p>
              </div>
            </div>
          </div>

          <!-- Footer -->
          <div class="flex items-center gap-3 px-6 py-4 border-t border-slate-100 flex-shrink-0">
            <p v-if="linkError" class="flex-1 text-xs text-red-500">{{ linkError }}</p>
            <div v-else class="flex-1" />
            <button @click="emit('close')" class="btn-secondary">Cancelar</button>
            <button @click="saveLink" :disabled="!selectedGif || saving"
              class="inline-flex items-center justify-center gap-1.5 px-5 py-2 bg-brand-600
                     text-white text-sm font-semibold rounded-lg hover:bg-brand-700 transition-colors
                     disabled:opacity-60 disabled:cursor-not-allowed shadow-sm">
              <svg v-if="saving" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
              </svg>
              {{ saving ? 'Salvando…' : 'Vincular GIF' }}
            </button>
          </div>

        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '../../services/api.js'

const props = defineProps({
  exercise: { type: Object, required: true },
})

const emit = defineEmits(['linked', 'close'])

const gifs               = ref([])
const suggestions        = ref([])
const gifsLoading        = ref(false)
const suggestionsLoading = ref(false)
const gifSearch          = ref('')
const selectedFolder     = ref('all')
const selectedGif        = ref(null)
const saving             = ref(false)
const linkError          = ref('')

const gifSource = computed(() =>
  gifs.value.length > 0 ? gifs.value : suggestionGifs.value
)

const filteredGifs = computed(() => {
  const q = gifSearch.value.trim().toLowerCase()
  const source = selectedFolder.value === 'all'
    ? gifSource.value
    : gifSource.value.filter((g) => g.folder === selectedFolder.value)

  if (!q) return source

  return source.filter((g) =>
    g.filename.toLowerCase().includes(q) || g.folder.toLowerCase().includes(q)
  )
})

const gifCategories = computed(() => {
  const counts = new Map()

  for (const gif of gifSource.value) {
    if (!gif.folder) continue
    counts.set(gif.folder, (counts.get(gif.folder) ?? 0) + 1)
  }

  return Array.from(counts.entries())
    .map(([folder, count]) => ({
      folder,
      count,
      label: folder.replace(/^Gifs -\s*/i, ''),
    }))
    .sort((a, b) => a.label.localeCompare(b.label, 'pt-BR'))
})

const gifCategoryTotal = computed(() =>
  gifCategories.value.reduce((total, category) => total + category.count, 0)
)

const displaySuggestions = computed(() =>
  suggestions.value.map((sug) => {
    const found = gifs.value.find((gif) => gif.path === sug.file)

    return {
      ...sug,
      url:    found?.url ?? sug.url,
      folder: found?.folder ?? sug.folder,
    }
  })
)

const suggestionGifs = computed(() =>
  displaySuggestions.value.map((sug) => ({
    path:        sug.file,
    url:         sug.url,
    folder:      sug.folder,
    filename:    sug.file.split('/').pop().replace(/\.gif$/i, ''),
    usage_count: 0,
  }))
)

onMounted(() => {
  loadGifsAndSuggestions()
})

async function loadGifsAndSuggestions() {
  // Fetch both in parallel
  gifsLoading.value        = true
  suggestionsLoading.value = true

  const [gifsResult, sugResult] = await Promise.allSettled([
    api.get('/admin/exercises/available-gifs'),
    api.get(`/admin/exercises/${props.exercise.id}/suggest-gifs`),
  ])

  if (gifsResult.status === 'fulfilled') {
    gifs.value = gifsResult.value.data.gifs ?? []
    // Pre-select current GIF if exercise already has one
    if (props.exercise.gif_file) {
      const current = gifs.value.find((g) => g.path === props.exercise.gif_file)
      selectedGif.value = current ?? {
        path:        props.exercise.gif_file,
        url:         props.exercise.gif_url ?? '',
        folder:      props.exercise.gif_file.split('/')[0] ?? '',
        filename:    props.exercise.gif_file.split('/').pop().replace(/\.gif$/i, ''),
        usage_count: 0,
      }
    }
  }

  if (sugResult.status === 'fulfilled') {
    suggestions.value = sugResult.value.data.suggestions ?? []
  }

  gifsLoading.value        = false
  suggestionsLoading.value = false
}

function selectSuggestion(sug) {
  const found = gifs.value.find((g) => g.path === sug.file)
  selectedGif.value = found ?? {
    path:        sug.file,
    url:         sug.url,
    folder:      sug.folder,
    filename:    sug.file.split('/').pop().replace(/\.gif$/i, ''),
    usage_count: 0,
  }
}

async function saveLink() {
  if (!selectedGif.value) return
  saving.value    = true
  linkError.value = ''
  try {
    const { data } = await api.post(`/admin/exercises/${props.exercise.id}/link-gif`, {
      gif_file: selectedGif.value.path,
    })
    emit('linked', data.exercise)
  } catch (e) {
    linkError.value = e.response?.data?.message ?? 'Erro ao vincular GIF.'
  } finally {
    saving.value = false
  }
}
</script>
