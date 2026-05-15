<template>
  <div>

    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Equipe e Acessos</h1>
        <p class="text-slate-500 text-sm mt-1">
          Gerencie treinadores, gestores e usuários com acesso ao painel da academia.
        </p>
      </div>
      <button @click="openInvite"
        class="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white text-sm
               font-semibold rounded-lg hover:bg-brand-700 transition-colors shadow-sm
               shadow-brand-600/20 flex-shrink-0">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Convidar membro
      </button>
    </div>

    <!-- Stat cards -->
    <div class="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
      <div class="card px-4 py-3.5 flex items-center gap-3">
        <div class="w-9 h-9 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
          <svg class="w-4.5 h-4.5 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
          </svg>
        </div>
        <div>
          <p class="text-xs text-slate-500">Total</p>
          <p class="text-lg font-bold text-slate-900 leading-tight">
            <span v-if="loading" class="inline-block w-6 h-4 bg-slate-100 rounded animate-pulse" />
            <template v-else>{{ staff.length }}</template>
          </p>
        </div>
      </div>

      <div class="card px-4 py-3.5 flex items-center gap-3">
        <div class="w-9 h-9 rounded-lg bg-emerald-50 flex items-center justify-center flex-shrink-0">
          <svg class="w-4.5 h-4.5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75z" />
          </svg>
        </div>
        <div>
          <p class="text-xs text-slate-500">Treinadores</p>
          <p class="text-lg font-bold text-slate-900 leading-tight">
            <span v-if="loading" class="inline-block w-6 h-4 bg-slate-100 rounded animate-pulse" />
            <template v-else>{{ trainers.length }}</template>
          </p>
        </div>
      </div>

      <div class="card px-4 py-3.5 flex items-center gap-3">
        <div class="w-9 h-9 rounded-lg bg-violet-50 flex items-center justify-center flex-shrink-0">
          <svg class="w-4.5 h-4.5 text-violet-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
          </svg>
        </div>
        <div>
          <p class="text-xs text-slate-500">Gestores</p>
          <p class="text-lg font-bold text-slate-900 leading-tight">
            <span v-if="loading" class="inline-block w-6 h-4 bg-slate-100 rounded animate-pulse" />
            <template v-else>{{ managers.length }}</template>
          </p>
        </div>
      </div>

      <div class="card px-4 py-3.5 flex items-center gap-3">
        <div class="w-9 h-9 rounded-lg bg-amber-50 flex items-center justify-center flex-shrink-0">
          <svg class="w-4.5 h-4.5 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
          </svg>
        </div>
        <div>
          <p class="text-xs text-slate-500">Pendentes</p>
          <p class="text-lg font-bold text-slate-900 leading-tight">
            <span v-if="loading" class="inline-block w-6 h-4 bg-slate-100 rounded animate-pulse" />
            <template v-else>{{ pending.length }}</template>
          </p>
        </div>
      </div>
    </div>

    <!-- Error -->
    <div v-if="error" class="card p-8 text-center mb-6">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar equipe</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="load" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Loading skeleton -->
    <div v-else-if="loading" class="card overflow-hidden">
      <div class="divide-y divide-slate-100">
        <div v-for="n in 3" :key="n" class="px-6 py-4 flex items-center gap-4 animate-pulse">
          <div class="w-9 h-9 rounded-full bg-slate-100 flex-shrink-0" />
          <div class="flex-1 space-y-2">
            <div class="h-3.5 bg-slate-100 rounded w-40" />
            <div class="h-3 bg-slate-100 rounded w-52" />
          </div>
          <div class="h-5 w-20 bg-slate-100 rounded-full" />
          <div class="h-5 w-16 bg-slate-100 rounded-full" />
        </div>
      </div>
    </div>

    <!-- Empty -->
    <div v-else-if="!staff.length" class="card p-12 text-center">
      <div class="w-12 h-12 bg-slate-100 rounded-xl flex items-center justify-center mx-auto mb-3">
        <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700 mb-1">Nenhum membro na equipe</p>
      <p class="text-xs text-slate-400 mb-4">Convide treinadores e gestores para acessar o painel.</p>
      <button @click="openInvite" class="btn-primary text-sm">Convidar primeiro membro</button>
    </div>

    <!-- Tabela de membros -->
    <div v-else class="card overflow-hidden">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-100">
            <th class="px-6 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">Membro</th>
            <th class="px-6 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider hidden sm:table-cell">Perfil de acesso</th>
            <th class="px-6 py-3.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider hidden md:table-cell">Status</th>
            <th class="px-6 py-3.5 text-right text-xs font-semibold text-slate-500 uppercase tracking-wider">Ações</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-50">
          <tr v-for="member in staff" :key="member.id"
            class="hover:bg-slate-50/60 transition-colors">

            <!-- Nome + e-mail -->
            <td class="px-6 py-4">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0"
                  :class="avatarClass(member.role)">
                  {{ member.name[0]?.toUpperCase() }}
                </div>
                <div>
                  <p class="font-medium text-slate-900">{{ member.name }}</p>
                  <p class="text-xs text-slate-400">{{ member.email }}</p>
                </div>
              </div>
            </td>

            <!-- Perfil -->
            <td class="px-6 py-4 hidden sm:table-cell">
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold"
                :class="roleClass(member.role)">
                {{ roleLabel(member.role) }}
              </span>
            </td>

            <!-- Status -->
            <td class="px-6 py-4 hidden md:table-cell">
              <span class="inline-flex items-center gap-1.5 text-xs font-medium"
                :class="member.status === 'pending' ? 'text-amber-600' : 'text-emerald-600'">
                <span class="w-1.5 h-1.5 rounded-full flex-shrink-0"
                  :class="member.status === 'pending' ? 'bg-amber-400' : 'bg-emerald-400'" />
                {{ member.status === 'pending' ? 'Convite pendente' : 'Ativo' }}
              </span>
            </td>

            <!-- Ações -->
            <td class="px-6 py-4 text-right">
              <div class="flex items-center justify-end gap-1">
                <!-- Reenviar convite (só se pendente) -->
                <button v-if="member.status === 'pending'"
                  @click="handleResend(member)"
                  class="p-1.5 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
                  title="Reenviar credenciais">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
                  </svg>
                </button>
                <!-- Editar perfil -->
                <button @click="openEdit(member)"
                  class="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 rounded-lg transition-colors"
                  title="Editar perfil">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
                  </svg>
                </button>
                <!-- Remover acesso -->
                <button @click="confirmRemove(member)"
                  class="p-1.5 text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"
                  title="Remover acesso">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M22 10.5h-6m-2.25-4.125a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zM4 19.235v-.11a6.375 6.375 0 0112.75 0v.109A12.318 12.318 0 0110.374 21c-2.331 0-4.512-.645-6.374-1.766z" />
                  </svg>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- ── Modal: Convidar membro ──────────────────────────────────────────────── -->
    <Teleport to="body">
      <div v-if="inviteModal.open"
        class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
        @click.self="inviteModal.open = false">
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md">

          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <h2 class="text-base font-bold text-slate-900">Convidar membro</h2>
            <button @click="inviteModal.open = false" class="text-slate-400 hover:text-slate-700">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div class="px-6 py-5 space-y-4">
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Nome completo</label>
              <input v-model="inviteModal.form.name" type="text" placeholder="Ex: João Silva"
                class="input w-full" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">E-mail de acesso</label>
              <input v-model="inviteModal.form.email" type="email" placeholder="joao@academia.com"
                class="input w-full" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Perfil de acesso</label>
              <select v-model="inviteModal.form.role" class="input w-full">
                <option value="" disabled>Selecione um perfil…</option>
                <option value="trainer">Treinador</option>
                <option value="gym_admin">Gestor da academia</option>
              </select>
              <p class="text-[11px] text-slate-400 mt-1.5">
                <span v-if="inviteModal.form.role === 'trainer'">Acessa alunos, treinos e rankings.</span>
                <span v-else-if="inviteModal.form.role === 'gym_admin'">Acesso completo à gestão da academia.</span>
                <span v-else>Escolha um perfil para ver suas permissões.</span>
              </p>
            </div>
          </div>

          <div class="px-6 py-4 border-t border-slate-100 flex justify-end gap-3">
            <button @click="inviteModal.open = false" class="btn-secondary">Cancelar</button>
            <button @click="submitInvite"
              :disabled="inviting || !inviteModal.form.name.trim() || !inviteModal.form.email.trim() || !inviteModal.form.role"
              class="btn-primary min-w-[120px]">
              <span v-if="inviting">Criando…</span>
              <span v-else>Enviar convite</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- ── Modal: Credenciais (após convite) ─────────────────────────────────── -->
    <Teleport to="body">
      <div v-if="credModal.open"
        class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
        @click.self="credModal.open = false">
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md">

          <div class="px-6 pt-6 pb-2 text-center">
            <div class="w-12 h-12 bg-emerald-50 rounded-full flex items-center justify-center mx-auto mb-3">
              <svg class="w-6 h-6 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h2 class="text-base font-bold text-slate-900 mb-1">
              {{ credModal.isResend ? 'Novas credenciais geradas' : 'Conta criada com sucesso!' }}
            </h2>
            <p class="text-xs text-slate-500">
              Compartilhe essas credenciais com
              <strong class="text-slate-700">{{ credModal.name }}</strong>
              para que possa acessar o painel.
            </p>
          </div>

          <div class="px-6 py-5 space-y-3">
            <div class="bg-slate-50 rounded-xl p-4 space-y-3">
              <div>
                <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-widest mb-0.5">E-mail</p>
                <p class="text-sm font-mono text-slate-800">{{ credModal.email }}</p>
              </div>
              <div>
                <p class="text-[10px] font-semibold text-slate-400 uppercase tracking-widest mb-0.5">Senha temporária</p>
                <p class="text-lg font-mono font-bold text-slate-900 tracking-widest">{{ credModal.tempPassword }}</p>
              </div>
            </div>
            <p class="text-[11px] text-slate-400 text-center">
              O membro pode alterar a senha após o primeiro acesso em Configurações.
            </p>
          </div>

          <div class="px-6 pb-5 flex gap-3">
            <button @click="copyCredentials"
              class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2 border border-slate-200
                     text-sm font-semibold text-slate-700 rounded-lg hover:bg-slate-50 transition-colors">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
              </svg>
              {{ copied ? 'Copiado!' : 'Copiar credenciais' }}
            </button>
            <button @click="credModal.open = false" class="btn-primary px-6">Fechar</button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- ── Modal: Editar perfil ───────────────────────────────────────────────── -->
    <Teleport to="body">
      <div v-if="editModal.open"
        class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
        @click.self="editModal.open = false">
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-md">

          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <h2 class="text-base font-bold text-slate-900">Editar membro</h2>
            <button @click="editModal.open = false" class="text-slate-400 hover:text-slate-700">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div class="px-6 py-5 space-y-4">
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Nome</label>
              <input v-model="editModal.form.name" type="text" class="input w-full" />
            </div>
            <div>
              <label class="block text-xs font-semibold text-slate-700 mb-1.5">Perfil de acesso</label>
              <select v-model="editModal.form.role" class="input w-full">
                <option value="trainer">Treinador</option>
                <option value="gym_admin">Gestor da academia</option>
              </select>
            </div>
          </div>

          <div class="px-6 py-4 border-t border-slate-100 flex justify-end gap-3">
            <button @click="editModal.open = false" class="btn-secondary">Cancelar</button>
            <button @click="submitEdit" :disabled="saving" class="btn-primary min-w-[100px]">
              <span v-if="saving">Salvando…</span>
              <span v-else>Salvar</span>
            </button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- ── Modal: Confirmar remoção ───────────────────────────────────────────── -->
    <Teleport to="body">
      <div v-if="removeModal.open"
        class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
        @click.self="removeModal.open = false">
        <div class="bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6">
          <h3 class="font-bold text-slate-900 mb-2">Remover acesso</h3>
          <p class="text-sm text-slate-500 mb-6">
            Tem certeza que deseja remover o acesso de
            <strong class="text-slate-700">{{ removeModal.member?.name }}</strong>?
            A conta será excluída e o acesso ao painel será encerrado.
          </p>
          <div class="flex justify-end gap-3">
            <button @click="removeModal.open = false" class="btn-secondary">Cancelar</button>
            <button @click="submitRemove" :disabled="removing"
              class="px-4 py-2 text-sm font-semibold text-white bg-red-500 hover:bg-red-600
                     rounded-lg transition-colors disabled:opacity-50">
              {{ removing ? 'Removendo…' : 'Remover acesso' }}
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

const loading  = ref(true)
const inviting = ref(false)
const saving   = ref(false)
const removing = ref(false)
const copied   = ref(false)
const error    = ref('')
const staff    = ref([])

const trainers = computed(() => staff.value.filter(m => m.role === 'trainer'))
const managers = computed(() => staff.value.filter(m => m.role === 'gym_admin'))
const pending  = computed(() => staff.value.filter(m => m.status === 'pending'))

// ── Labels e classes visuais ──────────────────────────────────────────────────

const roleLabels = {
  gym_admin: 'Gestor da academia',
  trainer:   'Treinador',
}
const roleLabel = (r) => roleLabels[r] ?? r

function roleClass(role) {
  if (role === 'gym_admin') return 'bg-violet-100 text-violet-700'
  if (role === 'trainer')   return 'bg-emerald-100 text-emerald-700'
  return 'bg-slate-100 text-slate-600'
}

function avatarClass(role) {
  if (role === 'gym_admin') return 'bg-violet-100 text-violet-700'
  if (role === 'trainer')   return 'bg-emerald-100 text-emerald-700'
  return 'bg-slate-100 text-slate-600'
}

// ── Modais ────────────────────────────────────────────────────────────────────

const inviteModal = reactive({
  open: false,
  form: { name: '', email: '', role: '' },
})

const credModal = reactive({
  open:        false,
  isResend:    false,
  name:        '',
  email:       '',
  tempPassword: '',
})

const editModal = reactive({
  open:   false,
  id:     null,
  form:   { name: '', role: '' },
})

const removeModal = reactive({
  open:   false,
  member: null,
})

function openInvite() {
  inviteModal.form = { name: '', email: '', role: '' }
  inviteModal.open = true
}

function openEdit(member) {
  editModal.id   = member.id
  editModal.form = { name: member.name, role: member.role }
  editModal.open = true
}

function confirmRemove(member) {
  removeModal.member = member
  removeModal.open   = true
}

function showCredentials(member, tempPassword, isResend = false) {
  credModal.isResend    = isResend
  credModal.name        = member.name
  credModal.email       = member.email
  credModal.tempPassword = tempPassword
  credModal.open        = true
}

async function copyCredentials() {
  const text = `Acesso ao painel GymUp\nE-mail: ${credModal.email}\nSenha: ${credModal.tempPassword}`
  try {
    await navigator.clipboard.writeText(text)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  } catch { /* fallback silencioso */ }
}

// ── CRUD ──────────────────────────────────────────────────────────────────────

async function load() {
  loading.value = true
  error.value   = ''
  try {
    const { data } = await api.get('/admin/staff')
    staff.value = data.staff
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar a equipe.'
  } finally {
    loading.value = false
  }
}

async function submitInvite() {
  if (!inviteModal.form.name.trim() || !inviteModal.form.email.trim() || !inviteModal.form.role) return
  inviting.value = true
  try {
    const { data } = await api.post('/admin/staff', inviteModal.form)
    inviteModal.open = false
    await load()
    showCredentials(data.member, data.temp_password)
  } catch (e) {
    alert(e.response?.data?.message ?? 'Erro ao criar membro.')
  } finally {
    inviting.value = false
  }
}

async function handleResend(member) {
  try {
    const { data } = await api.post(`/admin/staff/${member.id}/resend-invite`)
    showCredentials(member, data.temp_password, true)
  } catch (e) {
    alert(e.response?.data?.message ?? 'Erro ao gerar novas credenciais.')
  }
}

async function submitEdit() {
  if (!editModal.form.name.trim()) return
  saving.value = true
  try {
    await api.put(`/admin/staff/${editModal.id}`, editModal.form)
    editModal.open = false
    await load()
  } catch (e) {
    alert(e.response?.data?.message ?? 'Erro ao atualizar membro.')
  } finally {
    saving.value = false
  }
}

async function submitRemove() {
  if (!removeModal.member) return
  removing.value = true
  try {
    await api.delete(`/admin/staff/${removeModal.member.id}`)
    removeModal.open = false
    await load()
  } catch (e) {
    alert(e.response?.data?.message ?? 'Erro ao remover acesso.')
  } finally {
    removing.value = false
  }
}

onMounted(load)
</script>
