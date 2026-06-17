<template>
  <div @click="handlePageClick">

    <!-- Back + header -->
    <div class="flex items-center gap-3 mb-6">
      <button @click="router.back()"
        class="p-2 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors flex-shrink-0">
        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
        </svg>
      </button>
      <div class="flex-1 min-w-0">
        <h1 class="text-2xl font-bold text-slate-900 tracking-tight truncate">
          <span v-if="loading" class="inline-block w-40 h-6 bg-slate-100 rounded animate-pulse" />
          <template v-else>{{ plan?.name }}</template>
        </h1>
        <p v-if="!loading && plan?.description" class="text-slate-500 text-sm mt-0.5">{{ plan.description }}</p>
      </div>
    </div>

    <!-- Error -->
    <div v-if="error" class="card p-8 text-center mb-6">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar plano</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadPlan" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else-if="!loading">

      <!-- ── Steps list ─────────────────────────────────────────────────── -->
      <div class="space-y-2 mb-4">

        <!-- Empty state -->
        <div v-if="!plan?.days?.length"
          class="border-2 border-dashed border-slate-200 rounded-xl p-10 text-center text-slate-400">
          <svg class="w-8 h-8 mx-auto mb-2 opacity-40" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          <p class="text-sm font-medium">Nenhum treino adicionado</p>
          <p class="text-xs mt-0.5">Use "+ Adicionar treino" abaixo para começar.</p>
        </div>

        <!-- Step cards -->
        <div v-for="(day, idx) in plan?.days" :key="day.id"
          class="bg-white border rounded-xl overflow-hidden transition-all duration-150"
          :class="[
            day.rest_day ? 'border-violet-100' : 'border-slate-200 shadow-sm',
            dayDragOverIdx === idx && dayDraggingIdx !== idx
              ? 'ring-2 ring-brand-400 ring-offset-1 border-transparent shadow-md'
              : '',
            dayDraggingIdx === idx ? 'opacity-50 cursor-grabbing' : '',
          ]"
          @dragover.prevent="onDayDragOver(idx)"
          @drop.prevent="onDayDrop(idx)">

          <!-- Card header -->
          <div class="flex items-center gap-2 px-4 py-3"
            :class="day.rest_day ? 'bg-violet-50/50' : ''">

            <!-- Drag handle for day -->
            <div draggable="true"
              @dragstart="onDayDragStart(idx, $event)"
              @dragend="onDayDragEnd"
              class="cursor-grab active:cursor-grabbing p-1 text-slate-300 hover:text-slate-500
                     transition-colors flex-shrink-0">
              <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 16 16">
                <circle cx="5.5" cy="3.5" r="1.5"/>
                <circle cx="5.5" cy="8" r="1.5"/>
                <circle cx="5.5" cy="12.5" r="1.5"/>
                <circle cx="10.5" cy="3.5" r="1.5"/>
                <circle cx="10.5" cy="8" r="1.5"/>
                <circle cx="10.5" cy="12.5" r="1.5"/>
              </svg>
            </div>

            <!-- Step icon / number -->
            <div v-if="day.rest_day" class="text-xl leading-none flex-shrink-0">🌙</div>
            <!-- Day-of-week selector (calendar-based) -->
            <select v-else
              :value="day.day_of_week"
              @change="changeDayOfWeek(day, Number($event.target.value))"
              title="Dia da semana"
              class="text-xs font-bold text-brand-600 bg-brand-50 rounded-full
                     px-2 py-1 border-0 cursor-pointer hover:bg-brand-100
                     focus:outline-none focus:ring-1 focus:ring-brand-400 flex-shrink-0">
              <option v-for="(lbl, i) in DOW_LABELS" :key="i" :value="i">{{ lbl }}</option>
            </select>

            <!-- Name -->
            <span class="flex-1 font-semibold text-sm text-slate-900">{{ day.name }}</span>

            <!-- Exercise count -->
            <span v-if="!day.rest_day" class="text-xs text-slate-400 flex-shrink-0">
              {{ localEx[day.id]?.length ?? 0 }} ex.
            </span>

            <!-- Saving indicator -->
            <svg v-if="savingDays[day.id]"
              class="animate-spin w-3.5 h-3.5 text-brand-400 flex-shrink-0"
              fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
            </svg>

            <!-- Delete -->
            <button @click.stop="askDeleteDay(day)"
              class="p-1 rounded text-slate-300 hover:text-red-400 hover:bg-red-50
                     transition-colors flex-shrink-0" title="Remover">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Training day body -->
          <template v-if="!day.rest_day">

            <!-- Exercise rows (draggable) -->
            <div v-if="localEx[day.id]?.length" class="divide-y divide-slate-50 border-t border-slate-100">
              <div v-for="(ex, exIdx) in localEx[day.id]" :key="exIdx"
                class="flex items-center gap-2 px-4 py-2.5 transition-all duration-100 group"
                :class="[
                  dayStates[day.id]?.exDragOverIdx === exIdx && dayStates[day.id]?.exDraggingIdx !== exIdx
                    ? 'bg-brand-50 ring-2 ring-inset ring-brand-200'
                    : 'hover:bg-slate-50/60',
                  dayStates[day.id]?.exDraggingIdx === exIdx ? 'opacity-40' : '',
                ]"
                @dragover.prevent="onExDragOver(day.id, exIdx)"
                @drop.prevent="onExDrop(day.id, exIdx)">

                <!-- Drag handle for exercise -->
                <div draggable="true"
                  @dragstart="onExDragStart(day.id, exIdx, $event)"
                  @dragend="onExDragEnd(day.id)"
                  class="cursor-grab active:cursor-grabbing flex-shrink-0 text-slate-200
                         hover:text-slate-400 transition-colors">
                  <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 16 16">
                    <circle cx="5.5" cy="3.5" r="1.3"/>
                    <circle cx="5.5" cy="8" r="1.3"/>
                    <circle cx="5.5" cy="12.5" r="1.3"/>
                    <circle cx="10.5" cy="3.5" r="1.3"/>
                    <circle cx="10.5" cy="8" r="1.3"/>
                    <circle cx="10.5" cy="12.5" r="1.3"/>
                  </svg>
                </div>

                <!-- Name + muscle -->
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-slate-800 truncate">{{ ex.name }}</p>
                  <p class="text-[11px] text-slate-400 leading-none mt-0.5">{{ ex.muscle_group }}</p>
                </div>

                <!-- Cardio fields -->
                <template v-if="ex.type === 'cardio'">
                  <input v-model.number="ex.duration_minutes" type="number" min="1"
                    @input="markDirty(day.id)"
                    class="w-12 px-1.5 py-1 text-xs text-center border border-slate-200 rounded-md
                           focus:outline-none focus:ring-1 focus:ring-brand-400"
                    title="Duração (min)" />
                  <span class="text-xs text-slate-400">min</span>
                  <input v-model.number="ex.distance_km" type="number" min="0" step="0.1"
                    @input="markDirty(day.id)"
                    class="w-12 px-1.5 py-1 text-xs text-center border border-slate-200 rounded-md
                           focus:outline-none focus:ring-1 focus:ring-brand-400"
                    title="Distância (km)" />
                  <span class="text-xs text-slate-400">km</span>
                </template>

                <!-- Strength fields -->
                <template v-else>
                  <input v-model.number="ex.sets" type="number" min="1" max="20"
                    @input="markDirty(day.id)"
                    class="w-9 px-1 py-1 text-xs text-center border border-slate-200 rounded-md
                           focus:outline-none focus:ring-1 focus:ring-brand-400" />
                  <span class="text-xs text-slate-300">×</span>
                  <input v-model="ex.reps" type="text"
                    @input="markDirty(day.id)"
                    class="w-12 px-1.5 py-1 text-xs text-center border border-slate-200 rounded-md
                           focus:outline-none focus:ring-1 focus:ring-brand-400"
                    placeholder="12" />
                  <input v-model.number="ex.rest_seconds" type="number" min="0"
                    @input="markDirty(day.id)"
                    class="w-12 px-1.5 py-1 text-xs text-center border border-slate-200 rounded-md
                           focus:outline-none focus:ring-1 focus:ring-brand-400"
                    title="Descanso (s)" />
                  <span class="text-xs text-slate-400">s</span>
                </template>

                <!-- Technique badge -->
                <span v-if="ex.technique && ex.technique !== 'normal'"
                  :class="techniqueClass(ex.technique)"
                  class="text-[10px] font-bold px-1.5 py-0.5 rounded flex-shrink-0">
                  {{ techniqueLabel(ex.technique) }}
                </span>

                <!-- Remove -->
                <button @click="removeExercise(day.id, exIdx)"
                  class="opacity-0 group-hover:opacity-100 p-0.5 rounded text-slate-300
                         hover:text-red-400 transition-all flex-shrink-0" title="Remover exercício">
                  <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            </div>

            <!-- Save error -->
            <p v-if="dayErrors[day.id]"
              class="px-4 py-2 text-xs text-red-500 bg-red-50 border-t border-red-100">
              {{ dayErrors[day.id] }}
            </p>

            <!-- Exercise search / add button -->
            <div class="border-t border-slate-100 px-4 py-3">

              <!-- Inline search (open) -->
              <div v-if="dayStates[day.id]?.searchOpen" class="relative">
                <div class="flex items-center gap-2">
                  <div class="relative flex-1">
                    <svg class="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400 pointer-events-none"
                      fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round"
                        d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                    </svg>
                    <input
                      :data-ex-search="day.id"
                      v-model="dayStates[day.id].searchQuery"
                      @input="searchExercisesForDay(day.id)"
                      @keydown.escape="closeExSearch(day.id)"
                      type="text"
                      placeholder="Buscar exercício…"
                      class="w-full pl-8 pr-3 py-1.5 text-sm border border-brand-300 rounded-lg bg-white
                             focus:outline-none focus:ring-2 focus:ring-brand-400 focus:border-transparent" />
                  </div>
                  <button @click="closeExSearch(day.id)"
                    class="text-xs text-slate-400 hover:text-slate-600 px-2 py-1.5 hover:bg-slate-100
                           rounded-md transition-colors">
                    Cancelar
                  </button>
                </div>

                <!-- Search results -->
                <div v-if="dayStates[day.id].searchResults.length"
                  class="mt-1.5 border border-slate-200 rounded-lg overflow-hidden bg-white shadow-sm">
                  <button v-for="result in dayStates[day.id].searchResults" :key="result.id"
                    @click="addExercise(day.id, result)"
                    class="w-full flex items-center justify-between px-3 py-2 text-sm text-left
                           hover:bg-brand-50 transition-colors border-b border-slate-50 last:border-0">
                    <span class="font-medium text-slate-800">{{ result.name }}</span>
                    <span class="text-xs text-slate-400 ml-2 flex-shrink-0">{{ result.muscle_group }}</span>
                  </button>
                </div>

                <p v-else-if="dayStates[day.id].searchQuery.length >= 2"
                  class="mt-1.5 text-xs text-slate-400 px-1">
                  Nenhum exercício encontrado.
                </p>
              </div>

              <!-- Add button + unsaved indicator (closed) -->
              <div v-else class="flex items-center justify-between">
                <button @click.stop="openExSearch(day.id)"
                  class="text-xs font-semibold text-brand-600 hover:text-brand-700
                         hover:bg-brand-50 px-2 py-1 rounded-md transition-colors -ml-2">
                  + Adicionar exercício
                </button>
                <div v-if="exDirty[day.id]" class="flex items-center gap-2">
                  <span class="text-[11px] text-amber-600">Não salvo</span>
                  <button @click="saveExercises(day.id)"
                    class="text-[11px] font-semibold text-brand-600 hover:underline">
                    Salvar agora
                  </button>
                </div>
              </div>

            </div>
          </template>

        </div>
      </div>

      <!-- ── Add step actions ────────────────────────────────────────────── -->
      <div class="relative mb-10" id="add-popover-anchor">

        <div class="flex items-center gap-2 flex-wrap">

          <!-- + Treino (opens popover) -->
          <button @click.stop="toggleAddPopover" :disabled="addingStep"
            class="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-semibold text-brand-600
                   border-2 border-dashed border-brand-200 rounded-xl hover:border-brand-400
                   hover:bg-brand-50 transition-colors disabled:opacity-50">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Treino
          </button>

          <!-- + Descanso (instant) -->
          <button @click.stop="addRestInstant" :disabled="addingStep"
            class="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-semibold text-slate-500
                   border-2 border-dashed border-slate-200 rounded-xl hover:border-violet-300
                   hover:bg-violet-50 hover:text-violet-700 transition-colors disabled:opacity-50">
            <span class="text-base leading-none">🌙</span>
            Descanso
          </button>

          <span v-if="addStepError" class="text-xs text-red-500">{{ addStepError }}</span>
        </div>

        <!-- Popover (workout options only) -->
        <Transition
          enter-active-class="transition duration-100 ease-out"
          enter-from-class="opacity-0 scale-95 translate-y-1"
          enter-to-class="opacity-100 scale-100 translate-y-0"
          leave-active-class="transition duration-75 ease-in"
          leave-from-class="opacity-100 scale-100 translate-y-0"
          leave-to-class="opacity-0 scale-95 translate-y-1">
          <div v-if="addPopoverOpen" @click.stop
            class="absolute bottom-full mb-2 left-0 bg-white border border-slate-200
                   rounded-xl shadow-xl z-20 overflow-hidden"
            style="min-width: 260px">

            <!-- Option picker -->
            <template v-if="addMode === null">
              <div class="p-1.5">
                <!-- Criar treino -->
                <button @click="openWorkoutModal"
                  class="w-full flex items-start gap-3 px-3 py-2.5 rounded-lg text-left
                         hover:bg-slate-50 transition-colors group">
                  <div class="w-7 h-7 rounded-lg bg-brand-100 flex items-center justify-center flex-shrink-0 mt-0.5
                              group-hover:bg-brand-200 transition-colors">
                    <svg class="w-3.5 h-3.5 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931z" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-slate-800">Criar treino</p>
                    <p class="text-xs text-slate-400 mt-0.5">Novo treino com exercícios</p>
                  </div>
                </button>

                <!-- Usar existente -->
                <button @click="startTemplateAdd"
                  class="w-full flex items-start gap-3 px-3 py-2.5 rounded-lg text-left
                         hover:bg-slate-50 transition-colors group">
                  <div class="w-7 h-7 rounded-lg bg-slate-100 flex items-center justify-center flex-shrink-0 mt-0.5
                              group-hover:bg-slate-200 transition-colors">
                    <svg class="w-3.5 h-3.5 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z" />
                    </svg>
                  </div>
                  <div>
                    <p class="text-sm font-semibold text-slate-800">Usar treino existente</p>
                    <p class="text-xs text-slate-400 mt-0.5">Copiar de um modelo da academia</p>
                  </div>
                </button>
              </div>
            </template>

            <!-- Template picker -->
            <template v-else-if="addMode === 'template'">
              <div class="p-3">
                <div class="flex items-center gap-2 mb-3">
                  <button @click="addMode = null"
                    class="p-1 rounded text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors">
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
                    </svg>
                  </button>
                  <p class="text-xs font-semibold text-slate-600">Usar treino existente</p>
                </div>
                <div v-if="tplLoading" class="py-6 text-center text-xs text-slate-400">Carregando…</div>
                <div v-else-if="!tplList.length" class="py-6 text-center text-xs text-slate-400">
                  Nenhum treino encontrado.
                </div>
                <div v-else class="max-h-48 overflow-y-auto space-y-0.5">
                  <button v-for="tpl in tplList" :key="tpl.id"
                    @click="addFromTemplate(tpl)" :disabled="addingStep"
                    class="w-full flex items-center justify-between px-2.5 py-2 rounded-lg text-left
                           hover:bg-brand-50 transition-colors disabled:opacity-50">
                    <span class="text-sm font-medium text-slate-800 truncate">{{ tpl.name }}</span>
                    <span class="text-xs text-slate-400 ml-2 flex-shrink-0">{{ tpl.exercises_count }} ex.</span>
                  </button>
                </div>
                <p v-if="addStepError" class="text-xs text-red-500 mt-1.5">{{ addStepError }}</p>
              </div>
            </template>

          </div>
        </Transition>
      </div>

      <!-- ── Assign to student ───────────────────────────────────────────── -->
      <div class="card flex flex-col gap-4 p-6 sm:flex-row sm:flex-wrap sm:items-center sm:justify-between">
        <div class="flex items-center gap-3">
          <div class="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-xl bg-brand-50 text-brand-600">
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 9.75a3.375 3.375 0 100-6.75 3.375 3.375 0 000 6.75z" />
            </svg>
          </div>
          <div>
            <h3 class="text-sm font-semibold text-slate-900">Atribuir plano</h3>
            <p class="mt-0.5 text-xs text-slate-500">Selecione um aluno da academia para receber este plano.</p>
          </div>
        </div>
        <button type="button" class="inline-flex items-center justify-center gap-2 rounded-lg bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-brand-700" @click="assignModalOpen = true">
          Selecionar aluno
          <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" /></svg>
        </button>
        <div v-if="assignSuccess" class="basis-full rounded-xl bg-emerald-50 px-3 py-2.5 text-xs font-medium text-emerald-700 sm:order-3">{{ assignSuccess }}</div>
      </div>

    </template>

    <!-- ── Delete confirmation modal ────────────────────────────────────── -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="deleteDayTarget" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="cancelDeleteDay" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-sm">
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Remover treino</h3>
            <p class="text-sm text-slate-500 text-center mb-5">
              Remover <strong class="text-slate-700">"{{ deleteDayTarget.name }}"</strong> do plano?
            </p>
            <p v-if="deleteDayError" class="text-xs text-red-500 text-center mb-3">{{ deleteDayError }}</p>
            <div class="flex items-center gap-3">
              <button @click="cancelDeleteDay" class="flex-1 btn-secondary">Cancelar</button>
              <button @click="confirmDeleteDay" :disabled="deletingDay"
                class="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 bg-red-600
                       text-white text-sm font-semibold rounded-lg hover:bg-red-700 transition-colors
                       disabled:opacity-60">
                {{ deletingDay ? 'Removendo…' : 'Sim, remover' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ── WorkoutModal (create workout + add to plan) ───────────────────── -->
    <WorkoutModal
      v-model="workoutModalOpen"
      :in-plan-context="true"
      @saved="onWorkoutModalSaved" />

    <PlanAssignModal
      v-model="assignModalOpen"
      :plan-id="planId"
      :plan-name="plan?.name"
      @assigned="onPlanAssigned" />

  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '../services/api.js'
import WorkoutModal from '../components/workouts/WorkoutModal.vue'
import PlanAssignModal from '../components/workout-plans/PlanAssignModal.vue'

const route  = useRoute()
const router = useRouter()
const planId = route.params.id

// ── Day-of-week helpers ────────────────────────────────────────────────────────
const DOW_LABELS = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
const dowLabel   = (dow) => (dow != null && dow >= 0 && dow <= 6) ? DOW_LABELS[dow] : '?'

/** day_of_week values already used by this plan (so we never duplicate). */
const usedDows = computed(() =>
  new Set((plan.value?.days ?? []).map(d => d.day_of_week).filter(d => d != null))
)

/** Returns the first unused day_of_week Mon→Sun, or null if all 7 are taken. */
function getNextAvailableDow() {
  for (const d of [1, 2, 3, 4, 5, 6, 0]) { // Mon first
    if (!usedDows.value.has(d)) return d
  }
  return null
}

// ── Plan ──────────────────────────────────────────────────────────────────────
const plan    = ref(null)
const loading = ref(true)
const error   = ref('')

// ── Local exercise state per day ──────────────────────────────────────────────
const localEx      = reactive({}) // dayId → exercise[]
const exDirty      = reactive({}) // dayId → bool
const savingDays   = reactive({}) // dayId → bool
const dayErrors    = reactive({}) // dayId → string
const exSaveTimers = {}

// ── Per-day UI state ──────────────────────────────────────────────────────────
// dayId → { searchOpen, searchQuery, searchResults, exDraggingIdx, exDragOverIdx }
const dayStates = reactive({})

// ── Add popover ───────────────────────────────────────────────────────────────
const addPopoverOpen = ref(false)
const addMode        = ref(null) // null | 'template'
const addingStep     = ref(false)
const addStepError   = ref('')
const tplList        = ref([])
const tplLoading     = ref(false)

// ── Plan day DnD ──────────────────────────────────────────────────────────────
const dayDraggingIdx = ref(null)
const dayDragOverIdx = ref(null)
const reordering     = ref(false)

// ── WorkoutModal (create from plan) ──────────────────────────────────────────
const workoutModalOpen = ref(false)

// ── Delete ────────────────────────────────────────────────────────────────────
const deleteDayTarget = ref(null)
const deletingDay     = ref(false)
const deleteDayError  = ref('')

// ── Assign ────────────────────────────────────────────────────────────────────
const assignModalOpen = ref(false)
const assignSuccess = ref('')

// ── Helpers ───────────────────────────────────────────────────────────────────
const techniqueLabel = t => ({ superset: 'SS', dropset: 'DS', circuit: 'CIR' }[t] ?? '')
const techniqueClass = t => ({
  superset: 'bg-purple-50 text-purple-700',
  dropset:  'bg-red-50 text-red-700',
  circuit:  'bg-teal-50 text-teal-700',
}[t] ?? '')

// ── Load ──────────────────────────────────────────────────────────────────────
async function loadPlan() {
  loading.value = true; error.value = ''
  try {
    const { data } = await api.get(`/admin/workout-plans/${planId}`)
    plan.value = data.plan
    for (const day of data.plan.days ?? []) {
      initLocalEx(day)
      initDayState(day.id)
    }
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Não foi possível carregar o plano.'
  } finally { loading.value = false }
}

function initLocalEx(day) {
  localEx[day.id] = (day.exercises ?? []).map(ex => ({
    name:             ex.name,
    muscle_group:     ex.muscle_group,
    type:             ex.type || 'strength',
    exercise_id:      ex.exercise_id,
    sets:             ex.sets,
    reps:             ex.reps,
    rest_seconds:     ex.rest_seconds,
    duration_minutes: ex.duration_minutes,
    distance_km:      ex.distance_km,
    technique:        ex.technique || 'normal',
    group_id:         ex.group_id,
    rounds:           ex.rounds,
    drops:            ex.drops,
  }))
  exDirty[day.id] = false
}

function initDayState(dayId) {
  if (!dayStates[dayId]) {
    dayStates[dayId] = {
      searchOpen:    false,
      searchQuery:   '',
      searchResults: [],
      exDraggingIdx: null,
      exDragOverIdx: null,
    }
  }
}

// ── Exercise editing ──────────────────────────────────────────────────────────
function markDirty(dayId) {
  exDirty[dayId] = true
  clearTimeout(exSaveTimers[dayId])
  exSaveTimers[dayId] = setTimeout(() => saveExercises(dayId), 900)
}

async function saveExercises(dayId) {
  clearTimeout(exSaveTimers[dayId])
  savingDays[dayId] = true
  dayErrors[dayId]  = ''
  try {
    const exercises = (localEx[dayId] ?? []).map((ex, i) => ({
      exercise_id:      ex.exercise_id,
      sets:             ex.type === 'cardio' ? null : (ex.sets || null),
      reps:             ex.type === 'cardio' ? null : (ex.reps || null),
      rest_seconds:     ex.type === 'cardio' ? 0 : (ex.rest_seconds ?? 60),
      exercise_order:   i + 1,
      duration_minutes: ex.type === 'cardio' ? (ex.duration_minutes || null) : null,
      distance_km:      ex.type === 'cardio' ? (ex.distance_km || null) : null,
      technique:        ex.technique || 'normal',
      group_id:         ex.group_id || null,
      rounds:           ex.rounds || null,
      drops:            ex.drops || null,
    }))
    await api.put(`/admin/workout-plans/${planId}/days/${dayId}`, { exercises })
    exDirty[dayId] = false
  } catch (e) {
    dayErrors[dayId] = e.response?.data?.message ?? 'Erro ao salvar exercícios.'
  } finally { savingDays[dayId] = false }
}

function removeExercise(dayId, idx) {
  localEx[dayId].splice(idx, 1)
  saveExercises(dayId)
}

// ── Exercise search ───────────────────────────────────────────────────────────
function openExSearch(dayId) {
  initDayState(dayId)
  dayStates[dayId].searchOpen    = true
  dayStates[dayId].searchQuery   = ''
  dayStates[dayId].searchResults = []
  nextTick(() => {
    const el = document.querySelector(`[data-ex-search="${dayId}"]`)
    if (el) el.focus()
  })
}

function closeExSearch(dayId) {
  if (dayStates[dayId]) {
    dayStates[dayId].searchOpen    = false
    dayStates[dayId].searchQuery   = ''
    dayStates[dayId].searchResults = []
  }
}

const exSearchTimers = {}
function searchExercisesForDay(dayId) {
  const q = dayStates[dayId]?.searchQuery?.trim()
  if (!q || q.length < 2) { if (dayStates[dayId]) dayStates[dayId].searchResults = []; return }
  clearTimeout(exSearchTimers[dayId])
  exSearchTimers[dayId] = setTimeout(async () => {
    try {
      const { data } = await api.get('/admin/exercises', { params: { search: q } })
      if (dayStates[dayId]) dayStates[dayId].searchResults = (data.exercises ?? []).slice(0, 8)
    } catch { if (dayStates[dayId]) dayStates[dayId].searchResults = [] }
  }, 250)
}

function addExercise(dayId, ex) {
  if (!localEx[dayId]) localEx[dayId] = []
  const isCardio = ex.type === 'cardio'
  localEx[dayId].push({
    name:             ex.name,
    muscle_group:     ex.muscle_group,
    type:             ex.type || 'strength',
    exercise_id:      ex.id,
    sets:             isCardio ? null : 3,
    reps:             isCardio ? null : '12',
    rest_seconds:     isCardio ? 0 : (ex.default_rest ?? 60),
    duration_minutes: isCardio ? 15 : null,
    distance_km:      null,
    technique:        'normal',
    group_id:         null,
    rounds:           null,
    drops:            null,
  })
  closeExSearch(dayId)
  saveExercises(dayId)
}

// ── Exercise DnD (within a day) ───────────────────────────────────────────────
function onExDragStart(dayId, idx, event) {
  initDayState(dayId)
  dayStates[dayId].exDraggingIdx = idx
  event.dataTransfer.effectAllowed = 'move'
}
function onExDragEnd(dayId) {
  if (dayStates[dayId]) {
    dayStates[dayId].exDraggingIdx = null
    dayStates[dayId].exDragOverIdx = null
  }
}
function onExDragOver(dayId, idx) {
  initDayState(dayId)
  dayStates[dayId].exDragOverIdx = idx
}
function onExDrop(dayId, idx) {
  const state = dayStates[dayId]
  if (!state || state.exDraggingIdx === null || state.exDraggingIdx === idx) {
    if (state) { state.exDraggingIdx = null; state.exDragOverIdx = null }
    return
  }
  const arr = [...localEx[dayId]]
  const [moved] = arr.splice(state.exDraggingIdx, 1)
  arr.splice(idx, 0, moved)
  localEx[dayId] = arr
  state.exDraggingIdx = null
  state.exDragOverIdx = null
  saveExercises(dayId)
}

// ── Plan day DnD ──────────────────────────────────────────────────────────────
function onDayDragStart(idx, event) {
  dayDraggingIdx.value = idx
  event.dataTransfer.effectAllowed = 'move'
}
function onDayDragEnd() {
  dayDraggingIdx.value = null
  dayDragOverIdx.value = null
}
function onDayDragOver(idx) {
  dayDragOverIdx.value = idx
}
function onDayDrop(idx) {
  if (dayDraggingIdx.value === null || dayDraggingIdx.value === idx) {
    dayDraggingIdx.value = null
    dayDragOverIdx.value = null
    return
  }
  // Swap day_of_week between the two dragged days (calendar semantics)
  const days    = [...plan.value.days]
  const fromDay = days[dayDraggingIdx.value]
  const toDay   = days[idx]
  const fromDow = fromDay.day_of_week
  fromDay.day_of_week = toDay.day_of_week
  toDay.day_of_week   = fromDow

  plan.value.days      = days
  dayDraggingIdx.value = null
  dayDragOverIdx.value = null
  persistDayReorder(days)
}

async function persistDayReorder(days) {
  reordering.value = true
  try {
    await api.patch(`/admin/workout-plans/${planId}/days/reassign`, {
      days: days.map(d => ({ id: d.id, day_of_week: d.day_of_week })),
    })
  } catch { await loadPlan() }
  finally { reordering.value = false }
}

// ── Add step (popover) ────────────────────────────────────────────────────────
function toggleAddPopover() {
  addPopoverOpen.value = !addPopoverOpen.value
  if (addPopoverOpen.value) {
    addMode.value      = null
    addStepError.value = ''
  }
}

function closeAddPopover() {
  addPopoverOpen.value = false
  addMode.value        = null
}

function openWorkoutModal() {
  closeAddPopover()
  workoutModalOpen.value = true
}

async function onWorkoutModalSaved(workout) {
  addStepError.value = ''
  addingStep.value   = true
  const dow = getNextAvailableDow()
  if (dow === null) {
    addStepError.value = 'Todos os 7 dias já estão configurados no plano.'
    addingStep.value   = false
    return
  }
  try {
    await api.post(`/admin/workout-plans/${planId}/days/from-template`, {
      workout_id:  workout.id,
      day_of_week: dow,
    })
    await loadPlan()
  } catch (e) {
    addStepError.value = e.response?.data?.message ?? 'Erro ao adicionar treino ao plano.'
  } finally { addingStep.value = false }
}

async function addRestInstant() {
  const dow = getNextAvailableDow()
  if (dow === null) {
    addStepError.value = 'Todos os 7 dias já estão configurados no plano.'
    return
  }
  addingStep.value = true
  try {
    await api.post(`/admin/workout-plans/${planId}/days`, {
      name:        'Descanso',
      rest_day:    true,
      day_of_week: dow,
    })
    await loadPlan()
    closeAddPopover()
  } catch (e) {
    addStepError.value = e.response?.data?.message ?? 'Erro ao adicionar descanso.'
  } finally { addingStep.value = false }
}

async function startTemplateAdd() {
  addMode.value = 'template'
  if (tplList.value.length) return
  tplLoading.value = true
  try {
    const { data } = await api.get('/admin/workouts')
    tplList.value = (data.workouts ?? []).map(w => ({
      id:              w.id,
      name:            w.name,
      exercises_count: w.exercises_count ?? 0,
    }))
  } catch { tplList.value = [] }
  finally { tplLoading.value = false }
}

async function addFromTemplate(tpl) {
  addingStep.value = true; addStepError.value = ''
  const dow = getNextAvailableDow()
  if (dow === null) {
    addStepError.value = 'Todos os 7 dias já estão configurados no plano.'
    addingStep.value   = false
    return
  }
  try {
    await api.post(`/admin/workout-plans/${planId}/days/from-template`, {
      workout_id:  tpl.id,
      day_of_week: dow,
    })
    await loadPlan()
    closeAddPopover()
  } catch (e) {
    addStepError.value = e.response?.data?.message ?? 'Erro ao usar treino.'
  } finally { addingStep.value = false }
}

// ── Delete ────────────────────────────────────────────────────────────────────
function askDeleteDay(day)  { deleteDayError.value = ''; deleteDayTarget.value = day }
function cancelDeleteDay()  { if (!deletingDay.value) deleteDayTarget.value = null }

async function confirmDeleteDay() {
  if (!deleteDayTarget.value) return
  deletingDay.value = true; deleteDayError.value = ''
  try {
    await api.delete(`/admin/workout-plans/${planId}/days/${deleteDayTarget.value.id}`)
    await loadPlan()
    deleteDayTarget.value = null
  } catch (e) {
    deleteDayError.value = e.response?.data?.message ?? 'Erro ao remover treino.'
  } finally { deletingDay.value = false }
}

// ── Assign ────────────────────────────────────────────────────────────────────
function onPlanAssigned({ user, pending }) {
  assignSuccess.value = pending
    ? `Plano agendado para ${user.name}. Entrará em vigor na próxima semana.`
    : `Plano atribuído a ${user.name} com sucesso.`
}

// ── Change day_of_week inline ─────────────────────────────────────────────────
async function changeDayOfWeek(day, newDow) {
  if (day.day_of_week === newDow) return
  const conflict = (plan.value?.days ?? []).some(d => d.id !== day.id && d.day_of_week === newDow)
  if (conflict) {
    dayErrors[day.id] = `Já existe um treino para ${dowLabel(newDow)}.`
    return
  }
  try {
    await api.put(`/admin/workout-plans/${planId}/days/${day.id}`, { day_of_week: newDow })
    day.day_of_week = newDow
    dayErrors[day.id] = ''
  } catch (e) {
    dayErrors[day.id] = e.response?.data?.message ?? 'Erro ao alterar dia.'
  }
}

// ── Outside click: close popover ──────────────────────────────────────────────
function handlePageClick() {
  if (addPopoverOpen.value) closeAddPopover()
}

onMounted(loadPlan)
onUnmounted(() => { Object.values(exSaveTimers).forEach(clearTimeout) })
</script>
