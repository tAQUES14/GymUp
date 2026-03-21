<template>
  <div class="card overflow-hidden">
    <table class="w-full text-left border-collapse">

      <!-- Header -->
      <thead>
        <tr class="border-b border-slate-100 bg-slate-50/60">
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">
            Aluno
          </th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden lg:table-cell">
            Email
          </th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">
            Treinos
          </th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden sm:table-cell">
            Última atividade
          </th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider">
            Status
          </th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wider text-right">
            Ações
          </th>
        </tr>
      </thead>

      <tbody>

        <!-- Loading skeleton -->
        <template v-if="loading">
          <tr v-for="n in 6" :key="n" class="border-b border-slate-100 animate-pulse">
            <td class="px-5 py-3.5">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-full bg-slate-100 flex-shrink-0" />
                <div class="space-y-1.5">
                  <div class="h-3 bg-slate-100 rounded w-32" />
                  <div class="h-2.5 bg-slate-100 rounded w-24" />
                </div>
              </div>
            </td>
            <td class="px-5 py-3.5 hidden lg:table-cell">
              <div class="h-3 bg-slate-100 rounded w-40" />
            </td>
            <td class="px-5 py-3.5">
              <div class="h-5 bg-slate-100 rounded-full w-8" />
            </td>
            <td class="px-5 py-3.5 hidden sm:table-cell">
              <div class="h-3 bg-slate-100 rounded w-20" />
            </td>
            <td class="px-5 py-3.5">
              <div class="h-5 bg-slate-100 rounded-full w-14" />
            </td>
            <td class="px-5 py-3.5" />
          </tr>
        </template>

        <!-- Rows -->
        <template v-else-if="users.length">
          <UserRow
            v-for="user in users"
            :key="user.id"
            :user="user"
            @view="$emit('view', $event)"
          />
        </template>

        <!-- Empty state -->
        <tr v-else>
          <td colspan="6" class="px-5 py-16 text-center">
            <div class="flex flex-col items-center gap-3">
              <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center">
                <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                    d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
                </svg>
              </div>
              <div>
                <p class="text-sm font-semibold text-slate-700">
                  {{ emptyTitle }}
                </p>
                <p class="text-xs text-slate-400 mt-0.5">{{ emptySubtitle }}</p>
              </div>
            </div>
          </td>
        </tr>

      </tbody>
    </table>
  </div>
</template>

<script setup>
import UserRow from './UserRow.vue'

const props = defineProps({
  users:   { type: Array,   default: () => [] },
  loading: { type: Boolean, default: false },
  search:  { type: String,  default: '' },
})

defineEmits(['view'])

const emptyTitle    = props.search ? 'Nenhum resultado encontrado' : 'Nenhum aluno cadastrado'
const emptySubtitle = props.search ? `Sem resultados para "${props.search}"` : 'Os alunos cadastrados aparecerão aqui.'
</script>
