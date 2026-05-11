<template>
  <div>

    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Filiais da Rede</h1>
        <p class="text-slate-500 text-sm mt-1">Gerencie as academias vinculadas à sua rede.</p>
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

    <!-- Loading -->
    <div v-if="loading" class="card animate-pulse">
      <div v-for="n in 4" :key="n" class="flex items-center gap-4 px-5 py-3.5 border-b border-slate-100 last:border-0">
        <div class="h-4 w-40 bg-slate-100 rounded" />
        <div class="h-4 w-24 bg-slate-100 rounded" />
        <div class="ml-auto h-4 w-12 bg-slate-100 rounded" />
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar filiais</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Empty -->
    <div v-else-if="gyms.length === 0" class="card p-12 text-center">
      <p class="text-sm font-semibold text-slate-700">Nenhuma filial cadastrada</p>
      <p class="text-xs text-slate-400 mt-1">Crie a primeira filial clicando em "+ Nova filial".</p>
    </div>

    <!-- Table -->
    <div v-else class="card overflow-hidden">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-100 bg-slate-50/60">
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Nome</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden sm:table-cell">Cidade</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Alunos</th>
            <th class="px-5 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wide">Ações</th>
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
            <td class="px-5 py-3.5 hidden sm:table-cell text-slate-500">{{ gym.city ?? '—' }}</td>
            <td class="px-5 py-3.5">
              <span class="inline-flex items-center justify-center min-w-[2rem] h-6 px-2 rounded-full text-xs font-semibold"
                    :class="gym.students_count > 0 ? 'bg-brand-50 text-brand-700' : 'bg-slate-100 text-slate-400'">
                {{ gym.students_count }}
              </span>
            </td>
            <td class="px-5 py-3.5 text-right">
              <button @click="$router.push(`/network/gyms/${gym.id}/edit`)"
                class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-slate-600
                       border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors
                       opacity-0 group-hover:opacity-100">
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
                </svg>
                Editar
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../services/api.js'

const gyms    = ref([])
const loading = ref(true)
const error   = ref(null)

onMounted(load)

async function load() {
  loading.value = true
  error.value   = null
  try {
    const { data } = await api.get('/network/gyms')
    gyms.value = data.gyms
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao carregar filiais.'
  } finally {
    loading.value = false
  }
}
</script>
