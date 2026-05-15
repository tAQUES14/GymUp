<template>
  <div>
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">Permissões</h1>
        <p class="text-sm text-slate-500 mt-1">Defina o que cada tipo de usuário pode acessar no sistema</p>
      </div>
      <button @click="openCreate" class="btn-primary inline-flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Novo perfil
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <div v-for="n in 3" :key="n" class="card p-5 animate-pulse space-y-3">
        <div class="h-4 w-32 bg-slate-100 rounded" />
        <div class="h-3 w-48 bg-slate-100 rounded" />
        <div class="flex gap-2 flex-wrap mt-2">
          <div v-for="i in 4" :key="i" class="h-5 w-20 bg-slate-100 rounded-full" />
        </div>
      </div>
    </div>

    <!-- Empty -->
    <div v-else-if="!visibleRoles.length" class="card p-12 text-center">
      <div class="w-12 h-12 bg-slate-100 rounded-xl flex items-center justify-center mx-auto mb-3">
        <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700 mb-1">Nenhum perfil criado</p>
      <p class="text-xs text-slate-400 mb-4">Crie um perfil para definir permissões de acesso</p>
      <button @click="openCreate" class="btn-primary text-sm">Criar primeiro perfil</button>
    </div>

    <!-- Grid de perfis -->
    <div v-else class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <div v-for="role in visibleRoles" :key="role.id" class="card p-5 flex flex-col gap-3">
        <div class="flex items-start justify-between">
          <div>
            <div class="flex items-center gap-2">
              <h3 class="font-semibold text-slate-900">{{ roleLabel(role.name) }}</h3>
              <span v-if="role.is_global"
                class="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-brand-50 text-brand-700">
                Global
              </span>
            </div>
            <p class="text-xs text-slate-500 mt-0.5">{{ roleDescription(role.name) }}</p>
            <p class="text-xs text-slate-400 mt-1">
              {{ role.permissions.length }} permissão{{ role.permissions.length !== 1 ? 'ões' : '' }}
            </p>
          </div>
          <div class="flex gap-1 flex-shrink-0">
            <button @click="openEdit(role)"
              class="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 rounded-lg transition-colors"
              title="Editar">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
              </svg>
            </button>
            <button v-if="!role.is_global" @click="confirmDelete(role)"
              class="p-1.5 text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"
              title="Remover">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Permissões -->
        <div class="flex flex-wrap gap-1.5">
          <span v-for="perm in role.permissions.slice(0, 6)" :key="perm"
            class="inline-block px-2 py-0.5 text-[10px] font-medium bg-slate-100 text-slate-600 rounded-full">
            {{ permLabel(perm) }}
          </span>
          <span v-if="role.permissions.length > 6"
            class="inline-block px-2 py-0.5 text-[10px] font-medium bg-slate-100 text-slate-500 rounded-full">
            +{{ role.permissions.length - 6 }} mais
          </span>
          <span v-if="!role.permissions.length"
            class="text-xs text-slate-400 italic">Nenhuma permissão</span>
        </div>
      </div>
    </div>

    <!-- ── Modal criar/editar perfil ───────────────────────────────────────────── -->
    <Teleport to="body">
      <div v-if="modal.open"
        class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
        @click.self="modal.open = false">
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] flex flex-col">

          <!-- Header modal -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <h2 class="text-base font-bold text-slate-900">
              {{ modal.isEditing ? 'Editar perfil' : 'Novo perfil' }}
            </h2>
            <button @click="modal.open = false" class="text-slate-400 hover:text-slate-700">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Body modal -->
          <div class="overflow-y-auto flex-1 px-6 py-5 space-y-5">

            <!-- Nome do perfil -->
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Nome do perfil</label>
              <input v-model="modal.form.name" type="text" placeholder="Ex: Personal Trainer, Estagiário"
                class="input w-full" />
            </div>

            <!-- Permissões agrupadas -->
            <div>
              <p class="text-xs font-semibold text-slate-700 mb-3">Permissões</p>
              <div v-for="group in permissionGroups" :key="group.label" class="mb-4">
                <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-widest mb-2">
                  {{ group.label }}
                </p>
                <div class="space-y-2">
                  <label v-for="perm in group.items" :key="perm.name"
                    class="flex items-center gap-3 cursor-pointer group">
                    <input type="checkbox" :value="perm.name" v-model="modal.form.permissions"
                      class="w-4 h-4 rounded border-slate-300 text-brand-600
                             focus:ring-brand-500 focus:ring-offset-0 cursor-pointer" />
                    <span class="flex-1">
                      <span class="block text-sm text-slate-800 group-hover:text-slate-900">
                        {{ perm.description }}
                      </span>
                      <span class="block text-[11px] text-slate-400">{{ perm.name }}</span>
                    </span>
                  </label>
                </div>
              </div>
            </div>
          </div>

          <!-- Footer modal -->
          <div class="px-6 py-4 border-t border-slate-100 flex justify-end gap-3">
            <button @click="modal.open = false" class="btn-secondary">Cancelar</button>
            <button @click="saveRole" :disabled="saving || !modal.form.name.trim()"
              class="btn-primary min-w-[100px]">
              <span v-if="saving">Salvando…</span>
              <span v-else>{{ modal.isEditing ? 'Salvar' : 'Criar perfil' }}</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- ── Modal confirmar exclusão ─────────────────────────────────────────── -->
    <Teleport to="body">
      <div v-if="deleteModal.open"
        class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
        @click.self="deleteModal.open = false">
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6">
          <h3 class="font-bold text-slate-900 mb-2">Remover perfil</h3>
          <p class="text-sm text-slate-500 mb-6">
            Tem certeza que deseja remover o perfil
            <strong class="text-slate-700">{{ roleLabel(deleteModal.role?.name) }}</strong>?
            Os usuários com esse perfil perderão as permissões associadas.
          </p>
          <div class="flex justify-end gap-3">
            <button @click="deleteModal.open = false" class="btn-secondary">Cancelar</button>
            <button @click="deleteRole" :disabled="deleting"
              class="px-4 py-2 text-sm font-semibold text-white bg-red-500 hover:bg-red-600
                     rounded-lg transition-colors disabled:opacity-50">
              {{ deleting ? 'Removendo…' : 'Remover' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import api from '../services/api.js'
import { useAuthStore } from '../stores/auth.js'

const auth    = useAuthStore()
const loading = ref(true)
const saving  = ref(false)
const deleting = ref(false)
const roles   = ref([])

// Oculta super_admin para quem não é super_admin
const visibleRoles = computed(() =>
  auth.isSuperAdmin
    ? roles.value
    : roles.value.filter(r => r.name !== 'super_admin')
)

// Nomes amigáveis para perfis do sistema
const roleLabels = {
  super_admin:   'Super Admin',
  gym_admin:     'Gestor da academia',
  network_admin: 'Gestor de rede',
  trainer:       'Treinador',
  user:          'Aluno',
}

const roleDescriptions = {
  super_admin:   'Acesso total à plataforma GymUp.',
  gym_admin:     'Acesso completo à gestão da unidade.',
  network_admin: 'Gerencia todas as unidades da rede.',
  trainer:       'Gerencia treinos e acompanha alunos.',
  user:          'Acesso ao app como aluno.',
}

const roleLabel       = (name) => roleLabels[name] ?? name
const roleDescription = (name) => roleDescriptions[name] ?? 'Perfil personalizado.'

// Permissões disponíveis vindas da API
const allPermissions = ref([])

// Labels curtos para exibição nos cards
const permLabels = {
  view_users:            'Ver alunos',
  edit_users:            'Editar alunos',
  delete_users:          'Remover alunos',
  adjust_points:         'Ajustar pontos',
  view_workouts:         'Ver treinos',
  manage_workouts:       'Gerenciar treinos',
  assign_workouts:       'Atribuir treinos',
  manage_workout_plans:  'Planos de treino',
  manage_exercises:      'Exercícios',
  manage_challenges:     'Desafios',
  manage_achievements:   'Conquistas',
  manage_rewards:        'Recompensas',
  manage_redemptions:    'Resgates',
  view_ranking:          'Ranking',
  view_reports:          'Relatórios',
  manage_roles:          'Gerenciar perfis',
  manage_settings:       'Configurações',
  manage_gyms:           'Academias',
}

const permLabel = (name) => permLabels[name] ?? name

// Agrupamento visual das permissões no modal
const permissionGroups = [
  {
    label: 'Alunos',
    items: ['view_users', 'edit_users', 'delete_users', 'adjust_points'],
  },
  {
    label: 'Treinos',
    items: ['view_workouts', 'manage_workouts', 'assign_workouts', 'manage_workout_plans', 'manage_exercises'],
  },
  {
    label: 'Conteúdo',
    items: ['manage_challenges', 'manage_achievements', 'manage_rewards', 'manage_redemptions'],
  },
  {
    label: 'Visualização',
    items: ['view_ranking', 'view_reports'],
  },
  {
    label: 'Administração',
    items: ['manage_roles'],
  },
].map(group => ({
  label: group.label,
  items: group.items
    .map(name => allPermissions.value.find(p => p.name === name))
    .filter(Boolean),
}))

// ── Modal ─────────────────────────────────────────────────────────────────────

const modal = reactive({
  open:      false,
  isEditing: false,
  editId:    null,
  form: {
    name:        '',
    permissions: [],
  },
})

const deleteModal = reactive({
  open: false,
  role: null,
})

function openCreate() {
  modal.isEditing        = false
  modal.editId           = null
  modal.form.name        = ''
  modal.form.permissions = []
  modal.open             = true
}

function openEdit(role) {
  modal.isEditing        = true
  modal.editId           = role.id
  modal.form.name        = role.name
  modal.form.permissions = [...role.permissions]
  modal.open             = true
}

function confirmDelete(role) {
  deleteModal.role = role
  deleteModal.open = true
}

// ── CRUD ──────────────────────────────────────────────────────────────────────

async function load() {
  loading.value = true
  try {
    const [rolesRes, permsRes] = await Promise.all([
      api.get('/admin/roles'),
      api.get('/admin/permissions'),
    ])
    roles.value          = rolesRes.data
    allPermissions.value = permsRes.data
  } finally {
    loading.value = false
  }
}

async function saveRole() {
  if (!modal.form.name.trim()) return
  saving.value = true
  try {
    const payload = {
      name:        modal.form.name.trim(),
      permissions: modal.form.permissions,
    }

    if (modal.isEditing) {
      await api.put(`/admin/roles/${modal.editId}`, payload)
    } else {
      await api.post('/admin/roles', payload)
    }

    modal.open = false
    await load()
  } finally {
    saving.value = false
  }
}

async function deleteRole() {
  if (!deleteModal.role) return
  deleting.value = true
  try {
    await api.delete(`/admin/roles/${deleteModal.role.id}`)
    deleteModal.open = false
    await load()
  } finally {
    deleting.value = false
  }
}

onMounted(load)
</script>
