<template>
  <div>

    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Redes</h1>
        <p class="text-slate-500 text-sm mt-1">Gerencie as redes de academias da plataforma.</p>
      </div>
      <button @click="$router.push('/chains/new')"
        class="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-semibold text-white
               bg-brand-600 rounded-xl hover:bg-brand-700 active:bg-brand-800 transition-colors shadow-sm">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Nova rede
      </button>
    </div>

    <!-- Search -->
    <div class="mb-4">
      <div class="relative max-w-sm">
        <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400"
             fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
        </svg>
        <input v-model="searchInput" type="text" placeholder="Buscar por nome..."
          class="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg
                 focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400" />
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card animate-pulse">
      <div v-for="n in 5" :key="n" class="flex items-center gap-4 px-5 py-3.5 border-b border-slate-100 last:border-0">
        <div class="h-4 w-40 bg-slate-100 rounded" />
        <div class="h-4 w-24 bg-slate-100 rounded" />
        <div class="ml-auto h-4 w-16 bg-slate-100 rounded" />
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar redes</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Empty -->
    <div v-else-if="chains.length === 0" class="card p-12 text-center">
      <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
        <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700">Nenhuma rede encontrada</p>
      <p class="text-xs text-slate-400 mt-1">Crie a primeira rede clicando em "+ Nova rede".</p>
    </div>

    <!-- Table -->
    <div v-else class="card overflow-hidden">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-100 bg-slate-50/60">
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Nome</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden md:table-cell">Slug</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Filiais</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden sm:table-cell">Criada em</th>
            <th class="px-5 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wide">Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="chain in chains" :key="chain.id"
              class="border-b border-slate-100 last:border-0 hover:bg-slate-50/60 transition-colors group">
            <td class="px-5 py-3.5">
              <div class="flex items-center gap-2.5">
                <img v-if="chain.logo_url" :src="chain.logo_url" :alt="chain.name"
                  class="w-6 h-6 rounded object-cover flex-shrink-0" />
                <div v-else class="w-6 h-6 rounded bg-brand-100 flex items-center justify-center flex-shrink-0">
                  <span class="text-brand-700 text-[10px] font-bold">{{ chain.name[0] }}</span>
                </div>
                <span class="font-semibold text-slate-800">{{ chain.name }}</span>
              </div>
            </td>
            <td class="px-5 py-3.5 hidden md:table-cell">
              <code class="text-xs text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded">{{ chain.slug }}</code>
            </td>
            <td class="px-5 py-3.5">
              <span class="inline-flex items-center justify-center min-w-[2rem] h-6 px-2 rounded-full text-xs font-semibold"
                    :class="chain.gyms_count > 0 ? 'bg-brand-50 text-brand-700' : 'bg-slate-100 text-slate-400'">
                {{ chain.gyms_count }}
              </span>
            </td>
            <td class="px-5 py-3.5 hidden sm:table-cell text-slate-500">{{ chain.created_at }}</td>
            <td class="px-5 py-3.5 text-right">
              <div class="inline-flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <button @click="$router.push(`/chains/${chain.id}`)"
                  class="p-1.5 text-slate-500 hover:text-brand-600 hover:bg-brand-50 rounded-lg transition-colors"
                  title="Ver detalhes">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.964-7.178z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </button>
                <button @click="$router.push(`/chains/${chain.id}/edit`)"
                  class="p-1.5 text-slate-500 hover:text-slate-700 hover:bg-slate-100 rounded-lg transition-colors"
                  title="Editar">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
                  </svg>
                </button>
                <button @click="confirmDelete(chain)"
                  class="p-1.5 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                  title="Excluir">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
                  </svg>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div v-if="meta.last_page > 1" class="flex items-center justify-between px-5 py-3 border-t border-slate-100">
        <p class="text-xs text-slate-500">{{ meta.total }} redes · página {{ meta.current_page }} de {{ meta.last_page }}</p>
        <div class="flex gap-1">
          <button :disabled="meta.current_page <= 1" @click="page--"
            class="px-2.5 py-1 text-xs font-medium rounded-lg border border-slate-200
                   disabled:opacity-40 hover:bg-slate-50 transition-colors">
            Anterior
          </button>
          <button :disabled="meta.current_page >= meta.last_page" @click="page++"
            class="px-2.5 py-1 text-xs font-medium rounded-lg border border-slate-200
                   disabled:opacity-40 hover:bg-slate-50 transition-colors">
            Próxima
          </button>
        </div>
      </div>
    </div>

    <!-- Delete Confirm Modal -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="deleteTarget"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
            <h2 class="text-lg font-bold text-slate-900 mb-1">Excluir rede</h2>
            <p class="text-sm text-slate-500 mb-3">
              Tem certeza que deseja excluir <strong>{{ deleteTarget.name }}</strong>?
            </p>
            <div class="flex items-start gap-2.5 p-3 rounded-lg bg-amber-50 border border-amber-200 mb-5">
              <svg class="w-4 h-4 text-amber-600 mt-0.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
              </svg>
              <p class="text-xs text-amber-700">
                As <strong>{{ deleteTarget.gyms_count }}</strong> filiais desta rede ficarão independentes.
              </p>
            </div>
            <div class="flex justify-end gap-2">
              <button @click="deleteTarget = null"
                class="px-4 py-2 text-sm font-semibold text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                Cancelar
              </button>
              <button @click="doDelete" :disabled="deleting"
                class="px-4 py-2 text-sm font-semibold text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors disabled:opacity-60">
                {{ deleting ? 'Excluindo…' : 'Excluir' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue'
import api from '../services/api.js'

const chains      = ref([])
const meta        = ref({ current_page: 1, last_page: 1, per_page: 20, total: 0 })
const loading     = ref(false)
const error       = ref(null)
const searchInput = ref('')
const page        = ref(1)
const deleteTarget = ref(null)
const deleting    = ref(false)

let searchTimer = null

watch(searchInput, () => {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => { page.value = 1; load() }, 350)
})

watch(page, load)

onMounted(load)

async function load() {
  loading.value = true
  error.value   = null
  try {
    const params = new URLSearchParams({ page: page.value, per_page: 20 })
    if (searchInput.value.trim()) params.set('search', searchInput.value.trim())
    const { data } = await api.get(`/super/chains?${params}`)
    chains.value = data.data
    meta.value   = data.meta
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao carregar redes.'
  } finally {
    loading.value = false
  }
}

function confirmDelete(chain) {
  deleteTarget.value = chain
}

async function doDelete() {
  if (!deleteTarget.value) return
  deleting.value = true
  try {
    await api.delete(`/super/chains/${deleteTarget.value.id}`)
    deleteTarget.value = null
    await load()
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao excluir rede.'
    deleteTarget.value = null
  } finally {
    deleting.value = false
  }
}
</script>

<style scoped>
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s ease; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
</style>
