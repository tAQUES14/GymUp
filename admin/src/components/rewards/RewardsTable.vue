<template>
  <div class="card overflow-hidden">
    <table class="w-full text-left">
      <thead>
        <tr class="border-b border-slate-100 bg-slate-50/60">
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide w-16">Imagem</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Recompensa</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide hidden sm:table-cell">Tipo</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Pontos</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide hidden md:table-cell">Estoque</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide hidden lg:table-cell">Resgates</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide hidden sm:table-cell">Status</th>
          <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right">Ações</th>
        </tr>
      </thead>
      <tbody>

        <!-- Loading skeleton -->
        <template v-if="loading">
          <tr v-for="i in 4" :key="i" class="border-b border-slate-100">
            <td class="px-5 py-3.5">
              <div class="w-12 h-12 rounded-xl bg-slate-100 animate-pulse" />
            </td>
            <td class="px-5 py-3.5">
              <div class="h-4 bg-slate-100 rounded animate-pulse w-36 mb-1.5" />
              <div class="h-3 bg-slate-100 rounded animate-pulse w-48" />
            </td>
            <td v-for="j in 6" :key="j" class="px-5 py-3.5 hidden sm:table-cell">
              <div class="h-4 bg-slate-100 rounded animate-pulse w-16" />
            </td>
          </tr>
        </template>

        <!-- Empty state -->
        <tr v-else-if="rewards.length === 0">
          <td colspan="8" class="px-5 py-16 text-center">
            <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
              <svg class="w-6 h-6 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M21 11.25v8.25a1.5 1.5 0 01-1.5 1.5H5.25a1.5 1.5 0 01-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 109.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1114.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
              </svg>
            </div>
            <p class="text-sm font-semibold text-slate-700 mb-1">
              {{ search ? 'Nenhuma recompensa encontrada' : 'Nenhuma recompensa cadastrada' }}
            </p>
            <p class="text-xs text-slate-400">
              {{ search ? `Nenhum resultado para "${search}"` : 'Adicione a primeira recompensa da academia.' }}
            </p>
          </td>
        </tr>

        <!-- Rows -->
        <RewardRow
          v-for="r in rewards"
          :key="r.id"
          :reward="r"
          :toggling="togglingId === r.id"
          @edit="$emit('edit', $event)"
          @delete="$emit('delete', $event)"
          @toggle="$emit('toggle', $event)"
        />

      </tbody>
    </table>
  </div>
</template>

<script setup>
import RewardRow from './RewardRow.vue'

defineProps({
  rewards:    { type: Array,   required: true },
  loading:    { type: Boolean, default: false },
  search:     { type: String,  default: '' },
  togglingId: { type: Number,  default: null },
})
defineEmits(['edit', 'delete', 'toggle'])
</script>
