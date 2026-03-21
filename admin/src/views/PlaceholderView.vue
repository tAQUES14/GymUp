<template>
  <div>

    <!-- Page header -->
    <div class="mb-8">
      <h1 class="text-2xl font-bold text-slate-900 tracking-tight">{{ page }}</h1>
      <p class="text-slate-500 text-sm mt-1">{{ description }}</p>
    </div>

    <!-- Placeholder card -->
    <div class="card p-16 flex flex-col items-center justify-center text-center">
      <div class="text-6xl mb-5 select-none">{{ icon }}</div>
      <h2 class="text-lg font-semibold text-slate-700 mb-2">Em desenvolvimento</h2>
      <p class="text-sm text-slate-400 max-w-sm">
        Esta seção está sendo desenvolvida e em breve estará disponível.
      </p>

      <!-- Progress pill -->
      <div class="mt-6 flex items-center gap-2 px-3 py-1.5 bg-brand-50 rounded-full">
        <span class="w-2 h-2 rounded-full bg-brand-500 animate-pulse" />
        <span class="text-xs font-medium text-brand-600">Em breve</span>
      </div>
    </div>

  </div>
</template>

<script setup>
defineProps({
  page:        { type: String, default: 'Página' },
  icon:        { type: String, default: '🚧' },
  description: { type: String, default: 'Esta funcionalidade está em desenvolvimento.' },
})
</script>
