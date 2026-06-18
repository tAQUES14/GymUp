<template>
  <div>

    <!-- Loading skeleton -->
    <div v-if="loading" class="space-y-4 animate-pulse">
      <div class="h-4 w-28 bg-slate-100 rounded" />
      <div class="card px-6 py-5">
        <div class="flex items-start gap-4">
          <div class="w-12 h-12 bg-slate-100 rounded-xl flex-shrink-0" />
          <div class="flex-1 space-y-2">
            <div class="h-6 w-64 bg-slate-100 rounded" />
            <div class="h-4 w-40 bg-slate-100 rounded" />
            <div class="flex gap-2 mt-3">
              <div class="h-6 w-20 bg-slate-100 rounded-full" />
              <div class="h-6 w-24 bg-slate-100 rounded-full" />
              <div class="h-6 w-28 bg-slate-100 rounded-full" />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Error -->
    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar desafio</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadChallenge" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <template v-else-if="challenge">

      <!-- Breadcrumb -->
      <button @click="$router.push('/challenges')"
        class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors mb-5">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18" />
        </svg>
        Desafios
      </button>

      <!-- ── STATUS BANNER ─────────────────────────────────────────── -->
      <!-- ATIVO -->
      <div v-if="statusKey === 'active'"
        class="rounded-xl border border-emerald-200 bg-emerald-50 px-5 py-3.5 mb-5 flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <span class="flex h-3 w-3 flex-shrink-0">
            <span class="animate-ping absolute inline-flex h-3 w-3 rounded-full bg-emerald-400 opacity-75" />
            <span class="relative inline-flex rounded-full h-3 w-3 bg-emerald-500" />
          </span>
          <div>
            <p class="text-sm font-bold text-emerald-800">Desafio em andamento</p>
            <p class="text-xs text-emerald-600 mt-0.5">{{ daysRemaining }} · {{ formatDate(challenge.starts_at) }} até {{ formatDate(challenge.ends_at) }}</p>
          </div>
        </div>
        <!-- Progress bar -->
        <div class="hidden sm:block flex-1 max-w-[180px]">
          <div class="flex justify-between text-[10px] text-emerald-600 mb-1">
            <span>{{ progressPct }}% concluído</span>
          </div>
          <div class="h-1.5 bg-emerald-200 rounded-full overflow-hidden">
            <div class="h-full bg-emerald-500 rounded-full transition-all" :style="{ width: progressPct + '%' }" />
          </div>
        </div>
      </div>

      <!-- AGENDADO -->
      <div v-else-if="statusKey === 'scheduled'"
        class="rounded-xl border border-blue-200 bg-blue-50 px-5 py-3.5 mb-5 flex items-center gap-3">
        <svg class="w-4 h-4 text-blue-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 9v7.5" />
        </svg>
        <div>
          <p class="text-sm font-bold text-blue-800">Desafio agendado</p>
          <p class="text-xs text-blue-600 mt-0.5">Inicia em {{ daysUntilStart }} · {{ formatDate(challenge.starts_at) }}</p>
        </div>
      </div>

      <!-- FINALIZADO / ENCERRADO -->
      <div v-else
        class="rounded-xl border border-slate-200 bg-slate-50 px-5 py-3.5 mb-5 flex items-center gap-3">
        <svg class="w-4 h-4 text-slate-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div>
          <p class="text-sm font-bold text-slate-600">Desafio encerrado</p>
          <p class="text-xs text-slate-400 mt-0.5">
            {{ formatDate(challenge.starts_at) }} até {{ formatDate(challenge.ends_at) }}
            · {{ challenge.participants_count ?? 0 }} participante{{ (challenge.participants_count ?? 0) !== 1 ? 's' : '' }}
          </p>
        </div>
      </div>

      <!-- ── HEADER CARD ────────────────────────────────────────────── -->
      <div class="card px-6 py-5 mb-6">
        <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
          <div class="flex items-start gap-4">
            <!-- Icon -->
            <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0"
                 :class="challenge.type === 'competitive' ? 'bg-violet-100' : 'bg-amber-100'">
              <svg v-if="challenge.type === 'competitive'" class="w-6 h-6 text-violet-600"
                   fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 18.75h-9m9 0a3 3 0 013 3h-15a3 3 0 013-3m9 0v-3.375c0-.621-.503-1.125-1.125-1.125h-.871M7.5 18.75v-3.375c0-.621.504-1.125 1.125-1.125h.872m5.007 0H9.497m5.007 0a7.454 7.454 0 01-.982-3.172M9.497 14.25a7.454 7.454 0 00.981-3.172M5.25 4.236c-.982.143-1.954.317-2.916.52A6.003 6.003 0 007.73 9.728M5.25 4.236V4.5c0 2.108.966 3.99 2.48 5.228M5.25 4.236V2.721C7.456 2.41 9.71 2.25 12 2.25c2.291 0 4.545.16 6.75.47v1.516M7.73 9.728a6.726 6.726 0 002.748 1.35m8.272-6.842V4.5c0 2.108-.966 3.99-2.48 5.228m2.48-5.492a46.32 46.32 0 012.916.52 6.003 6.003 0 01-5.395 4.972m0 0a6.726 6.726 0 01-2.749 1.35m0 0a6.772 6.772 0 01-3.044 0" />
              </svg>
              <svg v-else class="w-6 h-6 text-amber-600"
                   fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
              </svg>
            </div>

            <div>
              <h1 class="text-xl font-bold text-slate-900 mb-1">{{ challenge.name }}</h1>
              <p v-if="challenge.description" class="text-sm text-slate-500 mb-3">{{ challenge.description }}</p>
              <div class="flex flex-wrap items-center gap-2">
                <span class="chip"
                      :class="challenge.type === 'competitive' ? 'bg-violet-50 text-violet-700' : 'bg-amber-50 text-amber-700'">
                  {{ challenge.type === 'competitive' ? 'Competitivo' : 'Simples' }}
                </span>
                <span class="chip bg-slate-100 text-slate-600">
                  {{ durationDays }} dias
                </span>
                <span class="chip bg-brand-50 text-brand-700">
                  {{ challenge.participants_count ?? 0 }} participante{{ (challenge.participants_count ?? 0) !== 1 ? 's' : '' }}
                </span>
                <span v-if="challenge.reward_type && challenge.reward_type !== 'none'" class="chip bg-amber-50 text-amber-700">
                  {{ rewardTypeLabel }}
                </span>
              </div>
            </div>
          </div>

          <!-- Action buttons -->
          <div class="flex items-center gap-2 flex-shrink-0">
            <button v-if="canEdit" @click="editModalOpen = true"
              class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-semibold text-slate-600
                     border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
              </svg>
              Editar
            </button>
            <button v-if="statusKey === 'active'" @click="finishConfirm = true"
              class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-semibold text-amber-700
                     border border-amber-200 bg-amber-50 rounded-lg hover:bg-amber-100 transition-colors">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M5.25 7.5A2.25 2.25 0 017.5 5.25h9a2.25 2.25 0 012.25 2.25v9a2.25 2.25 0 01-2.25 2.25h-9a2.25 2.25 0 01-2.25-2.25v-9z" />
              </svg>
              Encerrar
            </button>
            <button v-if="canDelete" @click="deleteConfirm = true"
              class="inline-flex items-center gap-1.5 px-3.5 py-2 text-sm font-semibold text-red-600
                     border border-red-200 rounded-lg hover:bg-red-50 transition-colors">
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
              </svg>
              Excluir
            </button>
          </div>
        </div>
      </div>

      <!-- ── TABS ──────────────────────────────────────────────────── -->
      <div class="flex items-center gap-1 mb-5 border-b border-slate-200">
        <button v-for="tab in tabs" :key="tab.key"
          @click="activeTab = tab.key"
          class="px-4 py-2.5 text-sm font-semibold transition-colors relative"
          :class="activeTab === tab.key ? 'text-brand-600' : 'text-slate-500 hover:text-slate-700'"
        >
          {{ tab.label }}
          <span v-if="tab.count !== undefined"
            class="ml-1.5 inline-flex items-center justify-center min-w-[1.25rem] h-5 px-1 rounded-full text-[11px]"
            :class="activeTab === tab.key ? 'bg-brand-100 text-brand-700' : 'bg-slate-100 text-slate-500'">
            {{ tab.count }}
          </span>
          <span v-if="activeTab === tab.key"
            class="absolute bottom-0 left-0 right-0 h-0.5 bg-brand-600 rounded-t-full" />
        </button>
      </div>

      <!-- TAB: Configuração -->
      <template v-if="activeTab === 'config'">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">

          <!-- Período -->
          <div class="card px-5 py-4">
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3">Período</p>
            <div class="space-y-3">
              <div class="flex items-center justify-between">
                <span class="text-sm text-slate-500">Início</span>
                <span class="text-sm font-semibold text-slate-800">{{ formatDate(challenge.starts_at) }}</span>
              </div>
              <div class="flex items-center justify-between">
                <span class="text-sm text-slate-500">Término</span>
                <span class="text-sm font-semibold text-slate-800">{{ formatDate(challenge.ends_at) }}</span>
              </div>
              <div class="flex items-center justify-between border-t border-slate-100 pt-2">
                <span class="text-sm text-slate-500">Duração</span>
                <span class="text-sm font-bold text-slate-900">{{ durationDays }} dias</span>
              </div>
            </div>
          </div>

          <!-- Recompensa -->
          <div class="card px-5 py-4">
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3">Recompensa</p>
            <div class="space-y-3">
              <div class="flex items-center justify-between">
                <span class="text-sm text-slate-500">Tipo</span>
                <span class="text-sm font-semibold text-slate-800">{{ rewardTypeLabel }}</span>
              </div>
              <div v-if="challenge.reward_description" class="flex items-start justify-between gap-4">
                <span class="text-sm text-slate-500 flex-shrink-0">Descrição</span>
                <span class="text-sm font-semibold text-slate-800 text-right">{{ challenge.reward_description }}</span>
              </div>
            </div>
          </div>

          <!-- Competitivo config -->
          <div v-if="challenge.type === 'competitive'" class="card px-5 py-4 md:col-span-2">
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-4">Configuração Competitiva</p>
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-6 mb-5">
              <div>
                <p class="text-xs text-slate-400 mb-1">Mín. treinos/semana</p>
                <p class="text-2xl font-bold text-slate-900">{{ challenge.min_weekly_workouts ?? '—' }}</p>
              </div>
              <div>
                <p class="text-xs text-slate-400 mb-1">Máx. treinos/semana</p>
                <p class="text-2xl font-bold text-slate-900">{{ challenge.max_weekly_workouts ?? '—' }}</p>
              </div>
            </div>
            <div v-if="challenge.weekly_points_config?.length">
              <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3">Pontos por posição semanal</p>
              <div class="flex flex-wrap gap-2">
                <div v-for="(pts, i) in challenge.weekly_points_config" :key="i"
                  class="flex items-center gap-2 px-3 py-2 rounded-lg border"
                  :class="i === 0 ? 'bg-yellow-50 border-yellow-200' : i === 1 ? 'bg-slate-50 border-slate-200' : i === 2 ? 'bg-amber-50 border-amber-200' : 'bg-white border-slate-100'">
                  <span class="text-xs font-bold"
                        :class="i === 0 ? 'text-yellow-600' : i === 1 ? 'text-slate-500' : i === 2 ? 'text-amber-600' : 'text-slate-400'">
                    {{ ordinal(i + 1) }}
                  </span>
                  <span class="text-sm font-bold text-slate-800">{{ pts }} pts</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Simples config -->
          <div v-if="challenge.type === 'simple'" class="card px-5 py-4">
            <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-4">Meta</p>
            <div class="space-y-3">
              <div class="flex items-center justify-between">
                <span class="text-sm text-slate-500">Treinos para completar</span>
                <span class="text-2xl font-bold text-slate-900">{{ challenge.goal_workouts ?? '—' }}</span>
              </div>
              <div v-if="challenge.reward_points" class="flex items-center justify-between border-t border-slate-100 pt-2">
                <span class="text-sm text-slate-500">Pontos de recompensa</span>
                <span class="text-xl font-bold text-amber-600">+{{ challenge.reward_points }}</span>
              </div>
            </div>
          </div>

        </div>
      </template>

      <!-- TAB: Participantes -->
      <template v-if="activeTab === 'participants'">
        <div class="card overflow-hidden">
          <table class="w-full text-left">
            <thead>
              <tr class="border-b border-slate-100 bg-slate-50/60">
                <th v-if="challenge.type === 'competitive'"
                  class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide w-12">#</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">Aluno</th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right hidden sm:table-cell">
                  Treinos
                </th>
                <th class="px-5 py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right">
                  {{ challenge.type === 'competitive' ? 'Pontos' : 'Meta' }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="participants.length === 0">
                <td :colspan="challenge.type === 'competitive' ? 4 : 3" class="px-5 py-16 text-center">
                  <div class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-slate-100 mb-3">
                    <svg class="w-5 h-5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" />
                    </svg>
                  </div>
                  <p class="text-sm font-semibold text-slate-600 mb-1">Nenhum participante ainda</p>
                  <p class="text-xs text-slate-400">Os alunos são inscritos automaticamente ao realizar o primeiro treino do desafio.</p>
                </td>
              </tr>

              <tr v-for="(p, i) in participants" :key="p.id"
                class="border-b border-slate-100 hover:bg-slate-50/60 transition-colors">

                <!-- Ranking position (competitive) -->
                <td v-if="challenge.type === 'competitive'" class="px-5 py-3.5">
                  <span class="inline-flex items-center justify-center w-7 h-7 rounded-full text-xs font-bold"
                        :class="rankClass(i)">
                    {{ i + 1 }}
                  </span>
                </td>

                <!-- Aluno -->
                <td class="px-5 py-3.5">
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0 overflow-hidden"
                         :style="{ backgroundColor: avatarColor(p.name) }">
                      <img v-if="participantAvatar(p)" :src="participantAvatar(p)" :alt="p.name" class="w-full h-full object-cover" @error="onParticipantAvatarError(p)" />
                      <template v-else>{{ initials(p.name) }}</template>
                    </div>
                    <div class="min-w-0">
                      <p class="text-sm font-semibold text-slate-800 truncate">{{ p.name }}</p>
                      <p class="text-[11px] text-slate-400 truncate">{{ p.email }}</p>
                    </div>
                  </div>
                </td>

                <!-- Treinos realizados -->
                <td class="px-5 py-3.5 text-right hidden sm:table-cell">
                  <span class="text-sm font-semibold text-slate-700">{{ p.workouts_this_challenge }}</span>
                  <span class="text-xs text-slate-400 ml-1">treino{{ p.workouts_this_challenge !== 1 ? 's' : '' }}</span>
                </td>

                <!-- Pontos (competitive) | Status meta (simple) -->
                <td class="px-5 py-3.5 text-right">
                  <template v-if="challenge.type === 'competitive'">
                    <span class="text-sm font-bold text-violet-700">{{ p.total_challenge_points }}</span>
                    <span class="text-xs text-slate-400 ml-1">pts</span>
                  </template>
                  <template v-else>
                    <span v-if="p.goal_completed"
                      class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700">
                      <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                      </svg>
                      Concluída
                    </span>
                    <span v-else class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold bg-slate-100 text-slate-500">
                      Em andamento
                    </span>
                  </template>
                </td>

              </tr>
            </tbody>
          </table>
        </div>
      </template>

    </template>

    <!-- Edit Modal -->
    <ChallengeModal v-model="editModalOpen" :challenge-to-edit="challenge" @saved="loadChallenge" />

    <!-- Finish confirmation -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="finishConfirm" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="finishConfirm = false" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-sm">
            <div class="flex items-center justify-center w-12 h-12 rounded-full bg-amber-50 mx-auto mb-4">
              <svg class="w-6 h-6 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
              </svg>
            </div>
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Encerrar desafio</h3>
            <p class="text-sm text-slate-500 text-center mb-5">
              Esta ação encerrará o desafio imediatamente para todos os participantes e não pode ser desfeita.
            </p>
            <p v-if="finishError" class="text-xs text-red-500 text-center mb-3">{{ finishError }}</p>
            <div class="flex items-center gap-3">
              <button @click="finishConfirm = false" class="flex-1 btn-secondary">Cancelar</button>
              <button @click="confirmFinish" :disabled="finishing"
                class="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 bg-amber-600
                       text-white text-sm font-semibold rounded-lg hover:bg-amber-700 transition-colors
                       disabled:opacity-60 disabled:cursor-not-allowed">
                <svg v-if="finishing" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                </svg>
                {{ finishing ? 'Encerrando…' : 'Sim, encerrar' }}
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- Delete confirmation (detail page) -->
    <Teleport to="body">
      <Transition enter-active-class="transition duration-150" enter-from-class="opacity-0"
        enter-to-class="opacity-100" leave-active-class="transition duration-100"
        leave-from-class="opacity-100" leave-to-class="opacity-0">
        <div v-if="deleteConfirm" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
          <div class="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" @click="deleteConfirm = false" />
          <div class="relative z-10 bg-white rounded-2xl shadow-2xl p-6 w-full max-w-sm">
            <div class="flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mx-auto mb-4">
              <svg class="w-6 h-6 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
              </svg>
            </div>
            <h3 class="text-base font-semibold text-slate-900 text-center mb-1">Excluir desafio</h3>
            <p class="text-sm text-slate-500 text-center mb-5">
              Tem certeza que deseja excluir
              <strong class="text-slate-700">"{{ challenge?.name }}"</strong>?
            </p>
            <p v-if="deleteError" class="text-xs text-red-500 text-center mb-3">{{ deleteError }}</p>
            <div class="flex items-center gap-3">
              <button @click="deleteConfirm = false" class="flex-1 btn-secondary">Cancelar</button>
              <button @click="confirmDelete" :disabled="deleting"
                class="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2 bg-red-600
                       text-white text-sm font-semibold rounded-lg hover:bg-red-700 transition-colors
                       disabled:opacity-60 disabled:cursor-not-allowed">
                <svg v-if="deleting" class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
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
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '../services/api.js'
import ChallengeModal from '../components/challenges/ChallengeModal.vue'

const route        = useRoute()
const router       = useRouter()
const challenge    = ref(null)
const participants = ref([])
const avatarFailures = ref(new Set())
const loading      = ref(true)
const error        = ref('')
const activeTab    = ref('config')

const editModalOpen = ref(false)
const finishConfirm = ref(false)
const finishing     = ref(false)
const finishError   = ref('')

const deleteConfirm = ref(false)
const deleting      = ref(false)
const deleteError   = ref('')

// ── Status ────────────────────────────────────────────────────────
const statusKey = computed(() => {
  if (!challenge.value) return ''
  if (challenge.value.status === 'finished') return 'finished'
  const now   = new Date()
  const start = new Date(challenge.value.starts_at)
  const end   = new Date(challenge.value.ends_at)
  if (now < start) return 'scheduled'
  if (now > end)   return 'expired'
  return 'active'
})

const canEdit   = computed(() => challenge.value && new Date(challenge.value.starts_at) > new Date())
const canDelete = computed(() => challenge.value && new Date(challenge.value.starts_at) > new Date())

// ── Progress ──────────────────────────────────────────────────────
const progressPct = computed(() => {
  if (!challenge.value) return 0
  const start = new Date(challenge.value.starts_at).getTime()
  const end   = new Date(challenge.value.ends_at).getTime()
  const now   = Date.now()
  return Math.min(100, Math.max(0, Math.round((now - start) / (end - start) * 100)))
})

const daysRemaining = computed(() => {
  if (!challenge.value) return ''
  const end  = new Date(challenge.value.ends_at)
  const days = Math.ceil((end - new Date()) / 864e5)
  if (days <= 0) return 'Último dia'
  return `${days} dia${days !== 1 ? 's' : ''} restante${days !== 1 ? 's' : ''}`
})

const daysUntilStart = computed(() => {
  if (!challenge.value) return ''
  const start = new Date(challenge.value.starts_at)
  const days  = Math.ceil((start - new Date()) / 864e5)
  return `${days} dia${days !== 1 ? 's' : ''}`
})

const durationDays = computed(() => {
  if (!challenge.value) return 0
  const start = new Date(challenge.value.starts_at)
  const end   = new Date(challenge.value.ends_at)
  return Math.round((end - start) / 864e5)
})

const rewardTypeLabel = computed(() => {
  const map = { points: 'Pontos', physical: 'Prêmio físico', none: 'Nenhuma' }
  return map[challenge.value?.reward_type] ?? '—'
})

const tabs = computed(() => [
  { key: 'config',       label: 'Configuração' },
  { key: 'participants', label: 'Participantes', count: challenge.value?.participants_count ?? 0 },
])

// ── Data ──────────────────────────────────────────────────────────
async function loadChallenge() {
  loading.value = true; error.value = ''
  try {
    const { data } = await api.get(`/admin/challenges/${route.params.id}`)
    challenge.value    = data.challenge
    participants.value = data.participants ?? []
  } catch {
    error.value = 'Não foi possível carregar o desafio.'
  } finally { loading.value = false }
}

async function confirmFinish() {
  finishing.value = true; finishError.value = ''
  try {
    await api.post(`/admin/challenges/${challenge.value.id}/finish`)
    finishConfirm.value = false
    loadChallenge()
  } catch (e) {
    finishError.value = e.response?.data?.message ?? 'Erro ao encerrar desafio.'
  } finally { finishing.value = false }
}

async function confirmDelete() {
  deleting.value = true; deleteError.value = ''
  try {
    await api.delete(`/admin/challenges/${challenge.value.id}`)
    router.push('/challenges')
  } catch (e) {
    deleteError.value = e.response?.data?.message ?? 'Erro ao excluir desafio.'
  } finally { deleting.value = false }
}

// ── Helpers ───────────────────────────────────────────────────────
function formatDate(iso) {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' })
}

function ordinal(n) { return `${n}º` }

function rankClass(i) {
  if (i === 0) return 'bg-yellow-100 text-yellow-700 ring-1 ring-yellow-300'
  if (i === 1) return 'bg-slate-200 text-slate-600'
  if (i === 2) return 'bg-amber-100 text-amber-700'
  return 'bg-slate-100 text-slate-500'
}

function initials(name) {
  return (name ?? '?').split(' ').slice(0, 2).map((w) => w[0]).join('').toUpperCase()
}
function avatarColor(name) {
  const colors = ['#6366f1', '#8b5cf6', '#ec4899', '#f59e0b', '#10b981', '#3b82f6', '#ef4444', '#14b8a6']
  let h = 0
  for (const c of (name ?? '')) h = (h * 31 + c.charCodeAt(0)) & 0xffffffff
  return colors[Math.abs(h) % colors.length]
}

function participantAvatar(participant) {
  if (!participant?.avatar_url || avatarFailures.value.has(participant.user_id)) return ''
  return participant.avatar_url
}

function onParticipantAvatarError(participant) {
  avatarFailures.value = new Set([...avatarFailures.value, participant.user_id])
}

onMounted(loadChallenge)
</script>

<style scoped>
.chip {
  @apply inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold;
}
</style>
