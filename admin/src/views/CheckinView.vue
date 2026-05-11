<template>
  <div>

    <!-- Page header -->
    <div class="mb-8">
      <h1 class="text-2xl font-bold text-slate-900 tracking-tight">Check-in & QR Code</h1>
      <p class="text-slate-500 text-sm mt-1">QR Code fixo da academia para check-in dos alunos.</p>
    </div>

    <!-- Loading skeleton -->
    <div v-if="loading" class="max-w-sm mx-auto card p-8 animate-pulse flex flex-col items-center gap-5">
      <div class="w-64 h-64 bg-slate-100 rounded-xl" />
      <div class="h-3 bg-slate-100 rounded w-48" />
      <div class="flex gap-3">
        <div class="h-9 bg-slate-100 rounded w-28" />
        <div class="h-9 bg-slate-100 rounded w-24" />
        <div class="h-9 bg-slate-100 rounded w-32" />
      </div>
    </div>

    <!-- Error state -->
    <div v-else-if="loadError" class="card p-8 text-center max-w-sm mx-auto">
      <div class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-50 mb-3">
        <svg class="w-6 h-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
      </div>
      <p class="text-sm font-semibold text-slate-700 mb-1">Erro ao carregar QR Code</p>
      <p class="text-xs text-slate-400 mb-4">{{ loadError }}</p>
      <button @click="loadData" class="btn-secondary text-xs">Tentar novamente</button>
    </div>

    <!-- Content -->
    <div v-else class="max-w-sm mx-auto space-y-5">

      <!-- QR card -->
      <div class="card p-8 flex flex-col items-center gap-6">

        <!-- Hint -->
        <p class="text-xs text-slate-400 text-center">
          Mostre este QR na entrada da academia.<br>
          Qualquer aluno cadastrado pode escanear para fazer check-in.
        </p>

        <!-- Canvas -->
        <div class="p-4 bg-white rounded-2xl border border-slate-100 shadow-sm">
          <canvas ref="qrCanvas" />
        </div>

        <!-- Generated at -->
        <p v-if="generatedAt" class="text-xs text-slate-400 text-center">
          Gerado em {{ formattedDate }}
        </p>

        <!-- Token copiável -->
        <div class="w-full">
          <p class="text-xs font-medium text-slate-500 mb-1.5">Token</p>
          <div class="flex gap-2">
            <input
              :value="qrToken"
              readonly
              class="input w-full font-mono text-xs text-slate-600 bg-slate-50 cursor-default select-all"
            />
            <button
              @click="copyToken"
              class="btn-secondary text-sm flex-shrink-0 inline-flex items-center gap-1.5"
              :title="copied ? 'Copiado!' : 'Copiar token'"
            >
              <svg v-if="!copied" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round"
                  d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 01-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 011.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 00-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 01-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 00-3.375-3.375h-1.5a1.125 1.125 0 01-1.125-1.125v-1.5a3.375 3.375 0 00-3.375-3.375H9.75" />
              </svg>
              <svg v-else class="w-4 h-4 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
              </svg>
              {{ copied ? 'Copiado' : 'Copiar' }}
            </button>
          </div>
        </div>

        <!-- Action buttons -->
        <div class="flex flex-wrap gap-3 justify-center">
          <button @click="downloadQr" class="btn-secondary text-sm inline-flex items-center gap-1.5">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
            </svg>
            Baixar imagem
          </button>

          <button @click="printQr" class="btn-secondary text-sm inline-flex items-center gap-1.5">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M6.72 13.829c-.24.03-.48.062-.72.096m.72-.096a42.415 42.415 0 0110.56 0m-10.56 0L6.34 18m10.94-4.171c.24.03.48.062.72.096m-.72-.096L17.66 18m0 0l.229 2.523a1.125 1.125 0 01-1.12 1.227H7.231c-.662 0-1.18-.568-1.12-1.227L6.34 18m11.318 0h1.091A2.25 2.25 0 0021 15.75V9.456c0-1.081-.768-2.015-1.837-2.175a48.055 48.055 0 00-1.913-.247M6.34 18H5.25A2.25 2.25 0 013 15.75V9.456c0-1.081.768-2.015 1.837-2.175a48.056 48.056 0 011.913-.247m10.5 0a48.536 48.536 0 00-10.5 0m10.5 0V3.375c0-.621-.504-1.125-1.125-1.125h-8.25c-.621 0-1.125.504-1.125 1.125v3.659M18 10.5h.008v.008H18V10.5zm-3 0h.008v.008H15V10.5z" />
            </svg>
            Imprimir
          </button>

          <button
            v-if="!confirmingRegen"
            @click="confirmingRegen = true"
            class="btn-secondary text-sm inline-flex items-center gap-1.5 text-amber-600 border-amber-200 hover:border-amber-300 hover:bg-amber-50"
          >
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
            </svg>
            Gerar novo QR
          </button>
        </div>

        <!-- Inline regenerate confirmation -->
        <div v-if="confirmingRegen" class="w-full rounded-xl border border-amber-200 bg-amber-50 p-4 text-center space-y-3">
          <p class="text-xs font-semibold text-amber-800">
            O QR atual deixará de funcionar imediatamente.<br>Deseja continuar?
          </p>
          <div class="flex gap-2 justify-center">
            <button
              @click="confirmingRegen = false"
              class="btn-secondary text-xs px-4"
            >
              Cancelar
            </button>
            <button
              @click="regenerate"
              :disabled="regenLoading"
              class="btn-primary text-xs px-4 bg-amber-500 hover:bg-amber-600 border-amber-500 inline-flex items-center gap-1.5"
            >
              <svg v-if="regenLoading" class="animate-spin w-3.5 h-3.5" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
              </svg>
              {{ regenLoading ? 'Gerando…' : 'Confirmar' }}
            </button>
          </div>
        </div>

        <!-- Regen feedback -->
        <div
          v-if="regenMsg"
          :class="['text-xs font-medium px-3 py-2 rounded-lg w-full text-center',
            regenMsg.ok ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700']"
        >
          {{ regenMsg.text }}
        </div>

      </div>

    </div>

  </div>
</template>

<script setup>
import { ref, computed, nextTick } from 'vue'
import api from '../services/api.js'
import QRCode from 'qrcode'

const loading        = ref(true)
const loadError      = ref('')
const qrToken        = ref('')
const generatedAt    = ref(null)
const qrCanvas       = ref(null)
const confirmingRegen = ref(false)
const regenLoading   = ref(false)
const regenMsg       = ref(null)
const copied         = ref(false)
const gymName        = ref('')

const formattedDate = computed(() => {
  if (!generatedAt.value) return ''
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(generatedAt.value))
})

async function loadData() {
  loading.value   = true
  loadError.value = ''
  try {
    const [qrRes, settingsRes] = await Promise.all([
      api.get('/admin/gym/qr'),
      api.get('/admin/settings').catch(() => null),
    ])
    qrToken.value     = qrRes.data.qr_token     ?? ''
    generatedAt.value = qrRes.data.qr_generated_at ?? null
    gymName.value     = settingsRes?.data?.gym?.name ?? ''
  } catch (e) {
    loadError.value = e.response?.data?.message ?? 'Erro ao carregar QR Code.'
  } finally {
    loading.value = false
  }

  if (qrToken.value) {
    await nextTick()
    await renderQr()
  }
}

async function renderQr() {
  if (!qrToken.value || !qrCanvas.value) return
  await QRCode.toCanvas(qrCanvas.value, qrToken.value, {
    width:  300,
    margin: 2,
    color: { dark: '#1e293b', light: '#ffffff' },
  })
}

function downloadQr() {
  if (!qrCanvas.value) return
  const link    = document.createElement('a')
  link.download = 'qrcode-checkin.png'
  link.href     = qrCanvas.value.toDataURL('image/png')
  link.click()
}

function printQr() {
  if (!qrCanvas.value) return
  const dataUrl = qrCanvas.value.toDataURL('image/png')
  const win = window.open('', '_blank', 'width=440,height=560')
  win.document.write(`
    <html><head><title>QR Code Check-in</title>
    <style>
      body { margin: 0; display: flex; flex-direction: column; align-items: center;
             justify-content: center; min-height: 100vh; font-family: sans-serif; }
      img  { width: 300px; height: 300px; }
      p    { margin-top: 16px; font-size: 14px; color: #475569; text-align: center; }
      @media print { button { display: none; } }
    </style></head>
    <body>
      <img src="${dataUrl}" alt="QR Code Check-in" />
      <p>QR Code de Check-in<br><strong>${gymName.value}</strong></p>
    </body></html>
  `)
  win.document.close()
  win.focus()
  win.print()
}

async function copyToken() {
  if (!qrToken.value) return
  await navigator.clipboard.writeText(qrToken.value)
  copied.value = true
  setTimeout(() => { copied.value = false }, 2000)
}

async function regenerate() {
  regenLoading.value = true
  try {
    const { data } = await api.post('/admin/gym/qr/regenerate')
    qrToken.value     = data.qr_token
    generatedAt.value = data.qr_generated_at
    confirmingRegen.value = false
    await nextTick()
    await renderQr()
    flash(true, 'Novo QR Code gerado com sucesso.')
  } catch (e) {
    flash(false, e.response?.data?.message ?? 'Erro ao gerar novo QR.')
  } finally {
    regenLoading.value = false
  }
}

function flash(ok, text) {
  regenMsg.value = { ok, text }
  setTimeout(() => { regenMsg.value = null }, 4000)
}

loadData()
</script>
