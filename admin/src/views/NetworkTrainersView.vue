<template>
  <div>

    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Trainers da Rede</h1>
        <p class="text-slate-500 text-sm mt-1">Visualize, crie e gerencie as filiais vinculadas a cada trainer.</p>
      </div>
      <button @click="openCreate"
        class="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-brand-600 hover:bg-brand-700 rounded-lg transition-colors">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Criar trainer
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="card animate-pulse">
      <div v-for="n in 3" :key="n" class="flex items-center gap-4 px-5 py-4 border-b border-slate-100 last:border-0">
        <div class="w-9 h-9 rounded-full bg-slate-100 flex-shrink-0" />
        <div class="flex-1 space-y-2">
          <div class="h-4 w-36 bg-slate-100 rounded" />
          <div class="h-3 w-24 bg-slate-100 rounded" />
        </div>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar trainers</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Empty -->
    <div v-else-if="trainers.length === 0" class="card p-12 text-center">
      <p class="text-sm font-semibold text-slate-700">Nenhum trainer encontrado</p>
      <p class="text-xs text-slate-400 mt-1">Trainers são vinculados às filiais via o painel de cada academia.</p>
    </div>

    <!-- List -->
    <div v-else class="card overflow-hidden">
      <ul>
        <li v-for="trainer in trainers" :key="trainer.id"
            class="flex items-center gap-4 px-5 py-4 border-b border-slate-100 last:border-0 hover:bg-slate-50/60 transition-colors group">

          <!-- Avatar -->
          <div class="w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold text-white flex-shrink-0"
               :style="{ backgroundColor: avatarColor(trainer.name) }">
            {{ trainer.name[0].toUpperCase() }}
          </div>

          <!-- Info -->
          <div class="flex-1 min-w-0">
            <p class="text-sm font-semibold text-slate-800">{{ trainer.name }}</p>
            <p class="text-xs text-slate-400 mt-0.5">{{ trainer.email }}</p>
            <div class="flex flex-wrap gap-1 mt-1.5">
              <span v-for="gym in trainer.gyms" :key="gym.id"
                class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold bg-brand-50 text-brand-700">
                {{ gym.name }}
              </span>
            </div>
          </div>

          <!-- Manage button -->
          <button @click="openManage(trainer)"
            class="opacity-0 group-hover:opacity-100 transition-opacity shrink-0
                   inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold
                   text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10.343 3.94c.09-.542.56-.94 1.11-.94h1.093c.55 0 1.02.398 1.11.94l.149.894c.07.424.384.764.78.93.398.164.855.142 1.205-.108l.737-.527a1.125 1.125 0 011.45.12l.773.774c.39.389.44 1.002.12 1.45l-.527.737c-.25.35-.272.806-.107 1.204.165.397.505.71.93.78l.893.15c.543.09.94.56.94 1.109v1.094c0 .55-.397 1.02-.94 1.11l-.893.149c-.425.07-.765.383-.93.78-.165.398-.143.854.107 1.204l.527.738c.32.447.269 1.06-.12 1.45l-.774.773a1.125 1.125 0 01-1.449.12l-.738-.527c-.35-.25-.806-.272-1.203-.107-.397.165-.71.505-.781.929l-.149.894c-.09.542-.56.94-1.11.94h-1.094c-.55 0-1.019-.398-1.11-.94l-.148-.894c-.071-.424-.384-.764-.781-.93-.398-.164-.854-.142-1.204.108l-.738.527c-.447.32-1.06.269-1.45-.12l-.773-.774a1.125 1.125 0 01-.12-1.45l.527-.737c.25-.35.273-.806.108-1.204-.165-.397-.505-.71-.93-.78l-.894-.15c-.542-.09-.94-.56-.94-1.109v-1.094c0-.55.398-1.02.94-1.11l.894-.149c.424-.07.765-.383.93-.78.165-.398.143-.854-.108-1.204l-.526-.738a1.125 1.125 0 01.12-1.45l.773-.773a1.125 1.125 0 011.45-.12l.737.527c.35.25.807.272 1.204.107.397-.165.71-.505.78-.929l.15-.894z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            Gerenciar filiais
          </button>

        </li>
      </ul>
    </div>

    <!-- ── CREATE TRAINER MODAL ─────────────────────────────────────────── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showCreate"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm">

            <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
              <h2 class="text-base font-bold text-slate-900">Criar trainer</h2>
              <button @click="showCreate = false"
                class="p-1 text-slate-400 hover:text-slate-600 rounded transition-colors">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <form @submit.prevent="submitCreate" class="p-5 space-y-4">
              <p v-if="createError" class="text-xs text-red-500">{{ createError }}</p>

              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Nome</label>
                <input v-model="createForm.name" type="text" required
                  class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500" />
              </div>

              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Email</label>
                <input v-model="createForm.email" type="email" required
                  class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500" />
              </div>

              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1">Filial principal</label>
                <select v-model="createForm.gym_id" required
                  class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-500">
                  <option value="" disabled>Selecione a filial</option>
                  <option v-for="gym in allGyms" :key="gym.id" :value="gym.id">{{ gym.name }}</option>
                </select>
              </div>

              <div class="flex justify-end gap-2 pt-2">
                <button type="button" @click="showCreate = false"
                  class="px-4 py-2 text-sm font-semibold text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                  Cancelar
                </button>
                <button type="submit" :disabled="createLoading"
                  class="px-4 py-2 text-sm font-semibold text-white bg-brand-600 hover:bg-brand-700 rounded-lg transition-colors disabled:opacity-50">
                  {{ createLoading ? 'Criando...' : 'Criar' }}
                </button>
              </div>
            </form>

          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- Exibe senha temporária após criação -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="createdPassword"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6 text-center">
            <div class="w-12 h-12 rounded-full bg-green-50 flex items-center justify-center mx-auto mb-3">
              <svg class="w-6 h-6 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
              </svg>
            </div>
            <h3 class="text-base font-bold text-slate-900 mb-1">Trainer criado!</h3>
            <p class="text-xs text-slate-500 mb-4">Compartilhe a senha temporária com o trainer:</p>
            <div class="bg-slate-50 border border-slate-200 rounded-lg px-4 py-3 mb-4 font-mono text-lg font-bold text-slate-800 tracking-widest">
              {{ createdPassword }}
            </div>
            <p class="text-xs text-slate-400 mb-4">O trainer deverá trocar a senha no primeiro acesso.</p>
            <button @click="createdPassword = null"
              class="px-5 py-2 text-sm font-semibold text-white bg-brand-600 hover:bg-brand-700 rounded-lg transition-colors">
              Fechar
            </button>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ── MANAGE MODAL ──────────────────────────────────────────────────── -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="manageTarget"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm">

            <div class="flex items-center justify-between px-5 py-4 border-b border-slate-100">
              <div>
                <h2 class="text-base font-bold text-slate-900">Filiais de {{ manageTarget.name }}</h2>
                <p class="text-xs text-slate-400 mt-0.5">Marque as filiais vinculadas</p>
              </div>
              <button @click="manageTarget = null"
                class="p-1 text-slate-400 hover:text-slate-600 rounded transition-colors">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div class="p-5">
              <p v-if="modalError" class="text-xs text-red-500 mb-3">{{ modalError }}</p>
              <p v-if="atLeastOneError" class="text-xs text-amber-600 mb-3 flex items-center gap-1">
                <svg class="w-3.5 h-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                </svg>
                O trainer deve estar em pelo menos uma filial.
              </p>

              <ul class="space-y-2 max-h-64 overflow-y-auto">
                <li v-for="gym in allGyms" :key="gym.id">
                  <label class="flex items-center gap-3 p-2.5 rounded-lg hover:bg-slate-50 cursor-pointer transition-colors">
                    <input type="checkbox"
                      :checked="checkedGyms.has(gym.id)"
                      @change="toggleGym(gym.id)"
                      class="w-4 h-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500" />
                    <span class="text-sm font-medium text-slate-700">{{ gym.name }}</span>
                    <span v-if="gym.city" class="text-xs text-slate-400">{{ gym.city }}</span>
                  </label>
                </li>
              </ul>
            </div>

            <div class="flex justify-end gap-2 px-5 pb-5">
              <button @click="manageTarget = null"
                class="px-4 py-2 text-sm font-semibold text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                Fechar
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

const trainers = ref([])
const allGyms  = ref([])
const loading  = ref(true)
const error    = ref(null)

const manageTarget    = ref(null)
const checkedGyms     = ref(new Set())
const modalError      = ref(null)
const atLeastOneError = ref(false)

// Create trainer
const showCreate     = ref(false)
const createLoading  = ref(false)
const createError    = ref(null)
const createForm     = ref({ name: '', email: '', gym_id: '' })
const createdPassword = ref(null)

function openCreate() {
  createForm.value  = { name: '', email: '', gym_id: '' }
  createError.value = null
  showCreate.value  = true
}

async function submitCreate() {
  createLoading.value = true
  createError.value   = null
  try {
    const { data } = await api.post('/network/trainers', createForm.value)
    trainers.value.push(data.trainer)
    createdPassword.value = data.temp_password
    showCreate.value      = false
  } catch (e) {
    createError.value = e.response?.data?.message ?? 'Erro ao criar trainer.'
  } finally {
    createLoading.value = false
  }
}

const AVATAR_COLORS = ['#3B82F6','#8B5CF6','#10B981','#F59E0B','#EF4444','#06B6D4','#6366F1','#14B8A6']
function avatarColor(name) {
  const code = [...(name ?? 'A')].reduce((a, c) => a + c.charCodeAt(0), 0)
  return AVATAR_COLORS[code % AVATAR_COLORS.length]
}

onMounted(load)

async function load() {
  loading.value = true
  error.value   = null
  try {
    const [tRes, gRes] = await Promise.all([
      api.get('/network/trainers'),
      api.get('/network/gyms'),
    ])
    trainers.value = tRes.data.trainers
    allGyms.value  = gRes.data.gyms
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao carregar trainers.'
  } finally {
    loading.value = false
  }
}

function openManage(trainer) {
  manageTarget.value    = trainer
  checkedGyms.value     = new Set(trainer.gyms.map(g => g.id))
  modalError.value      = null
  atLeastOneError.value = false
}

async function toggleGym(gymId) {
  if (!manageTarget.value) return
  atLeastOneError.value = false
  modalError.value      = null

  const isLinked = checkedGyms.value.has(gymId)

  if (isLinked) {
    if (checkedGyms.value.size <= 1) {
      atLeastOneError.value = true
      return
    }
    try {
      await api.delete(`/network/trainers/${manageTarget.value.id}/gyms/${gymId}`)
      checkedGyms.value.delete(gymId)
      // update local trainer gyms list
      manageTarget.value.gyms = manageTarget.value.gyms.filter(g => g.id !== gymId)
      // sync trainers list
      const t = trainers.value.find(t => t.id === manageTarget.value.id)
      if (t) t.gyms = t.gyms.filter(g => g.id !== gymId)
    } catch (e) {
      modalError.value = e.response?.data?.message ?? 'Erro ao desvincular.'
    }
  } else {
    try {
      await api.post(`/network/trainers/${manageTarget.value.id}/gyms`, { gym_id: gymId })
      checkedGyms.value.add(gymId)
      const gym = allGyms.value.find(g => g.id === gymId)
      if (gym) {
        manageTarget.value.gyms.push({ id: gym.id, name: gym.name })
        const t = trainers.value.find(t => t.id === manageTarget.value.id)
        if (t) t.gyms.push({ id: gym.id, name: gym.name })
      }
    } catch (e) {
      modalError.value = e.response?.data?.message ?? 'Erro ao vincular.'
    }
  }
}
</script>

<style scoped>
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s ease; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
</style>
