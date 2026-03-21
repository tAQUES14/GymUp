<template>
  <tr class="border-b border-slate-100 hover:bg-slate-50/60 transition-colors">

    <!-- Imagem -->
    <td class="px-5 py-3.5">
      <div class="w-12 h-12 rounded-xl overflow-hidden bg-slate-100 flex-shrink-0 flex items-center justify-center">
        <img v-if="reward.image_url"
             :src="reward.image_url"
             :alt="reward.name"
             class="w-full h-full object-cover" />
        <svg v-else class="w-6 h-6 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z" />
        </svg>
      </div>
    </td>

    <!-- Nome + Descrição -->
    <td class="px-5 py-3.5 max-w-xs">
      <p class="text-sm font-semibold text-slate-900 leading-snug truncate">{{ reward.name }}</p>
      <p class="text-xs text-slate-400 truncate mt-0.5">{{ reward.description || '—' }}</p>
    </td>

    <!-- Categoria -->
    <td class="px-5 py-3.5 hidden sm:table-cell">
      <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold"
            :class="categoryStyle.bg + ' ' + categoryStyle.text">
        <span>{{ categoryStyle.icon }}</span>
        {{ categoryStyle.label }}
      </span>
    </td>

    <!-- Pontos -->
    <td class="px-5 py-3.5">
      <div class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-50 border border-amber-100">
        <svg class="w-3 h-3 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
        </svg>
        <span class="text-xs font-bold text-amber-700">{{ reward.points_cost.toLocaleString('pt-BR') }}</span>
      </div>
    </td>

    <!-- Estoque -->
    <td class="px-5 py-3.5 hidden md:table-cell">
      <template v-if="reward.stock === null">
        <span class="text-xs text-slate-400 italic">Ilimitado</span>
      </template>
      <template v-else>
        <span class="text-sm font-semibold"
              :class="reward.stock === 0 ? 'text-red-500' : reward.stock <= 5 ? 'text-amber-600' : 'text-slate-700'">
          {{ reward.stock }}
        </span>
        <span class="text-xs text-slate-400 ml-1">un.</span>
      </template>
    </td>

    <!-- Resgates -->
    <td class="px-5 py-3.5 hidden lg:table-cell">
      <div class="flex items-center gap-2">
        <span class="text-sm font-semibold text-slate-700">{{ reward.redemptions_count }}</span>
        <span v-if="reward.pending_count > 0"
              class="inline-flex items-center px-1.5 py-0.5 rounded-full text-[10px] font-bold
                     bg-orange-100 text-orange-700">
          {{ reward.pending_count }} pend.
        </span>
      </div>
    </td>

    <!-- Status -->
    <td class="px-5 py-3.5 hidden sm:table-cell">
      <button @click="$emit('toggle', reward)"
        :disabled="toggling"
        class="relative inline-flex h-5 w-9 items-center rounded-full transition-colors focus:outline-none
               disabled:opacity-50 flex-shrink-0"
        :class="reward.active ? 'bg-emerald-500' : 'bg-slate-200'">
        <span class="inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow-sm transition-transform"
              :class="reward.active ? 'translate-x-[18px]' : 'translate-x-[3px]'" />
      </button>
    </td>

    <!-- Ações -->
    <td class="px-5 py-3.5 text-right">
      <div class="flex items-center justify-end gap-1">
        <button @click="$emit('edit', reward)"
          class="p-1.5 rounded-lg text-slate-400 hover:text-brand-600 hover:bg-brand-50 transition-colors"
          title="Editar">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
          </svg>
        </button>
        <button @click="$emit('delete', reward)"
          class="p-1.5 rounded-lg text-slate-400 hover:text-red-500 hover:bg-red-50 transition-colors"
          title="Excluir">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
          </svg>
        </button>
      </div>
    </td>

  </tr>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  reward:   { type: Object,  required: true },
  toggling: { type: Boolean, default: false },
})
defineEmits(['edit', 'delete', 'toggle'])

const categoryStyle = computed(() => {
  const map = {
    physical: { label: 'Produto',  icon: '📦', bg: 'bg-blue-50',   text: 'text-blue-700'  },
    service:  { label: 'Serviço',  icon: '🎯', bg: 'bg-violet-50', text: 'text-violet-700' },
    discount: { label: 'Desconto', icon: '🏷️', bg: 'bg-green-50',  text: 'text-green-700' },
  }
  return map[props.reward.category] ?? map.physical
})
</script>
