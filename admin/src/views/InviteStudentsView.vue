<template>
  <div>

    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Convidar Alunos</h1>
      <p class="text-slate-500 text-sm mt-1">Compartilhe o link ou código da sua academia para novos alunos se cadastrarem.</p>
    </div>

    <!-- Loading -->
    <template v-if="loading">
      <div class="space-y-4">
        <div v-for="n in 2" :key="n" class="card p-6 animate-pulse">
          <div class="h-4 bg-slate-100 rounded w-32 mb-4" />
          <div class="h-12 bg-slate-100 rounded mb-4" />
          <div class="flex gap-2">
            <div class="h-9 bg-slate-100 rounded w-28" />
            <div class="h-9 bg-slate-100 rounded w-36" />
          </div>
        </div>
      </div>
    </template>

    <!-- Error -->
    <div v-else-if="error" class="card p-8 text-center">
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar</p>
      <p class="text-xs text-slate-400 mb-4">{{ error }}</p>
      <button @click="loadData" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Content -->
    <template v-else-if="gym">
      <div class="space-y-5 max-w-2xl">

        <!-- ── Card: Link de convite ─────────────────────────────────────── -->
        <div class="card p-6">
          <div class="flex items-center gap-3 mb-5">
            <div class="w-8 h-8 rounded-lg bg-brand-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-4 h-4 text-brand-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244" />
              </svg>
            </div>
            <div>
              <h2 class="text-sm font-semibold text-slate-900">Link de convite</h2>
              <p class="text-xs text-slate-400">O aluno abre o link e já entra no app cadastrado na sua academia</p>
            </div>
          </div>

          <!-- Link display -->
          <div class="flex items-center gap-2 bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 mb-4">
            <svg class="w-4 h-4 text-slate-400 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244" />
            </svg>
            <span class="text-sm text-brand-700 font-mono flex-1 truncate">{{ inviteLink }}</span>
          </div>

          <!-- Actions -->
          <div class="flex flex-wrap gap-2">
            <button
              @click="copyLink"
              class="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium rounded-lg border border-slate-200 bg-white text-slate-700 hover:bg-slate-50 transition"
            >
              <svg v-if="!linkCopied" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
              </svg>
              <svg v-else class="w-4 h-4 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
              </svg>
              {{ linkCopied ? 'Copiado!' : 'Copiar link' }}
            </button>

            <button
              @click="shareWhatsApp"
              class="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white transition"
            >
              <svg class="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
              </svg>
              Compartilhar via WhatsApp
            </button>
          </div>
        </div>

        <!-- ── Card: Código de convite ────────────────────────────────────── -->
        <div class="card p-6">
          <div class="flex items-center gap-3 mb-5">
            <div class="w-8 h-8 rounded-lg bg-amber-50 flex items-center justify-center flex-shrink-0">
              <svg class="w-4 h-4 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M5.25 8.25h15m-16.5 7.5h15m-1.8-13.5l-3.9 19.5m-2.1-19.5l-3.9 19.5" />
              </svg>
            </div>
            <div>
              <h2 class="text-sm font-semibold text-slate-900">Código de convite</h2>
              <p class="text-xs text-slate-400">O aluno digita este código manualmente na tela de cadastro do app</p>
            </div>
          </div>

          <!-- Code display -->
          <div class="flex items-center justify-center bg-slate-900 rounded-xl px-6 py-5 mb-4">
            <span class="text-3xl font-mono font-bold tracking-[0.35em] text-white">{{ gym.invite_code }}</span>
          </div>

          <div class="flex">
            <button
              @click="copyCode"
              class="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium rounded-lg border border-slate-200 bg-white text-slate-700 hover:bg-slate-50 transition"
            >
              <svg v-if="!codeCopied" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" />
              </svg>
              <svg v-else class="w-4 h-4 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
              </svg>
              {{ codeCopied ? 'Copiado!' : 'Copiar código' }}
            </button>
          </div>
        </div>

        <!-- ── Dica ──────────────────────────────────────────────────────── -->
        <p class="text-xs text-slate-400 px-1">
          O link abre o app diretamente na tela de cadastro com a academia pré-selecionada.
          O código funciona para quem não conseguir abrir o link (app não instalado, link bloqueado, etc.).
        </p>

      </div>
    </template>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '../services/api.js'

const loading = ref(true)
const error   = ref('')
const gym     = ref(null)

const linkCopied = ref(false)
const codeCopied = ref(false)

const INVITE_BASE = 'https://gymup.app/join'

const inviteLink = computed(() =>
  gym.value ? `${INVITE_BASE}/${gym.value.invite_code}` : ''
)

const whatsappText = computed(() => {
  if (!gym.value) return ''
  return (
    `Olá! Você foi convidado a se cadastrar na ${gym.value.name} pelo app GymUp.\n\n` +
    `Acesse pelo link: ${inviteLink.value}\n\n` +
    `Ou utilize o código no cadastro: ${gym.value.invite_code}\n\n` +
    `Baixe o app na Play Store ou App Store e siga as instruções.`
  )
})

async function loadData() {
  loading.value = true
  error.value   = ''
  try {
    const { data } = await api.get('/admin/settings')
    gym.value = data.gym
  } catch (e) {
    error.value = e.response?.data?.message ?? 'Erro ao carregar dados.'
  } finally {
    loading.value = false
  }
}

function copyLink() {
  navigator.clipboard.writeText(inviteLink.value)
  linkCopied.value = true
  setTimeout(() => { linkCopied.value = false }, 2000)
}

function copyCode() {
  navigator.clipboard.writeText(gym.value.invite_code)
  codeCopied.value = true
  setTimeout(() => { codeCopied.value = false }, 2000)
}

function shareWhatsApp() {
  const encoded = encodeURIComponent(whatsappText.value)
  window.open(`https://wa.me/?text=${encoded}`, '_blank')
}

onMounted(loadData)
</script>
