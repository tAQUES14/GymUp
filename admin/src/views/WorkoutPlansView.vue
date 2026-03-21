<template>
  <div>

    <!-- Page header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <div class="flex items-center gap-3">
          <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Planos de Treino</h1>
          <span v-if="!loading && !error"
            class="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs
                   font-semibold bg-brand-50 text-brand-700 border border-brand-100">
            {{ plans.length }}
          </span>
        </div>
        <p class="text-slate-500 text-sm mt-1">Planos sequenciais atribuídos a alunos.</p>
      </div>
      <button @click="openCreate"
        class="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white text-sm
               font-semibold rounded-lg hover:bg-brand-700 transition-colors shadow-sm
               shadow-brand-600/20 flex-shrink-0">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Novo Plano
      </button>
    </div>

    <!-- Error state -->
    <div v-if="error" class="card p-8 text-center mb-6">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar planos</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadPlans" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Table -->
    <div v-else class="card overflow-hidden">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-100">
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider">Nome</th>
            <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden md:table-cell">Descrição</th>
            <th class="text-center px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider">Etapas</th>
            <th class="px-5 py-3.5"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="4" class="px-5 py-10 text-center">
              <div class="flex items-center justify-center gap-2 text-slate-400">
                <svg class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                </svg>
                <span class="text-sm">Carregando…</span>
              </div>
            </td>
          </tr>
          <tr v-else-if="plans.length === 0">
            <td colspan="5" class="px-5 py-10 text-center text-sm text-slate-400">
              Nenhum plano de treino criado ainda.
            </td>
          </tr>
          <tr v-for="plan in plans" :key="plan.id"
            class="border-b border-slate-50 hover:bg-slate-50/60 transition-colors">
            <td class="px-5 py-4">
              <button @click="goToPlan(plan.id)"
                class="font-semibold text-slate-900 hover:text-brand-600 transition-colors text-left">
                {{ plan.name }}
              </button>
            </td>
            <td class="px-5 py-4 text-slate-500 hidden md:table-cell max-w-xs">
              <span class="truncate block">{{ plan.description || '—' }}</span>
            </td>
            <td class="px-5 py-4 text-center">
              <span class="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs
                           font-semibold bg-slate-100 text-slate-700">
                {{ plan.days_count }}
              </span>
            </td>
            <td class="px-5 py-4">
              <div class="flex items-center justify-end gap-2">
                <button @click="goToPlan(plan.id)"
                  class="p-1.5 rounded-md text-slate-400 hover:text-brand-600 hover:bg-brand-50 transition-colors"
                  title="Ver detalhes">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </button>
                <button @click="openEdit(plan)"
                  class="p-1.5 rounded-md text-slate-400 hover:text-brand-600 hover:bg-brand-50 transition-colors"
                  title="Editar">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
                  </svg>
                </button>
                <button @click="askDelete(plan)"
                  class="p-1.5 rounded-md text-slate-400 hover:text-red-500 hover:bg-red-50 transition-colors"
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
    </div>

    <!-- ══════════════════════════════════════════════════════════════════ -->
    <!-- CREATE MODAL (new plan)                                            -->
    <!-- ══════════════════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="createModalOpen" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="closeCreate" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-md">
            <h3 class="text-base font-semibold text-slate-900 mb-5">Novo Plano de Treino</h3>

            <div class="space-y-4">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1.5">Nome *</label>
                <input v-model="createForm.name" type="text" placeholder="Ex: Push Pull Legs, Full Body 4x…"
                  @keydown.enter="submitCreate" autofocus
                  class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg
                         focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1.5">Descrição <span class="font-normal text-slate-400">(opcional)</span></label>
                <input v-model="createForm.description" type="text" placeholder="Descrição breve do plano…"
                  @keydown.enter="submitCreate"
                  class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg
                         focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
              </div>
            </div>

            <p v-if="createError" class="text-xs text-red-500 mt-3">{{ createError }}</p>

            <div class="flex items-center gap-3 mt-6">
              <button @click="closeCreate" :disabled="createSaving" class="flex-1 btn-secondary">Cancelar</button>
              <button @click="submitCreate" :disabled="createSaving || !createForm.name.trim()"
                class="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 bg-brand-600
                       text-white text-sm font-semibold rounded-lg hover:bg-brand-700 transition-colors
                       disabled:opacity-60 disabled:cursor-not-allowed">
                <svg v-if="createSaving" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                </svg>
                {{ createSaving ? 'Criando…' : 'Criar e montar' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ══════════════════════════════════════════════════════════════════ -->
    <!-- EDIT MODAL (existing plan metadata only)                           -->
    <!-- ══════════════════════════════════════════════════════════════════ -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="editModalOpen" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="closeEditModal" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-md">
            <h3 class="text-base font-semibold text-slate-900 mb-5">Editar Plano</h3>

            <div class="space-y-4">
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1.5">Nome *</label>
                <input v-model="editForm.name" type="text"
                  class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg
                         focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
              </div>
              <div>
                <label class="block text-xs font-semibold text-slate-600 mb-1.5">Descrição</label>
                <textarea v-model="editForm.description" rows="2"
                  class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg resize-none
                         focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
              </div>
            </div>

            <p v-if="editError" class="text-xs text-red-500 mt-3">{{ editError }}</p>

            <div class="flex items-center gap-3 mt-6">
              <button @click="closeEditModal" class="flex-1 btn-secondary">Cancelar</button>
              <button @click="saveEdit" :disabled="editSaving"
                class="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 bg-brand-600
                       text-white text-sm font-semibold rounded-lg hover:bg-brand-700 transition-colors
                       disabled:opacity-60 disabled:cursor-not-allowed">
                <svg v-if="editSaving" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                </svg>
                {{ editSaving ? 'Salvando…' : 'Salvar' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- Delete confirmation -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="deleteTarget" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="cancelDelete" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-sm">
            <div class="flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mx-auto mb-4">
              <svg class="w-6 h-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
              </svg>
            </div>
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Excluir plano</h3>
            <p class="text-sm text-slate-500 text-center mb-5">
              Tem certeza que deseja excluir
              <strong class="text-slate-700">"{{ deleteTarget.name }}"</strong>?
            </p>
            <p v-if="deleteError" class="text-xs text-red-500 text-center mb-3">{{ deleteError }}</p>
            <div class="flex items-center gap-3">
              <button @click="cancelDelete" class="flex-1 btn-secondary">Cancelar</button>
              <button @click="confirmDelete" :disabled="deleting"
                class="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 bg-red-600
                       text-white text-sm font-semibold rounded-lg hover:bg-red-700 transition-colors
                       disabled:opacity-60 disabled:cursor-not-allowed">
                <svg v-if="deleting" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                </svg>
                {{ deleting ? 'Excluindo…' : 'Sim, excluir' }}
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
import { useRouter } from 'vue-router'
import api from '../services/api.js'

const router  = useRouter()
const plans   = ref([])
const loading = ref(true)
const error   = ref('')

// ── Load ──────────────────────────────────────────────────────────────────────

async function loadPlans() {
  loading.value = true; error.value = ''
  try {
    const { data } = await api.get('/admin/workout-plans')
    plans.value = data.plans ?? []
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar os planos.'
  } finally { loading.value = false }
}

function goToPlan(id) { router.push(`/workout-plans/${id}`) }

// ── Create ────────────────────────────────────────────────────────────────────

const createModalOpen = ref(false)
const createSaving    = ref(false)
const createError     = ref('')
const createForm      = ref({ name: '', description: '' })

function openCreate() {
  createForm.value  = { name: '', description: '' }
  createError.value = ''
  createModalOpen.value = true
}

function closeCreate() {
  if (!createSaving.value) createModalOpen.value = false
}

async function submitCreate() {
  if (!createForm.value.name.trim()) { createError.value = 'Nome do plano é obrigatório.'; return }
  createSaving.value = true; createError.value = ''
  try {
    const { data } = await api.post('/admin/workout-plans', {
      name:        createForm.value.name.trim(),
      description: createForm.value.description.trim() || null,
    })
    router.push(`/workout-plans/${data.plan.id}`)
  } catch (e) {
    createError.value = e.response?.data?.message ?? 'Erro ao criar plano.'
    createSaving.value = false
  }
}

// ── Edit ──────────────────────────────────────────────────────────────────────

const editModalOpen = ref(false)
const editTarget    = ref(null)
const editSaving    = ref(false)
const editError     = ref('')
const editForm      = ref({ name: '', description: '' })

function openEdit(plan) {
  editTarget.value = plan
  editForm.value   = {
    name:        plan.name,
    description: plan.description ?? '',
  }
  editError.value    = ''
  editModalOpen.value = true
}

function closeEditModal() {
  if (!editSaving.value) editModalOpen.value = false
}

async function saveEdit() {
  if (!editForm.value.name.trim()) { editError.value = 'Nome é obrigatório.'; return }
  editSaving.value = true; editError.value = ''
  try {
    const { data } = await api.put(`/admin/workout-plans/${editTarget.value.id}`, {
      name:        editForm.value.name.trim(),
      description: editForm.value.description.trim() || null,
    })
    const idx = plans.value.findIndex((p) => p.id === editTarget.value.id)
    if (idx !== -1) plans.value[idx] = {
      ...plans.value[idx],
      name:        data.plan.name,
      description: data.plan.description,
    }
    editModalOpen.value = false
  } catch (e) {
    editError.value = e.response?.data?.message ?? 'Erro ao salvar plano.'
  } finally { editSaving.value = false }
}

// ── Delete ────────────────────────────────────────────────────────────────────

const deleteTarget = ref(null)
const deleting     = ref(false)
const deleteError  = ref('')

function askDelete(plan)  { deleteError.value = ''; deleteTarget.value = plan }
function cancelDelete()   { if (!deleting.value) deleteTarget.value = null }

async function confirmDelete() {
  if (!deleteTarget.value) return
  deleting.value = true; deleteError.value = ''
  try {
    await api.delete(`/admin/workout-plans/${deleteTarget.value.id}`)
    plans.value    = plans.value.filter((p) => p.id !== deleteTarget.value.id)
    deleteTarget.value = null
  } catch (e) {
    deleteError.value = e.response?.data?.message ?? 'Erro ao excluir plano.'
  } finally { deleting.value = false }
}

onMounted(loadPlans)
</script>
