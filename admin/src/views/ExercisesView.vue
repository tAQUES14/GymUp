<template>
  <div>

    <!-- Page header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
      <div>
        <div class="flex items-center gap-3">
          <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Exercícios</h1>
          <span v-if="!loading && !error"
            class="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs
                   font-semibold bg-brand-50 text-brand-700 border border-brand-100">
            {{ filteredExercises.length }}
          </span>
        </div>
        <p class="text-slate-500 text-sm mt-1">Catálogo de exercícios da academia.</p>
      </div>
      <button @click="openCreate"
        class="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white text-sm
               font-semibold rounded-lg hover:bg-brand-700 transition-colors shadow-sm
               shadow-brand-600/20 flex-shrink-0">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
        </svg>
        Novo Exercício
      </button>
    </div>

    <!-- Error -->
    <div v-if="error" class="card p-8 text-center mb-6">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar exercícios</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadExercises" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else>

      <!-- Search -->
      <div class="flex flex-wrap items-center gap-3 mb-5">
        <div class="relative flex-1 min-w-[200px] max-w-sm">
          <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 pointer-events-none"
            fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
              d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input v-model="search" type="text" placeholder="Buscar exercício…"
            class="w-full pl-9 pr-4 py-2 text-sm border border-slate-200 rounded-lg bg-white
                   focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent
                   placeholder-slate-400 transition" />
          <button v-if="search" @click="search = ''"
            class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <select v-model="muscleFilter"
          class="px-3 py-2 text-sm border border-slate-200 rounded-lg bg-white
                 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent">
          <option value="">Todos os grupos</option>
          <option v-for="g in muscleGroups" :key="g" :value="g">{{ g }}</option>
        </select>

        <select v-model="typeFilter"
          class="px-3 py-2 text-sm border border-slate-200 rounded-lg bg-white
                 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent">
          <option value="">Todos os tipos</option>
          <option value="strength">Musculação</option>
          <option value="cardio">Cardio</option>
          <option value="mobility">Mobilidade</option>
        </select>
      </div>

      <!-- Trainer notice -->
      <div v-if="auth.isTrainer"
        class="flex items-start gap-3 px-4 py-3 mb-5 bg-amber-50 border border-amber-200 rounded-xl text-sm text-amber-800">
        <svg class="w-4 h-4 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z" />
        </svg>
        <span>
          <strong>Treinadores</strong> podem criar novos exercícios e duplicar existentes.
          Para alterar parâmetros por aluno, use as <strong>personalizações de exercício</strong> no perfil do aluno.
        </span>
      </div>

      <!-- Table -->
      <div class="card overflow-hidden">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-slate-100">
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider">Nome</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden md:table-cell">Grupo Muscular</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden lg:table-cell">Tipo</th>
              <th class="text-left px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider hidden xl:table-cell">Conteúdo</th>
              <th class="text-center px-5 py-3.5 text-xs font-semibold text-slate-500 uppercase tracking-wider">Descanso</th>
              <th class="px-5 py-3.5"></th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="6" class="px-5 py-10 text-center">
                <div class="flex items-center justify-center gap-2 text-slate-400">
                  <svg class="animate-spin w-5 h-5" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                  </svg>
                  <span class="text-sm">Carregando…</span>
                </div>
              </td>
            </tr>
            <tr v-else-if="filteredExercises.length === 0">
              <td colspan="6" class="px-5 py-10 text-center text-sm text-slate-400">
                Nenhum exercício encontrado.
              </td>
            </tr>
            <tr v-for="ex in filteredExercises" :key="ex.id"
              class="border-b border-slate-50 hover:bg-slate-50/60 transition-colors">
              <td class="px-5 py-4">
                <p class="font-semibold text-slate-900">{{ ex.name }}</p>
                <p v-if="ex.primary_muscle" class="text-xs text-slate-500 mt-0.5">{{ ex.primary_muscle }}</p>
              </td>
              <td class="px-5 py-4 hidden md:table-cell">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-100 text-slate-700">
                  {{ ex.muscle_group }}
                </span>
              </td>
              <td class="px-5 py-4 hidden lg:table-cell">
                <span :class="typeClass(ex.type)"
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold">
                  {{ typeLabel(ex.type) }}
                </span>
              </td>
              <td class="px-5 py-4 hidden xl:table-cell">
                <div class="flex items-center gap-1.5">
                  <span v-if="ex.execution_steps?.length"
                    class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold bg-green-50 text-green-700">
                    {{ ex.execution_steps.length }} passos
                  </span>
                  <span v-if="ex.gif_file && ex.gif_is_auto === false"
                    class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-50 text-emerald-700">
                    GIF ✓
                  </span>
                  <span v-else-if="ex.gif_file"
                    class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold bg-amber-50 text-amber-700">
                    GIF auto
                  </span>
                  <span v-if="!ex.execution_steps?.length && !ex.gif_file"
                    class="text-xs text-slate-300">—</span>
                </div>
              </td>
              <td class="px-5 py-4 text-center text-sm text-slate-600">
                {{ ex.default_rest }}s
              </td>
              <td class="px-5 py-4">
                <div class="flex items-center justify-end gap-1.5">
                  <!-- Substituições: todos -->
                  <button @click="openSubs(ex)"
                    class="p-1.5 rounded-md text-slate-400 hover:text-violet-600 hover:bg-violet-50 transition-colors"
                    title="Substituições">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 21L3 16.5m0 0L7.5 12M3 16.5h13.5m0-13.5L21 7.5m0 0L16.5 12M21 7.5H7.5" />
                    </svg>
                  </button>
                  <!-- Duplicar: todos -->
                  <button @click="duplicateExercise(ex)" :disabled="duplicatingId === ex.id"
                    class="p-1.5 rounded-md text-slate-400 hover:text-teal-600 hover:bg-teal-50 transition-colors disabled:opacity-40"
                    title="Duplicar exercício">
                    <svg v-if="duplicatingId === ex.id" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                    </svg>
                    <svg v-else class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round"
                        d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 01-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 011.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 00-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 01-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 00-3.375-3.375h-1.5a1.125 1.125 0 01-1.125-1.125v-1.5a3.375 3.375 0 00-3.375-3.375H9.75" />
                    </svg>
                  </button>
                  <!-- Editar: somente gym_admin e super_admin -->
                  <button v-if="canEditLibrary" @click="openEdit(ex)"
                    class="p-1.5 rounded-md text-slate-400 hover:text-brand-600 hover:bg-brand-50 transition-colors"
                    title="Editar">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
                    </svg>
                  </button>
                  <!-- Excluir: somente gym_admin e super_admin -->
                  <button v-if="canEditLibrary" @click="askDelete(ex)"
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

    </template>

    <!-- Duplicate toast -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-200" enter-from-class="opacity-0 translate-y-2"
        enter-to-class="opacity-100 translate-y-0" leave-active-class="transition duration-150"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="duplicateToast"
          class="fixed bottom-6 left-1/2 -translate-x-1/2 z-[80] px-4 py-2.5 bg-slate-900 text-white
                 text-sm font-medium rounded-xl shadow-xl flex items-center gap-2">
          <svg class="w-4 h-4 text-teal-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
          </svg>
          Exercício duplicado com sucesso!
        </div>
      </Transition>
    </Teleport>

    <!-- Create / Edit Modal -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="modalOpen" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="closeModal" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl w-full max-w-2xl flex flex-col max-h-[90vh]">

            <!-- Modal header -->
            <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100 flex-shrink-0">
              <h3 class="text-base font-semibold text-slate-900">
                {{ editTarget ? 'Editar Exercício' : 'Novo Exercício' }}
              </h3>
              <button @click="closeModal"
                class="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-600 transition-colors">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <!-- Modal body (scrollable) -->
            <div class="flex-1 overflow-y-auto px-6 py-5 space-y-5">

              <!-- Basic info -->
              <section>
                <p class="text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-3">Informações básicas</p>
                <div class="grid grid-cols-2 gap-4">
                  <div class="col-span-2">
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Nome *</label>
                    <input v-model="form.name" type="text" placeholder="Ex: Supino Reto com Barra"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Tipo *</label>
                    <select v-model="form.type"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent bg-white">
                      <option value="strength">Musculação</option>
                      <option value="cardio">Cardio</option>
                      <option value="mobility">Mobilidade</option>
                    </select>
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Grupo Muscular *</label>
                    <select v-model="form.muscle_group"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent bg-white">
                      <option value="">Selecionar…</option>
                      <option v-for="g in allMuscleGroups" :key="g" :value="g">{{ g }}</option>
                    </select>
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Músculo Principal</label>
                    <input v-model="form.primary_muscle" type="text" placeholder="Ex: Peitoral maior"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Descanso padrão (s)</label>
                    <input v-model.number="form.default_rest" type="number" min="0" placeholder="60"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
                  </div>

                  <div class="col-span-2">
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Músculos Secundários
                      <span class="text-slate-400 font-normal">(um por linha)</span>
                    </label>
                    <textarea v-model="form.secondary_muscles" rows="2"
                      placeholder="Tríceps&#10;Deltoide anterior"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg resize-none
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
                  </div>

                  <!-- GIF block (edit mode only) -->
                  <div v-if="editTarget" class="col-span-2">
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">GIF animado</label>
                    <div class="flex items-center gap-4 p-3 bg-slate-50 rounded-xl border border-slate-200">
                      <!-- Thumbnail -->
                      <div class="w-16 h-14 flex-shrink-0 rounded-lg border border-slate-200 bg-white
                                  flex items-center justify-center overflow-hidden">
                        <img v-if="editTarget.gif_url" :src="editTarget.gif_url" :alt="editTarget.name"
                          class="w-full h-full object-contain" />
                        <svg v-else class="w-6 h-6 text-slate-300" fill="none" viewBox="0 0 24 24"
                          stroke="currentColor" stroke-width="1.5">
                          <path stroke-linecap="round" stroke-linejoin="round"
                            d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909M3 21h18M3.75 3h16.5M3.75 3v13.5M20.25 3v13.5" />
                        </svg>
                      </div>
                      <!-- Status info -->
                      <div class="flex-1 min-w-0">
                        <div v-if="editTarget.gif_file" class="flex items-center gap-2 flex-wrap">
                          <span v-if="editTarget.gif_is_auto === false"
                            class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                            <svg class="w-2.5 h-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                              <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                            </svg>
                            Confirmado
                          </span>
                          <span v-else
                            class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                            Auto
                            <span v-if="editTarget.gif_confidence" class="opacity-70">{{ editTarget.gif_confidence }}%</span>
                          </span>
                          <span class="text-[11px] text-slate-400 font-mono truncate">{{ editTarget.gif_file }}</span>
                        </div>
                        <p v-else class="text-xs text-slate-400">Sem GIF vinculado</p>
                      </div>
                      <!-- Action button -->
                      <button @click="gifSelectTarget = editTarget"
                        class="flex-shrink-0 inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold
                               bg-brand-600 text-white rounded-lg hover:bg-brand-700 transition-colors shadow-sm">
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round"
                            d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244" />
                        </svg>
                        {{ editTarget.gif_file ? 'Trocar' : 'Vincular GIF' }}
                      </button>
                    </div>
                  </div>
                  <!-- Create mode: GIF not available yet -->
                  <div v-else class="col-span-2">
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">GIF animado</label>
                    <p class="text-xs text-slate-400 px-3 py-2 bg-slate-50 rounded-lg border border-slate-200 border-dashed">
                      Salve o exercício primeiro para vincular um GIF.
                    </p>
                  </div>

                  <div class="col-span-2">
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">Descrição</label>
                    <textarea v-model="form.description" rows="2" placeholder="Breve descrição do exercício…"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg resize-none
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
                  </div>
                </div>
              </section>

              <!-- Educational content -->
              <section class="border-t border-slate-100 pt-5">
                <p class="text-[11px] font-semibold text-slate-400 uppercase tracking-wider mb-3">Conteúdo educacional</p>
                <div class="space-y-4">

                  <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                      Passos de execução
                      <span class="text-slate-400 font-normal">(um por linha)</span>
                    </label>
                    <textarea v-model="form.execution_steps" rows="5"
                      placeholder="1. Posicione-se no banco com as costas retas&#10;2. Segure a barra na largura dos ombros&#10;3. Desça controlando o movimento até o peito"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg resize-y
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                      Erros comuns
                      <span class="text-slate-400 font-normal">(um por linha)</span>
                    </label>
                    <textarea v-model="form.common_mistakes" rows="3"
                      placeholder="Elevar os quadris do banco&#10;Descer a barra de forma descontrolada"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg resize-y
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-slate-600 mb-1.5">
                      Dicas
                      <span class="text-slate-400 font-normal">(uma por linha)</span>
                    </label>
                    <textarea v-model="form.tips" rows="3"
                      placeholder="Inspire ao descer e expire ao subir&#10;Mantenha os pés bem apoiados no chão"
                      class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg resize-y
                             focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
                  </div>

                </div>
              </section>

            </div>

            <!-- Modal footer -->
            <div class="flex items-center gap-3 px-6 py-4 border-t border-slate-100 flex-shrink-0">
              <p v-if="formError" class="flex-1 text-xs text-red-500">{{ formError }}</p>
              <div v-else class="flex-1" />
              <button @click="closeModal" class="btn-secondary">Cancelar</button>
              <button @click="saveExercise" :disabled="saving"
                class="inline-flex items-center justify-center gap-1.5 px-5 py-2 bg-brand-600
                       text-white text-sm font-semibold rounded-lg hover:bg-brand-700 transition-colors
                       disabled:opacity-60 disabled:cursor-not-allowed">
                <svg v-if="saving" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                </svg>
                {{ saving ? 'Salvando…' : (editTarget ? 'Salvar' : 'Criar') }}
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
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Excluir exercício</h3>
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
                       disabled:opacity-60">
                {{ deleting ? 'Excluindo…' : 'Sim, excluir' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- GIF Select Modal -->
    <GifSelectModal
      v-if="gifSelectTarget"
      :exercise="gifSelectTarget"
      @linked="onGifLinked"
      @close="gifSelectTarget = null" />

    <!-- Substitutions Modal -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="subsTarget" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="closeSubs" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-lg flex flex-col max-h-[85vh]">

            <div class="mb-4 flex-shrink-0">
              <h3 class="text-base font-semibold text-slate-900">Substituições</h3>
              <p class="text-xs text-slate-500 mt-0.5">
                Alternativas para <strong class="text-slate-700">{{ subsTarget.name }}</strong>
              </p>
            </div>

            <div class="flex-1 overflow-y-auto min-h-0 mb-4">
              <div v-if="subsLoading" class="flex items-center justify-center py-8 text-slate-400 gap-2">
                <svg class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
                </svg>
                <span class="text-sm">Carregando…</span>
              </div>
              <div v-else-if="substitutions.length === 0"
                class="text-sm text-slate-400 text-center py-6 border border-dashed border-slate-200 rounded-xl">
                Nenhuma substituição cadastrada.
              </div>
              <ul v-else class="space-y-2">
                <li v-for="sub in substitutions" :key="sub.id"
                  class="flex items-center justify-between gap-3 px-3 py-2.5 bg-slate-50
                         rounded-xl border border-slate-100">
                  <div class="min-w-0">
                    <p class="text-sm font-semibold text-slate-800 truncate">{{ sub.name }}</p>
                    <p class="text-xs text-slate-500">{{ sub.muscle_group }} · {{ typeLabel(sub.type) }}</p>
                  </div>
                  <button @click="removeSub(sub.id)"
                    class="flex-shrink-0 p-1 rounded-md text-slate-400 hover:text-red-500
                           hover:bg-red-50 transition-colors">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </li>
              </ul>
            </div>

            <div class="flex-shrink-0 border-t border-slate-100 pt-4">
              <p class="text-xs font-semibold text-slate-600 mb-2">Adicionar substituto</p>
              <div class="relative">
                <input v-model="subsSearch" @input="onSubsSearchInput" type="text"
                  placeholder="Buscar exercício para adicionar…"
                  class="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg
                         focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent" />
              </div>
              <ul v-if="subsSearchResults.length > 0"
                class="mt-2 border border-slate-200 rounded-xl overflow-hidden divide-y divide-slate-100 max-h-48 overflow-y-auto">
                <li v-for="res in subsSearchResults" :key="res.id"
                  class="flex items-center justify-between gap-3 px-3 py-2.5 hover:bg-slate-50 transition-colors">
                  <div class="min-w-0">
                    <p class="text-sm font-medium text-slate-800 truncate">{{ res.name }}</p>
                    <p class="text-xs text-slate-500">{{ res.muscle_group }} · {{ typeLabel(res.type) }}</p>
                  </div>
                  <button @click="addSub(res)"
                    :disabled="isAlreadySub(res.id)"
                    class="flex-shrink-0 inline-flex items-center gap-1 px-2.5 py-1 text-xs font-semibold
                           bg-brand-600 text-white rounded-lg hover:bg-brand-700 transition-colors
                           disabled:opacity-40 disabled:cursor-not-allowed">
                    {{ isAlreadySub(res.id) ? 'Adicionado' : 'Adicionar' }}
                  </button>
                </li>
              </ul>
              <p v-if="subsError" class="text-xs text-red-500 mt-2">{{ subsError }}</p>
            </div>

            <button @click="closeSubs" class="mt-4 w-full btn-secondary flex-shrink-0">Fechar</button>
          </div>
        </div>
      </Transition>
    </Teleport>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '../services/api.js'
import { useAuthStore } from '../stores/auth.js'
import GifSelectModal from '../components/exercises/GifSelectModal.vue'

const auth = useAuthStore()

// Only gym_admin and super_admin can edit/delete library exercises
const canEditLibrary = computed(() => auth.isGymAdmin || auth.isSuperAdmin)

const allExercises  = ref([])
const loading       = ref(true)
const error         = ref('')
const search        = ref('')
const muscleFilter  = ref('')
const typeFilter    = ref('')
const modalOpen     = ref(false)
const editTarget    = ref(null)
const saving        = ref(false)
const formError     = ref('')
const deleteTarget  = ref(null)
const deleting      = ref(false)
const deleteError   = ref('')
const duplicatingId = ref(null)
const duplicateToast = ref(false)

// GIF selection modal
const gifSelectTarget = ref(null)

// Substitutions state
const subsTarget        = ref(null)
const substitutions     = ref([])
const subsLoading       = ref(false)
const subsSearch        = ref('')
const subsSearchResults = ref([])
const subsError         = ref('')
let   subsSearchTimer   = null

const allMuscleGroups = [
  'Peito', 'Costas', 'Ombros', 'Bíceps', 'Tríceps', 'Pernas', 'Abdômen',
  'Glúteos', 'Panturrilha', 'Antebraço', 'Cardio', 'Funcional',
]

// Array ↔ line-separated text helpers
const toLines   = (arr) => Array.isArray(arr) ? arr.join('\n') : (arr ?? '')
const fromLines = (str) => (str ?? '').split('\n').map((s) => s.trim()).filter(Boolean)

const emptyForm = () => ({
  name: '', type: 'strength', muscle_group: '', primary_muscle: '',
  secondary_muscles: '', description: '', default_rest: 60,
  execution_steps: '', common_mistakes: '', tips: '',
})

const typeLabel = (t) => ({ strength: 'Musculação', cardio: 'Cardio', mobility: 'Mobilidade' }[t] ?? t)
const typeClass = (t) => ({
  strength: 'bg-blue-50 text-blue-700',
  cardio:   'bg-orange-50 text-orange-700',
  mobility: 'bg-green-50 text-green-700',
}[t] ?? 'bg-slate-100 text-slate-700')

const form = ref(emptyForm())

const muscleGroups = computed(() => {
  const groups = new Set(allExercises.value.map((e) => e.muscle_group).filter(Boolean))
  return Array.from(groups).sort()
})

const filteredExercises = computed(() => {
  let result = allExercises.value
  const q = search.value.trim().toLowerCase()
  if (q) result = result.filter((e) => e.name.toLowerCase().includes(q))
  if (muscleFilter.value) result = result.filter((e) => e.muscle_group === muscleFilter.value)
  if (typeFilter.value)   result = result.filter((e) => (e.type ?? 'strength') === typeFilter.value)
  return result
})

async function loadExercises() {
  loading.value = true; error.value = ''
  try {
    const { data } = await api.get('/admin/exercises')
    allExercises.value = data.exercises ?? []
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar os exercícios.'
  } finally { loading.value = false }
}

function openCreate() {
  editTarget.value = null
  form.value = emptyForm()
  formError.value = ''
  modalOpen.value = true
}

function openEdit(ex) {
  editTarget.value = ex
  form.value = {
    name:              ex.name,
    type:              ex.type ?? 'strength',
    muscle_group:      ex.muscle_group,
    primary_muscle:    ex.primary_muscle ?? '',
    secondary_muscles: toLines(ex.secondary_muscles),
    description:       ex.description ?? '',
    default_rest:      ex.default_rest ?? 60,
    execution_steps:   toLines(ex.execution_steps),
    common_mistakes:   toLines(ex.common_mistakes),
    tips:              toLines(ex.tips),
  }
  formError.value = ''
  modalOpen.value = true
}

function closeModal() {
  if (!saving.value) modalOpen.value = false
}

async function saveExercise() {
  if (!form.value.name.trim())         { formError.value = 'Nome é obrigatório.'; return }
  if (!form.value.muscle_group.trim()) { formError.value = 'Grupo muscular é obrigatório.'; return }
  saving.value = true; formError.value = ''

  const payload = {
    name:              form.value.name.trim(),
    type:              form.value.type,
    muscle_group:      form.value.muscle_group,
    primary_muscle:    form.value.primary_muscle.trim() || null,
    secondary_muscles: fromLines(form.value.secondary_muscles),
    description:       form.value.description.trim() || null,
    default_rest:      form.value.default_rest,
    execution_steps:   fromLines(form.value.execution_steps),
    common_mistakes:   fromLines(form.value.common_mistakes),
    tips:              fromLines(form.value.tips),
  }

  try {
    if (editTarget.value) {
      const { data } = await api.put(`/admin/exercises/${editTarget.value.id}`, payload)
      const idx = allExercises.value.findIndex((e) => e.id === editTarget.value.id)
      if (idx !== -1) allExercises.value[idx] = data.exercise
    } else {
      const { data } = await api.post('/admin/exercises', payload)
      allExercises.value.push(data.exercise)
    }
    modalOpen.value = false
  } catch (e) {
    formError.value = e.response?.data?.message ?? 'Erro ao salvar exercício.'
  } finally { saving.value = false }
}

function askDelete(ex)   { deleteError.value = ''; deleteTarget.value = ex }
function cancelDelete()  { if (!deleting.value) deleteTarget.value = null }

async function confirmDelete() {
  if (!deleteTarget.value) return
  deleting.value = true; deleteError.value = ''
  try {
    await api.delete(`/admin/exercises/${deleteTarget.value.id}`)
    allExercises.value = allExercises.value.filter((e) => e.id !== deleteTarget.value.id)
    deleteTarget.value = null
  } catch (e) {
    deleteError.value = e.response?.data?.message ?? 'Erro ao excluir exercício.'
  } finally { deleting.value = false }
}

async function duplicateExercise(ex) {
  if (duplicatingId.value) return
  duplicatingId.value = ex.id
  try {
    const { data } = await api.post(`/admin/exercises/${ex.id}/duplicate`)
    allExercises.value.push(data.exercise)
    duplicateToast.value = true
    setTimeout(() => { duplicateToast.value = false }, 3000)
  } catch {
    // silencioso
  } finally { duplicatingId.value = null }
}

// ── Substitutions ────────────────────────────────────────────────────────────

function isAlreadySub(id) {
  return substitutions.value.some((s) => s.id === id)
}

async function openSubs(ex) {
  subsTarget.value = ex
  substitutions.value = []
  subsSearch.value = ''
  subsSearchResults.value = []
  subsError.value = ''
  subsLoading.value = true
  try {
    const { data } = await api.get(`/admin/exercises/${ex.id}/substitutions`)
    substitutions.value = data.substitutions ?? []
  } catch {
    subsError.value = 'Erro ao carregar substituições.'
  } finally {
    subsLoading.value = false
  }
}

function closeSubs() {
  subsTarget.value = null
  clearTimeout(subsSearchTimer)
}

function onSubsSearchInput() {
  clearTimeout(subsSearchTimer)
  const q = subsSearch.value.trim()
  if (q.length < 2) { subsSearchResults.value = []; return }
  subsSearchTimer = setTimeout(() => runSubsSearch(q), 300)
}

async function runSubsSearch(q) {
  try {
    const { data } = await api.get('/admin/exercises', { params: { search: q } })
    subsSearchResults.value = (data.exercises ?? []).filter(
      (e) => e.id !== subsTarget.value?.id
    )
  } catch {
    subsSearchResults.value = []
  }
}

async function addSub(ex) {
  if (!subsTarget.value || isAlreadySub(ex.id)) return
  subsError.value = ''
  try {
    await api.post(`/admin/exercises/${subsTarget.value.id}/substitutions`, {
      substitute_exercise_id: ex.id,
    })
    substitutions.value.push({ id: ex.id, name: ex.name, muscle_group: ex.muscle_group, type: ex.type })
    subsSearch.value = ''
    subsSearchResults.value = []
  } catch (e) {
    subsError.value = e.response?.data?.message ?? 'Erro ao adicionar substituição.'
  }
}

async function removeSub(substituteId) {
  if (!subsTarget.value) return
  subsError.value = ''
  try {
    await api.delete(`/admin/exercises/${subsTarget.value.id}/substitutions/${substituteId}`)
    substitutions.value = substitutions.value.filter((s) => s.id !== substituteId)
  } catch (e) {
    subsError.value = e.response?.data?.message ?? 'Erro ao remover substituição.'
  }
}

function onGifLinked(exerciseData) {
  if (!editTarget.value) return
  // Patch the exercise in the list and editTarget so the block re-renders
  const idx = allExercises.value.findIndex((e) => e.id === editTarget.value.id)
  if (idx !== -1) {
    allExercises.value[idx] = {
      ...allExercises.value[idx],
      gif_file:       exerciseData.gif_file,
      gif_url:        exerciseData.gif_url,
      gif_confidence: exerciseData.gif_confidence,
      gif_is_auto:    exerciseData.gif_is_auto,
    }
    editTarget.value = allExercises.value[idx]
  }
  gifSelectTarget.value = null
}

onMounted(loadExercises)
</script>
