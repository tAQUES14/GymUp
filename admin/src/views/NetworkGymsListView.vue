<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Filiais da Rede</h1>
        <p class="text-slate-500 text-sm mt-1">Gerencie as academias vinculadas a sua rede.</p>
      </div>
      <button @click="$router.push('/network/gyms/new')"
        class="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-semibold text-white
               bg-brand-600 rounded-xl hover:bg-brand-700 transition-colors shadow-sm">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Nova filial
      </button>
    </div>

    <div v-if="loading" class="card animate-pulse">
      <div v-for="n in 4" :key="n" class="flex items-center gap-4 px-5 py-3.5 border-b border-slate-100 last:border-0">
        <div class="h-4 w-40 bg-slate-100 rounded" />
        <div class="h-4 w-24 bg-slate-100 rounded" />
        <div class="ml-auto h-4 w-12 bg-slate-100 rounded" />
      </div>
    </div>

    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar filiais</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <div v-else-if="gyms.length === 0" class="card p-12 text-center">
      <p class="text-sm font-semibold text-slate-700">Nenhuma filial cadastrada</p>
      <p class="text-xs text-slate-400 mt-1">Crie a primeira filial clicando em "+ Nova filial".</p>
    </div>

    <div v-else class="card overflow-hidden">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-100 bg-slate-50/60">
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Nome</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden sm:table-cell">Cidade</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Alunos</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Status</th>
            <th class="px-5 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wide">Acoes</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="gym in gyms" :key="gym.id"
              class="border-b border-slate-100 last:border-0 hover:bg-slate-50/60 transition-colors group">
            <td class="px-5 py-3.5">
              <div class="flex items-center gap-2.5">
                <div class="w-7 h-7 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
                  <svg class="w-3.5 h-3.5 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21" />
                  </svg>
                </div>
                <div>
                  <p class="font-semibold text-slate-800">{{ gym.name }}</p>
                  <p v-if="gym.address" class="text-[11px] text-slate-400 truncate max-w-[16rem]">{{ gym.address }}</p>
                </div>
              </div>
            </td>
            <td class="px-5 py-3.5 hidden sm:table-cell text-slate-500">{{ gym.city ?? '-' }}</td>
            <td class="px-5 py-3.5">
              <span class="inline-flex items-center justify-center min-w-[2rem] h-6 px-2 rounded-full text-xs font-semibold"
                    :class="gym.students_count > 0 ? 'bg-brand-50 text-brand-700' : 'bg-slate-100 text-slate-400'">
                {{ gym.students_count }}
              </span>
            </td>
            <td class="px-5 py-3.5">
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold"
                    :class="gym.active ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'">
                <span class="w-1.5 h-1.5 rounded-full" :class="gym.active ? 'bg-emerald-500' : 'bg-slate-400'" />
                {{ gym.active ? 'Ativa' : 'Congelada' }}
              </span>
            </td>
            <td class="px-5 py-3.5 text-right">
              <div class="inline-flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <button @click="$router.push(`/network/gyms/${gym.id}/edit`)"
                  class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-slate-600
                         border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                  Editar
                </button>
                <button v-if="gym.active" @click="confirmFreeze(gym)"
                  class="inline-flex items-center px-3 py-1.5 text-xs font-semibold text-red-500
                         border border-red-200 rounded-lg hover:bg-red-50 transition-colors">
                  Congelar
                </button>
                <button v-else @click="doReactivate(gym)"
                  class="inline-flex items-center px-3 py-1.5 text-xs font-semibold text-emerald-600
                         border border-emerald-200 rounded-lg hover:bg-emerald-50 transition-colors">
                  Reativar
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="freezeTarget"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
            <h2 class="text-base font-bold text-slate-900 mb-1">Congelar filial</h2>
            <p class="text-sm text-slate-500 mb-4">
              Deseja congelar <strong>{{ freezeTarget.name }}</strong>?
            </p>
            <div class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 mb-5">
              <p class="text-xs font-medium text-amber-800 leading-relaxed">
                A filial ficara inativa, mas alunos, treinos, pontos, check-ins e historico permanecem vinculados a ela.
              </p>
            </div>
            <div class="flex justify-end gap-2">
              <button @click="freezeTarget = null"
                class="px-4 py-2 text-sm font-semibold text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                Cancelar
              </button>
              <button @click="doFreeze" :disabled="freezing"
                class="px-4 py-2 text-sm font-semibold text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors disabled:opacity-60">
                {{ freezing ? 'Congelando...' : 'Congelar filial' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../services/api.js'

const gyms = ref([])
const loading = ref(true)
const error = ref(null)
const freezeTarget = ref(null)
const freezing = ref(false)

onMounted(load)

async function load() {
  loading.value = true
  error.value = null
  try {
    const { data } = await api.get('/network/gyms')
    gyms.value = data.gyms
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao carregar filiais.'
  } finally {
    loading.value = false
  }
}

function confirmFreeze(gym) {
  freezeTarget.value = gym
}

async function doFreeze() {
  if (!freezeTarget.value) return
  freezing.value = true
  try {
    await api.patch(`/network/gyms/${freezeTarget.value.id}/freeze`)
    freezeTarget.value = null
    await load()
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao congelar filial.'
    freezeTarget.value = null
  } finally {
    freezing.value = false
  }
}

async function doReactivate(gym) {
  try {
    await api.patch(`/network/gyms/${gym.id}/reactivate`)
    await load()
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao reativar filial.'
  }
}
</script>

<style scoped>
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s ease; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
</style>
