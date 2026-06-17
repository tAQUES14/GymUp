<template>
  <div>
    <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 mb-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Academias</h1>
        <p class="text-slate-500 text-sm mt-1">Vis&atilde;o global das academias cadastradas na plataforma.</p>
      </div>

      <div class="flex flex-col sm:flex-row gap-3 w-full lg:w-auto">
        <div class="relative w-full lg:w-80">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400"
              fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input v-model="searchInput" type="text" placeholder="Buscar academia, cidade ou rede..."
            class="w-full pl-9 pr-4 py-2.5 text-sm border border-slate-200 rounded-xl bg-white
                  focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400" />
        </div>

        <button @click="openCreateModal"
          class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-brand-600 text-white text-sm font-bold shadow-sm hover:bg-brand-700 transition-colors whitespace-nowrap">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 5v14m7-7H5" />
          </svg>
          Nova academia
        </button>
      </div>
    </div>

    <div class="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
      <SummaryCard label="Total" :value="summary.total" color="brand" />
      <SummaryCard label="Ativas" :value="summary.active" color="emerald" />
      <SummaryCard label="Em redes" :value="summary.in_chains" color="violet" />
      <SummaryCard label="Independentes" :value="summary.independent" color="amber" />
    </div>

    <div v-if="loading" class="card animate-pulse">
      <div v-for="n in 7" :key="n" class="flex items-center gap-4 px-5 py-4 border-b border-slate-100 last:border-0">
        <div class="w-10 h-10 rounded-xl bg-slate-100" />
        <div class="flex-1 space-y-2">
          <div class="h-4 w-44 bg-slate-100 rounded" />
          <div class="h-3 w-28 bg-slate-100 rounded" />
        </div>
        <div class="hidden md:block h-4 w-24 bg-slate-100 rounded" />
        <div class="h-6 w-16 bg-slate-100 rounded-full" />
      </div>
    </div>

    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar academias</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <div v-else-if="gyms.length === 0" class="card p-12 text-center">
      <div class="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-slate-100 mb-3">
        <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M2.25 21h19.5m-18-18v18m10.5-18v18m6-13.5V21M6.75 6.75h.75m-.75 3h.75m-.75 3h.75m3-6h.75m-.75 3h.75m-.75 3h.75M6.75 21v-3.375c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21M3 3h12m-.75 4.5H21" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700">Nenhuma academia encontrada</p>
      <p class="text-xs text-slate-400 mt-1">
        {{ searchInput ? 'Ajuste a busca para encontrar outras academias.' : 'Ainda não há academias cadastradas.' }}
      </p>
    </div>

    <div v-else class="card overflow-hidden">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-100 bg-slate-50/70">
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Academia</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden lg:table-cell">Rede</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden md:table-cell">Equipe</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Alunos</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide hidden xl:table-cell">Convite</th>
            <th class="px-5 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Status</th>
            <th class="px-5 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wide">A&ccedil;&otilde;es</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="gym in gyms" :key="gym.id"
              class="border-b border-slate-100 last:border-0 hover:bg-slate-50/60 transition-colors">
            <td class="px-5 py-4">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-2xl bg-brand-50 flex items-center justify-center flex-shrink-0">
                  <span class="text-brand-700 text-sm font-bold">{{ initials(gym.name) }}</span>
                </div>
                <div class="min-w-0">
                  <p class="font-semibold text-slate-900 truncate">{{ gym.name }}</p>
                  <p class="text-xs text-slate-400 truncate">
                    {{ [gym.city, gym.email].filter(Boolean).join(' · ') || 'Sem cidade/email' }}
                  </p>
                </div>
              </div>
            </td>
            <td class="px-5 py-4 hidden lg:table-cell">
              <span v-if="gym.chain"
                class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-violet-50 text-violet-700">
                {{ gym.chain.name }}
              </span>
              <span v-else class="text-xs font-medium text-slate-400">Independente</span>
            </td>
            <td class="px-5 py-4 hidden md:table-cell">
              <div class="flex flex-col gap-0.5 text-xs">
                <span class="font-semibold text-slate-700">{{ gym.admins_count }} admin{{ gym.admins_count !== 1 ? 's' : '' }}</span>
                <span class="text-slate-400">{{ gym.trainers_count }} trainer{{ gym.trainers_count !== 1 ? 's' : '' }}</span>
              </div>
            </td>
            <td class="px-5 py-4">
              <span class="inline-flex items-center justify-center min-w-[2.25rem] h-7 px-2 rounded-full text-xs font-bold"
                    :class="gym.students_count > 0 ? 'bg-brand-50 text-brand-700' : 'bg-slate-100 text-slate-400'">
                {{ gym.students_count }}
              </span>
            </td>
            <td class="px-5 py-4 hidden xl:table-cell">
              <code class="text-xs text-slate-500 bg-slate-100 px-2 py-1 rounded-lg">{{ gym.invite_code ?? '-' }}</code>
            </td>
            <td class="px-5 py-4">
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold"
                    :class="gym.active ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'">
                <span class="w-1.5 h-1.5 rounded-full" :class="gym.active ? 'bg-emerald-500' : 'bg-slate-400'" />
                {{ gym.active ? 'Ativa' : 'Inativa' }}
              </span>
            </td>
            <td class="px-5 py-4 text-right">
              <button
                v-if="gym.chain"
                @click="confirmUnlink(gym)"
                class="inline-flex items-center justify-center px-3 py-1.5 text-xs font-semibold text-red-500
                       border border-red-200 rounded-lg hover:bg-red-50 transition-colors"
              >
                Desvincular
              </button>
              <span v-else class="text-xs font-medium text-slate-300">-</span>
            </td>
          </tr>
        </tbody>
      </table>

      <div v-if="meta.last_page > 1" class="flex items-center justify-between px-5 py-3 border-t border-slate-100">
        <p class="text-xs text-slate-500">{{ meta.total }} academias &middot; p&aacute;gina {{ meta.current_page }} de {{ meta.last_page }}</p>
        <div class="flex gap-1">
          <button :disabled="meta.current_page <= 1" @click="page--"
            class="px-2.5 py-1 text-xs font-medium rounded-lg border border-slate-200
                   disabled:opacity-40 hover:bg-slate-50 transition-colors">
            Anterior
          </button>
          <button :disabled="meta.current_page >= meta.last_page" @click="page++"
            class="px-2.5 py-1 text-xs font-medium rounded-lg border border-slate-200
                   disabled:opacity-40 hover:bg-slate-50 transition-colors">
            Pr&oacute;xima
          </button>
        </div>
      </div>
    </div>

    <Teleport to="body">
      <Transition name="modal">
        <div v-if="createModalOpen"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div class="bg-white rounded-3xl shadow-2xl w-full max-w-2xl overflow-hidden">
            <div class="px-6 py-5 border-b border-slate-100 flex items-start justify-between gap-4">
              <div>
                <h2 class="text-lg font-bold text-slate-900">Nova academia</h2>
                <p class="text-sm text-slate-500 mt-1">Cadastre uma unidade independente ou vinculada a uma rede.</p>
              </div>
              <button @click="closeCreateModal"
                class="w-9 h-9 rounded-full bg-slate-50 text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors">
                ×
              </button>
            </div>

            <form @submit.prevent="createGym" class="p-6 space-y-5">
              <div class="grid grid-cols-2 gap-3">
                <button type="button" @click="createForm.kind = 'independent'"
                  class="text-left rounded-2xl border p-4 transition-colors"
                  :class="createForm.kind === 'independent'
                    ? 'border-brand-400 bg-brand-50 text-brand-800'
                    : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'">
                  <p class="text-sm font-bold">Independente</p>
                  <p class="text-xs mt-1 leading-relaxed">Academia sem rede acima, com convite e QR próprios.</p>
                </button>
                <button type="button" @click="createForm.kind = 'chain'"
                  class="text-left rounded-2xl border p-4 transition-colors"
                  :class="createForm.kind === 'chain'
                    ? 'border-violet-400 bg-violet-50 text-violet-800'
                    : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'">
                  <p class="text-sm font-bold">Unidade de rede</p>
                  <p class="text-xs mt-1 leading-relaxed">Filial vinculada a uma rede já cadastrada.</p>
                </button>
              </div>

              <div v-if="createForm.kind === 'chain'">
                <label class="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1.5">Rede</label>
                <select v-model="createForm.chain_id"
                  class="w-full px-3.5 py-2.5 text-sm border rounded-xl bg-white focus:outline-none focus:ring-2 transition-colors"
                  :class="createErrors.chain_id ? 'border-red-300 focus:ring-red-500/20' : 'border-slate-200 focus:ring-brand-500/30 focus:border-brand-400'">
                  <option value="">Selecione uma rede</option>
                  <option v-for="chain in activeChains" :key="chain.id" :value="chain.id">{{ chain.name }}</option>
                </select>
                <p v-if="createErrors.chain_id" class="text-xs text-red-500 mt-1">{{ createErrors.chain_id }}</p>
                <p v-else-if="activeChains.length === 0" class="text-xs text-amber-600 mt-1">Crie uma rede ativa antes de cadastrar uma filial.</p>
              </div>

              <div class="grid md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1.5">Nome da academia</label>
                  <input v-model="createForm.name" type="text" placeholder="Ex: TNT Guamiranga"
                    class="w-full px-3.5 py-2.5 text-sm border rounded-xl focus:outline-none focus:ring-2 transition-colors"
                    :class="createErrors.name ? 'border-red-300 focus:ring-red-500/20' : 'border-slate-200 focus:ring-brand-500/30 focus:border-brand-400'" />
                  <p v-if="createErrors.name" class="text-xs text-red-500 mt-1">{{ createErrors.name }}</p>
                </div>
                <div>
                  <label class="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1.5">Cidade</label>
                  <input v-model="createForm.city" type="text" placeholder="Ex: Guamiranga"
                    class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors" />
                </div>
                <div>
                  <label class="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1.5">E-mail</label>
                  <input v-model="createForm.email" type="email" placeholder="contato@academia.com"
                    class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors" />
                </div>
                <div>
                  <label class="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1.5">Telefone</label>
                  <input v-model="createForm.phone" type="text" placeholder="(42) 99999-9999"
                    class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors" />
                </div>
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1.5">Endereço</label>
                <input v-model="createForm.address" type="text" placeholder="Rua, número e bairro"
                  class="w-full px-3.5 py-2.5 text-sm border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-500/30 focus:border-brand-400 transition-colors" />
              </div>

              <label class="flex items-center justify-between gap-4 p-4 rounded-2xl bg-slate-50 border border-slate-100">
                <div>
                  <p class="text-sm font-bold text-slate-800">Academia ativa</p>
                  <p class="text-xs text-slate-500 mt-0.5">Alunos poderão entrar pelo convite assim que ele for enviado.</p>
                </div>
                <input v-model="createForm.active" type="checkbox" class="h-5 w-5 accent-brand-600" />
              </label>

              <div v-if="createError" class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600">
                {{ createError }}
              </div>

              <div class="flex items-center justify-end gap-3 pt-2 border-t border-slate-100">
                <button type="button" @click="closeCreateModal"
                  class="px-4 py-2.5 text-sm font-semibold text-slate-600 border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors">
                  Cancelar
                </button>
                <button type="submit" :disabled="creating"
                  class="px-5 py-2.5 text-sm font-bold text-white bg-brand-600 rounded-xl hover:bg-brand-700 transition-colors disabled:opacity-60">
                  {{ creating ? 'Criando...' : 'Criar academia' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      </Transition>

      <Transition name="modal">
        <div v-if="unlinkTarget"
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
          <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
            <h2 class="text-base font-bold text-slate-900 mb-1">Desvincular academia da rede</h2>
            <p class="text-sm text-slate-500 mb-4">
              Deseja remover <strong>{{ unlinkTarget.name }}</strong> da rede
              <strong>{{ unlinkTarget.chain?.name }}</strong>?
            </p>
            <div class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 mb-5">
              <p class="text-xs font-medium text-amber-800 leading-relaxed">
                A academia continuar&aacute; ativa. Alunos, treinos, pontos, check-ins e hist&oacute;rico permanecem vinculados a ela.
              </p>
            </div>
            <div class="flex justify-end gap-2">
              <button @click="unlinkTarget = null"
                class="px-4 py-2 text-sm font-semibold text-slate-600 border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
                Cancelar
              </button>
              <button @click="doUnlink" :disabled="unlinking"
                class="px-4 py-2 text-sm font-semibold text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors disabled:opacity-60">
                {{ unlinking ? 'Desvinculando...' : 'Desvincular' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup>
import { defineComponent, h, ref, watch, onMounted } from 'vue'
import api from '../services/api.js'

const SummaryCard = defineComponent({
  props: {
    label: { type: String, required: true },
    value: { type: Number, default: 0 },
    color: { type: String, default: 'brand' },
  },
  setup(props) {
    const colors = {
      brand: 'bg-brand-50 text-brand-700',
      emerald: 'bg-emerald-50 text-emerald-700',
      violet: 'bg-violet-50 text-violet-700',
      amber: 'bg-amber-50 text-amber-700',
    }

    return () => h('div', { class: 'card px-4 py-3.5' }, [
      h('p', { class: 'text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1' }, props.label),
      h('div', { class: 'flex items-center gap-2' }, [
        h('span', { class: ['w-2 h-2 rounded-full', colors[props.color] ?? colors.brand] }),
        h('p', { class: 'text-2xl font-bold text-slate-900 tracking-tight' }, props.value.toLocaleString('pt-BR')),
      ]),
    ])
  },
})

const gyms = ref([])
const summary = ref({ total: 0, active: 0, independent: 0, in_chains: 0 })
const meta = ref({ current_page: 1, last_page: 1, per_page: 20, total: 0 })
const loading = ref(false)
const error = ref(null)
const searchInput = ref('')
const page = ref(1)
const unlinkTarget = ref(null)
const unlinking = ref(false)
const createModalOpen = ref(false)
const creating = ref(false)
const createError = ref(null)
const createErrors = ref({})
const activeChains = ref([])
const createForm = ref(defaultCreateForm())
let searchTimer = null

watch(searchInput, () => {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    page.value = 1
    load()
  }, 350)
})

watch(page, load)
onMounted(load)

function initials(name) {
  return (name ?? 'A')
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join('')
    .toUpperCase()
}

function defaultCreateForm() {
  return {
    kind: 'independent',
    chain_id: '',
    name: '',
    city: '',
    email: '',
    phone: '',
    address: '',
    active: true,
  }
}

async function openCreateModal() {
  createForm.value = defaultCreateForm()
  createError.value = null
  createErrors.value = {}
  createModalOpen.value = true
  await loadChains()
}

function closeCreateModal() {
  if (creating.value) return
  createModalOpen.value = false
}

async function loadChains() {
  try {
    const { data } = await api.get('/super/chains?per_page=100')
    activeChains.value = (data.data ?? []).filter((chain) => chain.status !== 'closed')
  } catch {
    activeChains.value = []
  }
}

function validateCreateForm() {
  createErrors.value = {}

  if (!createForm.value.name.trim()) {
    createErrors.value.name = 'Informe o nome da academia.'
  }

  if (createForm.value.kind === 'chain' && !createForm.value.chain_id) {
    createErrors.value.chain_id = 'Selecione a rede desta unidade.'
  }

  return Object.keys(createErrors.value).length === 0
}

async function createGym() {
  createError.value = null
  if (!validateCreateForm()) return

  creating.value = true
  try {
    const payload = {
      name: createForm.value.name.trim(),
      city: createForm.value.city.trim() || null,
      email: createForm.value.email.trim() || null,
      phone: createForm.value.phone.trim() || null,
      address: createForm.value.address.trim() || null,
      active: createForm.value.active,
      chain_id: createForm.value.kind === 'chain' ? Number(createForm.value.chain_id) : null,
    }

    await api.post('/super/gyms', payload)
    createModalOpen.value = false
    page.value = 1
    await load()
  } catch (e) {
    const apiErrors = e.response?.data?.errors
    if (apiErrors) {
      Object.entries(apiErrors).forEach(([key, value]) => {
        createErrors.value[key] = Array.isArray(value) ? value[0] : value
      })
    } else {
      createError.value = e.response?.data?.message ?? 'Erro ao criar academia.'
    }
  } finally {
    creating.value = false
  }
}

async function load() {
  loading.value = true
  error.value = null
  try {
    const params = new URLSearchParams({ page: page.value, per_page: 20 })
    if (searchInput.value.trim()) params.set('search', searchInput.value.trim())
    const { data } = await api.get(`/super/gyms?${params}`)
    gyms.value = data.data
    meta.value = data.meta
    summary.value = data.summary
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao carregar academias.'
  } finally {
    loading.value = false
  }
}

function confirmUnlink(gym) {
  unlinkTarget.value = gym
}

async function doUnlink() {
  if (!unlinkTarget.value?.chain?.id) return
  unlinking.value = true
  try {
    await api.delete(`/super/chains/${unlinkTarget.value.chain.id}/gyms/${unlinkTarget.value.id}`)
    unlinkTarget.value = null
    await load()
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao desvincular academia.'
    unlinkTarget.value = null
  } finally {
    unlinking.value = false
  }
}
</script>

<style scoped>
.modal-enter-active, .modal-leave-active { transition: opacity 0.2s ease; }
.modal-enter-from, .modal-leave-to { opacity: 0; }
</style>
