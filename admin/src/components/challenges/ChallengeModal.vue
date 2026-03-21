<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <div v-if="modelValue" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="close" />

        <div class="relative z-10 bg-white rounded-2xl shadow-2xl w-full max-w-xl flex flex-col"
             style="max-height: min(90vh, 700px)">

          <!-- ── HEADER ─────────────────────────────────────────── -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100 flex-shrink-0">
            <div class="flex items-center gap-3">
              <!-- Type icon when on step 2 -->
              <div v-if="isEdit || step === 2"
                   class="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                   :class="form.type === 'competitive' ? 'bg-violet-100' : 'bg-amber-100'">
                <svg v-if="form.type === 'competitive'" class="w-4 h-4 text-violet-600"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 18.75h-9m9 0a3 3 0 013 3h-15a3 3 0 013-3m9 0v-3.375c0-.621-.503-1.125-1.125-1.125h-.871M7.5 18.75v-3.375c0-.621.504-1.125 1.125-1.125h.872m5.007 0H9.497m5.007 0a7.454 7.454 0 01-.982-3.172M9.497 14.25a7.454 7.454 0 00.981-3.172M5.25 4.236c-.982.143-1.954.317-2.916.52A6.003 6.003 0 007.73 9.728M5.25 4.236V4.5c0 2.108.966 3.99 2.48 5.228M5.25 4.236V2.721C7.456 2.41 9.71 2.25 12 2.25c2.291 0 4.545.16 6.75.47v1.516M7.73 9.728a6.726 6.726 0 002.748 1.35m8.272-6.842V4.5c0 2.108-.966 3.99-2.48 5.228m2.48-5.492a46.32 46.32 0 012.916.52 6.003 6.003 0 01-5.395 4.972m0 0a6.726 6.726 0 01-2.749 1.35m0 0a6.772 6.772 0 01-3.044 0" />
                </svg>
                <svg v-else class="w-4 h-4 text-amber-600"
                     fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                </svg>
              </div>
              <div>
                <h2 class="text-sm font-bold text-slate-900 leading-tight">
                  {{ isEdit ? 'Editar desafio' : (step === 1 ? 'Novo desafio' : typeLabel) }}
                </h2>
                <p v-if="!isEdit && step === 1" class="text-xs text-slate-400 mt-0.5">Escolha o tipo para continuar</p>
                <p v-if="!isEdit && step === 2" class="text-xs text-slate-400 mt-0.5">Passo 2 de 2</p>
              </div>
            </div>

            <div class="flex items-center gap-2">
              <!-- Step indicator (create only) -->
              <div v-if="!isEdit" class="flex items-center gap-1.5 mr-2">
                <div class="w-6 h-1.5 rounded-full transition-colors"
                     :class="step >= 1 ? 'bg-brand-500' : 'bg-slate-200'" />
                <div class="w-6 h-1.5 rounded-full transition-colors"
                     :class="step >= 2 ? 'bg-brand-500' : 'bg-slate-200'" />
              </div>
              <button @click="close" class="text-slate-400 hover:text-slate-600 transition-colors p-1">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>

          <!-- ── BODY ──────────────────────────────────────────── -->
          <div class="overflow-y-auto flex-1 min-h-0">

            <!-- STEP 1: Tipo -->
            <div v-if="!isEdit && step === 1" class="px-6 py-8">
              <p class="text-center text-slate-500 text-sm mb-6">
                Qual modelo de desafio você quer criar?
              </p>
              <div class="grid grid-cols-2 gap-4">

                <!-- Competitivo -->
                <button type="button" @click="selectType('competitive')"
                  class="group flex flex-col items-center gap-3 p-5 rounded-2xl border-2 transition-all text-left"
                  :class="form.type === 'competitive'
                    ? 'border-violet-500 bg-violet-50 shadow-sm shadow-violet-100'
                    : 'border-slate-200 hover:border-violet-300 hover:bg-violet-50/40'"
                >
                  <div class="w-12 h-12 rounded-2xl flex items-center justify-center transition-colors"
                       :class="form.type === 'competitive' ? 'bg-violet-500' : 'bg-violet-100 group-hover:bg-violet-200'">
                    <svg class="w-6 h-6 transition-colors"
                         :class="form.type === 'competitive' ? 'text-white' : 'text-violet-500'"
                         fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 18.75h-9m9 0a3 3 0 013 3h-15a3 3 0 013-3m9 0v-3.375c0-.621-.503-1.125-1.125-1.125h-.871M7.5 18.75v-3.375c0-.621.504-1.125 1.125-1.125h.872m5.007 0H9.497m5.007 0a7.454 7.454 0 01-.982-3.172M9.497 14.25a7.454 7.454 0 00.981-3.172M5.25 4.236c-.982.143-1.954.317-2.916.52A6.003 6.003 0 007.73 9.728M5.25 4.236V4.5c0 2.108.966 3.99 2.48 5.228M5.25 4.236V2.721C7.456 2.41 9.71 2.25 12 2.25c2.291 0 4.545.16 6.75.47v1.516M7.73 9.728a6.726 6.726 0 002.748 1.35m8.272-6.842V4.5c0 2.108-.966 3.99-2.48 5.228m2.48-5.492a46.32 46.32 0 012.916.52 6.003 6.003 0 01-5.395 4.972m0 0a6.726 6.726 0 01-2.749 1.35m0 0a6.772 6.772 0 01-3.044 0" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-bold text-slate-900 mb-1">Competitivo</p>
                    <ul class="text-[11px] text-slate-500 space-y-0.5">
                      <li class="flex items-center gap-1"><span class="text-violet-400">✓</span> Ranking semanal</li>
                      <li class="flex items-center gap-1"><span class="text-violet-400">✓</span> Pontos por posição</li>
                      <li class="flex items-center gap-1"><span class="text-violet-400">✓</span> Metas semanais</li>
                    </ul>
                  </div>
                  <div v-if="form.type === 'competitive'"
                    class="w-5 h-5 rounded-full bg-violet-500 flex items-center justify-center mt-auto">
                    <svg class="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                </button>

                <!-- Simples -->
                <button type="button" @click="selectType('simple')"
                  class="group flex flex-col items-center gap-3 p-5 rounded-2xl border-2 transition-all text-left"
                  :class="form.type === 'simple'
                    ? 'border-amber-500 bg-amber-50 shadow-sm shadow-amber-100'
                    : 'border-slate-200 hover:border-amber-300 hover:bg-amber-50/40'"
                >
                  <div class="w-12 h-12 rounded-2xl flex items-center justify-center transition-colors"
                       :class="form.type === 'simple' ? 'bg-amber-500' : 'bg-amber-100 group-hover:bg-amber-200'">
                    <svg class="w-6 h-6 transition-colors"
                         :class="form.type === 'simple' ? 'text-white' : 'text-amber-500'"
                         fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-bold text-slate-900 mb-1">Simples</p>
                    <ul class="text-[11px] text-slate-500 space-y-0.5">
                      <li class="flex items-center gap-1"><span class="text-amber-400">✓</span> Meta de treinos</li>
                      <li class="flex items-center gap-1"><span class="text-amber-400">✓</span> Recompensa ao concluir</li>
                      <li class="flex items-center gap-1"><span class="text-amber-400">✓</span> Sem ranking</li>
                    </ul>
                  </div>
                  <div v-if="form.type === 'simple'"
                    class="w-5 h-5 rounded-full bg-amber-500 flex items-center justify-center mt-auto">
                    <svg class="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                  </div>
                </button>

              </div>
            </div>

            <!-- STEP 2 (or edit): Form -->
            <div v-else class="px-6 py-5 space-y-6">

              <!-- ◆ SEÇÃO: Informações básicas -->
              <section>
                <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-3">Informações</p>
                <div class="space-y-3">

                  <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-1.5">Nome do desafio</label>
                    <input v-model="form.name" type="text" placeholder="Ex: Desafio de março"
                      class="input-field w-full" :class="{ 'border-red-400 focus:ring-red-400': errors.name }" />
                    <p v-if="errors.name" class="text-xs text-red-500 mt-1">{{ errors.name }}</p>
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-1.5">
                      Descrição
                      <span class="text-slate-400 font-normal ml-1">— opcional</span>
                    </label>
                    <textarea v-model="form.description" rows="2"
                      placeholder="Descreva o objetivo do desafio para os alunos…"
                      class="input-field w-full resize-none" />
                  </div>

                  <div class="grid grid-cols-2 gap-3">
                    <div>
                      <label class="block text-xs font-semibold text-slate-700 mb-1.5">Data de início</label>
                      <input v-model="form.starts_at" type="date" class="input-field w-full"
                        :class="{ 'border-red-400': errors.starts_at }" />
                      <p v-if="errors.starts_at" class="text-xs text-red-500 mt-1">{{ errors.starts_at }}</p>
                    </div>
                    <div>
                      <label class="block text-xs font-semibold text-slate-700 mb-1.5">Data de término</label>
                      <input v-model="form.ends_at" type="date" class="input-field w-full"
                        :class="{ 'border-red-400': errors.ends_at }" />
                      <p v-if="errors.ends_at" class="text-xs text-red-500 mt-1">{{ errors.ends_at }}</p>
                    </div>
                  </div>

                  <!-- Duration preview -->
                  <div v-if="durationLabel"
                    class="flex items-center gap-2 px-3 py-2 bg-slate-50 rounded-lg text-xs text-slate-500">
                    <svg class="w-3.5 h-3.5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    Duração: <strong class="text-slate-700">{{ durationLabel }}</strong>
                  </div>

                </div>
              </section>

              <!-- ◆ SEÇÃO: Configuração (Competitivo) -->
              <section v-if="form.type === 'competitive'">
                <div class="flex items-center gap-2 mb-3">
                  <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest">Configuração</p>
                  <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold bg-violet-50 text-violet-600">Competitivo</span>
                </div>

                <div class="bg-slate-50 rounded-xl p-4 space-y-4">

                  <!-- Treinos por semana -->
                  <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-2">Treinos por semana</label>
                    <div class="grid grid-cols-2 gap-3">
                      <div>
                        <p class="text-[10px] text-slate-500 mb-1">Mínimo</p>
                        <div class="flex items-center gap-2">
                          <button type="button" @click="adjustMin(-1)"
                            class="w-7 h-7 rounded-lg bg-white border border-slate-200 flex items-center justify-center
                                   text-slate-600 hover:bg-slate-100 transition-colors text-sm font-bold">−</button>
                          <span class="w-8 text-center text-sm font-bold text-slate-800">{{ form.min_weekly_workouts }}</span>
                          <button type="button" @click="adjustMin(1)"
                            class="w-7 h-7 rounded-lg bg-white border border-slate-200 flex items-center justify-center
                                   text-slate-600 hover:bg-slate-100 transition-colors text-sm font-bold">+</button>
                        </div>
                      </div>
                      <div>
                        <p class="text-[10px] text-slate-500 mb-1">Máximo</p>
                        <div class="flex items-center gap-2">
                          <button type="button" @click="adjustMax(-1)"
                            class="w-7 h-7 rounded-lg bg-white border border-slate-200 flex items-center justify-center
                                   text-slate-600 hover:bg-slate-100 transition-colors text-sm font-bold">−</button>
                          <span class="w-8 text-center text-sm font-bold text-slate-800">{{ form.max_weekly_workouts }}</span>
                          <button type="button" @click="adjustMax(1)"
                            class="w-7 h-7 rounded-lg bg-white border border-slate-200 flex items-center justify-center
                                   text-slate-600 hover:bg-slate-100 transition-colors text-sm font-bold">+</button>
                        </div>
                      </div>
                    </div>
                  </div>

                  <!-- Pontos por posição -->
                  <div>
                    <div class="flex items-center justify-between mb-2">
                      <label class="text-xs font-semibold text-slate-700">Pontos por posição semanal</label>
                      <button type="button" @click="addPosition"
                        class="text-xs text-brand-600 font-semibold hover:text-brand-800 transition-colors">
                        + Posição
                      </button>
                    </div>
                    <div class="space-y-2">
                      <div v-for="(pts, i) in pointsConfig" :key="i"
                        class="flex items-center gap-2 bg-white rounded-lg px-3 py-2 border border-slate-200">
                        <span class="text-xs font-bold w-7 flex-shrink-0"
                              :class="i === 0 ? 'text-yellow-500' : i === 1 ? 'text-slate-400' : i === 2 ? 'text-amber-500' : 'text-slate-400'">
                          {{ ordinal(i + 1) }}
                        </span>
                        <input
                          type="number"
                          :value="pts"
                          @input="pointsConfig[i] = parseInt($event.target.value) || 0"
                          min="0"
                          class="flex-1 text-sm font-bold text-slate-800 bg-transparent outline-none min-w-0
                                 [appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none"
                          placeholder="0"
                        />
                        <span class="text-xs text-slate-400 flex-shrink-0">pts</span>
                        <button v-if="pointsConfig.length > 1" type="button" @click="removePosition(i)"
                          class="text-slate-300 hover:text-red-400 transition-colors flex-shrink-0 p-0.5">
                          <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                          </svg>
                        </button>
                      </div>
                    </div>
                    <p class="text-[10px] text-slate-400 mt-2">Cada posição no ranking semanal recebe esses pontos.</p>
                  </div>

                </div>
              </section>

              <!-- ◆ SEÇÃO: Configuração (Simples) -->
              <section v-if="form.type === 'simple'">
                <div class="flex items-center gap-2 mb-3">
                  <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest">Configuração</p>
                  <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-semibold bg-amber-50 text-amber-600">Simples</span>
                </div>

                <div class="bg-slate-50 rounded-xl p-4 space-y-4">

                  <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-1.5">Meta de treinos</label>
                    <div class="flex items-center gap-3">
                      <button type="button" @click="form.goal_workouts = Math.max(1, (form.goal_workouts || 1) - 1)"
                        class="w-9 h-9 rounded-xl bg-white border border-slate-200 flex items-center justify-center
                               text-slate-600 hover:bg-slate-100 transition-colors text-lg font-bold flex-shrink-0">−</button>
                      <div class="flex-1 relative">
                        <input v-model.number="form.goal_workouts" type="number" min="1"
                          class="input-field w-full text-center text-xl font-bold pr-16" placeholder="20" />
                        <span class="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-slate-400">treinos</span>
                      </div>
                      <button type="button" @click="form.goal_workouts = (form.goal_workouts || 0) + 1"
                        class="w-9 h-9 rounded-xl bg-white border border-slate-200 flex items-center justify-center
                               text-slate-600 hover:bg-slate-100 transition-colors text-lg font-bold flex-shrink-0">+</button>
                    </div>
                    <p class="text-[10px] text-slate-400 mt-1.5 text-center">Quantidade de treinos para completar o desafio.</p>
                  </div>

                  <div>
                    <label class="block text-xs font-semibold text-slate-700 mb-1.5">
                      Pontos ao concluir
                      <span class="text-slate-400 font-normal ml-1">— opcional</span>
                    </label>
                    <div class="relative">
                      <input v-model.number="form.reward_points" type="number" min="0"
                        class="input-field w-full pl-8" placeholder="500" />
                      <span class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09z" />
                        </svg>
                      </span>
                    </div>
                  </div>

                </div>
              </section>

              <!-- ◆ SEÇÃO: Recompensa -->
              <section>
                <p class="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-3">Recompensa</p>
                <div class="bg-slate-50 rounded-xl p-4 space-y-3">

                  <div class="grid grid-cols-3 gap-2">
                    <button v-for="opt in rewardTypes" :key="opt.value" type="button"
                      @click="form.reward_type = opt.value"
                      class="flex flex-col items-center gap-1.5 py-2.5 px-2 rounded-xl border-2 text-xs font-semibold transition-all"
                      :class="form.reward_type === opt.value
                        ? 'border-brand-500 bg-white text-brand-700 shadow-sm'
                        : 'border-transparent bg-white text-slate-500 hover:border-slate-200'"
                    >
                      <span class="text-base">{{ opt.emoji }}</span>
                      {{ opt.label }}
                    </button>
                  </div>

                  <div v-if="form.reward_type !== 'none'">
                    <label class="block text-xs font-semibold text-slate-700 mb-1.5">Descrição da recompensa</label>
                    <input v-model="form.reward_description" type="text"
                      :placeholder="form.reward_type === 'physical' ? 'Ex: Camiseta GymUp exclusiva' : 'Ex: Pontos dobrados na próxima semana'"
                      class="input-field w-full bg-white" />
                  </div>

                </div>
              </section>

              <!-- API error -->
              <div v-if="apiError"
                class="flex items-start gap-2 px-3 py-2.5 bg-red-50 border border-red-200 rounded-lg">
                <svg class="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
                </svg>
                <p class="text-xs text-red-600">{{ apiError }}</p>
              </div>

            </div>
          </div>

          <!-- ── FOOTER ─────────────────────────────────────────── -->
          <div class="flex items-center justify-between gap-3 px-6 py-4 border-t border-slate-100 flex-shrink-0">

            <!-- Step 1: just Cancelar -->
            <template v-if="!isEdit && step === 1">
              <button @click="close" class="btn-secondary">Cancelar</button>
              <button @click="goToStep2"
                :disabled="!form.type"
                class="inline-flex items-center gap-1.5 px-5 py-2 bg-brand-600 text-white text-sm
                       font-semibold rounded-lg hover:bg-brand-700 transition-colors
                       disabled:opacity-40 disabled:cursor-not-allowed">
                Próximo
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                </svg>
              </button>
            </template>

            <!-- Step 2 / Edit -->
            <template v-else>
              <button v-if="!isEdit" @click="step = 1"
                class="inline-flex items-center gap-1.5 btn-secondary">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
                </svg>
                Voltar
              </button>
              <button v-else @click="close" class="btn-secondary">Cancelar</button>

              <button @click="submit" :disabled="saving"
                class="inline-flex items-center gap-1.5 px-5 py-2 bg-brand-600 text-white text-sm
                       font-semibold rounded-lg hover:bg-brand-700 transition-colors
                       disabled:opacity-60 disabled:cursor-not-allowed">
                <svg v-if="saving" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
                {{ saving ? 'Salvando…' : (isEdit ? 'Salvar alterações' : 'Criar desafio') }}
              </button>
            </template>

          </div>

        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import api from '../../services/api.js'

const props = defineProps({
  modelValue:      { type: Boolean, required: true },
  challengeToEdit: { type: Object,  default: null  },
})
const emit = defineEmits(['update:modelValue', 'saved'])

const isEdit = computed(() => !!props.challengeToEdit)

const rewardTypes = [
  { value: 'points',   label: 'Pontos',    emoji: '⭐' },
  { value: 'physical', label: 'Prêmio',    emoji: '🎁' },
  { value: 'none',     label: 'Nenhuma',   emoji: '—' },
]

const typeLabel = computed(() =>
  form.value.type === 'competitive' ? 'Desafio Competitivo' : 'Desafio Simples'
)

// ── State ─────────────────────────────────────────────────────────
const step          = ref(1)
const form          = ref(defaultForm())
const pointsConfig  = ref([100, 75, 50, 25])
const saving        = ref(false)
const apiError      = ref('')
const errors        = ref({})

function defaultForm() {
  return {
    type:                'competitive',
    name:                '',
    description:         '',
    starts_at:           '',
    ends_at:             '',
    min_weekly_workouts: 3,
    max_weekly_workouts: 7,
    goal_workouts:       20,
    reward_points:       null,
    reward_type:         'points',
    reward_description:  '',
  }
}

// ── Watchers ──────────────────────────────────────────────────────
watch(() => props.modelValue, (open) => {
  if (!open) return
  apiError.value = ''
  errors.value   = {}
  step.value     = 1

  if (props.challengeToEdit) {
    const c = props.challengeToEdit
    form.value = {
      type:                c.type,
      name:                c.name ?? '',
      description:         c.description ?? '',
      starts_at:           c.starts_at?.slice(0, 10) ?? '',
      ends_at:             c.ends_at?.slice(0, 10) ?? '',
      min_weekly_workouts: c.min_weekly_workouts ?? 3,
      max_weekly_workouts: c.max_weekly_workouts ?? 7,
      goal_workouts:       c.goal_workouts ?? 20,
      reward_points:       c.reward_points ?? null,
      reward_type:         c.reward_type ?? 'points',
      reward_description:  c.reward_description ?? '',
    }
    pointsConfig.value = Array.isArray(c.weekly_points_config) && c.weekly_points_config.length
      ? [...c.weekly_points_config]
      : [100, 75, 50, 25]
  } else {
    form.value     = defaultForm()
    pointsConfig.value = [100, 75, 50, 25]
  }
})

// ── Duration preview ──────────────────────────────────────────────
const durationLabel = computed(() => {
  if (!form.value.starts_at || !form.value.ends_at) return ''
  const days = Math.round(
    (new Date(form.value.ends_at) - new Date(form.value.starts_at)) / 864e5
  )
  if (days <= 0) return ''
  const weeks = Math.floor(days / 7)
  const rem   = days % 7
  if (weeks > 0 && rem === 0) return `${weeks} semana${weeks !== 1 ? 's' : ''}`
  if (weeks > 0) return `${weeks} semana${weeks !== 1 ? 's' : ''} e ${rem} dia${rem !== 1 ? 's' : ''}`
  return `${days} dia${days !== 1 ? 's' : ''}`
})

// ── Helpers ───────────────────────────────────────────────────────
function selectType(t) { form.value.type = t }
function goToStep2()   { step.value = 2 }

function adjustMin(delta) {
  const v = (form.value.min_weekly_workouts ?? 1) + delta
  form.value.min_weekly_workouts = Math.min(Math.max(1, v), form.value.max_weekly_workouts ?? 7)
}
function adjustMax(delta) {
  const v = (form.value.max_weekly_workouts ?? 7) + delta
  form.value.max_weekly_workouts = Math.min(Math.max(form.value.min_weekly_workouts ?? 1, v), 7)
}

function addPosition()        { pointsConfig.value.push(0) }
function removePosition(i)    { pointsConfig.value.splice(i, 1) }
function ordinal(n)           { return `${n}º` }

function close() {
  if (!saving.value) emit('update:modelValue', false)
}

// ── Validation ────────────────────────────────────────────────────
function validate() {
  const e = {}
  if (!form.value.name.trim()) e.name = 'Nome é obrigatório.'
  if (!form.value.starts_at)   e.starts_at = 'Informe a data de início.'
  if (!form.value.ends_at)     e.ends_at   = 'Informe a data de término.'
  if (form.value.starts_at && form.value.ends_at && form.value.ends_at <= form.value.starts_at)
    e.ends_at = 'A data de término deve ser após o início.'
  errors.value = e
  return Object.keys(e).length === 0
}

// ── Submit ────────────────────────────────────────────────────────
async function submit() {
  apiError.value = ''
  if (!validate()) return

  saving.value = true
  try {
    const payload = { ...form.value }

    if (form.value.type === 'competitive') {
      payload.weekly_points_config = pointsConfig.value.map(Number).filter((v) => !isNaN(v))
    } else {
      delete payload.min_weekly_workouts
      delete payload.max_weekly_workouts
      delete payload.weekly_points_config
    }

    if (isEdit.value) {
      await api.put(`/admin/challenges/${props.challengeToEdit.id}`, payload)
    } else {
      await api.post('/admin/challenges', payload)
    }

    emit('saved')
    emit('update:modelValue', false)
  } catch (e) {
    apiError.value = e.response?.data?.message ?? 'Ocorreu um erro ao salvar.'
  } finally {
    saving.value = false
  }
}
</script>
